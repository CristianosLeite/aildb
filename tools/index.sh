#!/bin/sh
# tools/index.sh REPO OUT [REVISION] -- the index of a repository (make
# index, docs/mcp.md): the snapshot OUT of the files that the git
# repository in the directory REPO has at REVISION, HEAD if none is
# given. It is what the example does (docs/example.md) for a repository
# of one's own: the files of the revision are cut into chunks by
# build/chunk, which takes the sources of AIL and Markdown and passes
# over the rest, build/embed asks a running Ollama for their embeddings
# from nomic-embed-text, and "aildb build" publishes OUT with that model
# and the whole name of the revision. What is not committed is not
# indexed. An OUT that is there is replaced as build replaces one, so a
# reader of it, the MCP server among them, has the old index or the new.
#
# A file is indexed as the bytes git has for it at the revision: each is
# written from its blob, so nothing an attribute would do to an archive
# or a checkout (export-ignore, export-subst, a filter, line ends) is
# done to it. Only a regular file is taken. A symbolic link is passed
# over, since what it names may be outside the revision, and so is a
# submodule. A path with a double quote, a backslash or a byte below
# 0x20 in it, which git prints quoted, is passed over with a line on
# standard error, and so is one that would lead out of the directory.
#
# Standard output has the line of "aildb build" and standard error what
# the steps said. The status is 0, 2 for wrong usage, 1 if a program of
# build/ is not built, REPO is no repository or has no such revision,
# the revision has no file to index or the embeddings cannot be made,
# and otherwise that of "aildb build" (docs/usage.md). The files of the
# steps are in a directory beside OUT that is removed at the end.
set -eu
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
	echo 'usage: tools/index.sh REPO OUT [REVISION]' >&2
	exit 2
fi
repo=$1
out=$2
rev=${3:-HEAD}
b=$(cd "$(dirname "$0")/.." && pwd)/build
for p in chunk embed aildb; do
	if [ ! -x "$b/$p" ]; then
		echo "index: $b/$p is not built: make index builds it" >&2
		exit 1
	fi
done
if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
	echo "index: $repo is no repository of git" >&2
	exit 1
fi
if ! pin=$(git -C "$repo" rev-parse --verify -q "$rev^{commit}" 2>/dev/null); then
	echo "index: $repo has no revision $rev" >&2
	exit 1
fi
mkdir -p "$(dirname "$out")"
w=$(mktemp -d "$out.XXXXXX")
trap 'rm -rf "$w"' EXIT
mkdir "$w/src"
# "mode type name<tab>path" for each entry, a path of other bytes than
# ASCII as it is. The list is every regular file, of which the chunker
# takes what it knows; the files written are those it reads, the
# sources of AIL and Markdown (example/chunk.aiw). It fails for a path
# of the list that it takes and does not find, so the two cannot come
# to differ unseen.
tab=$(printf '\t')
git -C "$repo" -c core.quotePath=false ls-tree -r --full-tree "$pin" > "$w/tree"
: > "$w/list"
while IFS= read -r line; do
	meta=${line%%"$tab"*}
	path=${line#*"$tab"}
	case ${meta%% *} in
	100644|100755) ;;
	*) continue ;;
	esac
	case $path in
	\"*)
		echo "index: passed over, a path that git quotes: $path" >&2
		continue ;;
	/*|../*|*/../*|*/..|..)
		echo "index: passed over, a path that leaves the repository: $path" >&2
		continue ;;
	esac
	printf '%s\n' "$path" >> "$w/list"
	case $path in
	*.aiw|*.md)
		mkdir -p "$(dirname "$w/src/$path")"
		git -C "$repo" cat-file blob "${meta##* }" > "$w/src/$path" ;;
	esac
done < "$w/tree"
"$b/chunk" "$w/src" "$w/meta.tsv" "$w/text.jsonl" < "$w/list" >&2
if [ ! -s "$w/meta.tsv" ]; then
	echo "index: $repo has no source of AIL and no Markdown at $rev" >&2
	exit 1
fi
"$b/embed" document "$w/text.jsonl" "$w/vectors.bin" >&2
"$b/aildb" build -o "$out" -v "$w/vectors.bin" -m "$w/meta.tsv" -d 768 -i nomic-embed-text -r "$pin"
