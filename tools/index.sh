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
git -C "$repo" archive "$pin" | tar -x -C "$w/src"
git -C "$repo" ls-tree -r --name-only "$pin" > "$w/list"
"$b/chunk" "$w/src" "$w/meta.tsv" "$w/text.jsonl" < "$w/list" >&2
if [ ! -s "$w/meta.tsv" ]; then
	echo "index: $repo has no source of AIL and no Markdown at $rev" >&2
	exit 1
fi
"$b/embed" document "$w/text.jsonl" "$w/vectors.bin" >&2
"$b/aildb" build -o "$out" -v "$w/vectors.bin" -m "$w/meta.tsv" -d 768 -i nomic-embed-text -r "$pin"
