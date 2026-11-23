#!/bin/sh
# tools/eval.sh AIL CORPUS... -- the retrieval evaluation (make eval,
# docs/evaluation.md). For each CORPUS, example/eval/CORPUS.pin names a
# repository and a revision and example/eval/CORPUS.tsv has queries with
# the lines each is to find. The files of the revision are cut into
# chunks by "build/chunk -c", build/embed asks a running Ollama for the
# embeddings of the chunks and of the queries, aildb builds a snapshot,
# and build/example-eval says at which place each query finds its lines.
# Everything is in build/eval/, and build/eval/report.txt has what was
# printed: the day, the revisions, the model and how chunks are cut, and
# the places and measures of each corpus.
set -eu
ail=$1
shift
b=build
e=$b/eval
rm -rf "$e"
mkdir -p "$e"
{
	date -u '+%Y-%m-%d %H:%M UTC'
	printf 'aildb: %s' "$(git rev-parse --short HEAD)"
	[ -z "$(git status --porcelain)" ] || printf ' with changes'
	printf '\nAIL: %s\n' "$("$ail" version)"
	$b/embed model
	printf 'chunks: at most %s lines and %s bytes, no overlap\n' \
		"$(sed -n 's/^const maxlines //p' example/chunk.aiw)" \
		"$(sed -n 's/^const maxbytes //p' example/chunk.aiw)"
	for c in "$@"; do
		url=$(awk '!/^#/ && NF {print $1}' "example/eval/$c.pin")
		pin=$(awk '!/^#/ && NF {print $2}' "example/eval/$c.pin")
		d=$e/$c
		mkdir -p "$d/src"
		printf '\n%s: %s at %s\n' "$c" "$url" "$pin"
		git clone -q --no-checkout "$url" "$d/repo"
		git -C "$d/repo" archive "$pin" | tar -x -C "$d/src"
		git -C "$d/repo" ls-tree -r --name-only "$pin" > "$d/list"
		$b/chunk -c "$d/src" "$d/meta.tsv" "$d/text.jsonl" < "$d/list"
		$b/embed document "$d/text.jsonl" "$d/vectors.bin" >/dev/null
		$b/embed query "example/eval/$c.tsv" "$d/queries.bin" >/dev/null
		$b/aildb build -o "$d/$c.idx" -v "$d/vectors.bin" -m "$d/meta.tsv" -d 768 -i nomic-embed-text -r "$pin"
		$b/example-eval $b/aildb "$d/$c.idx" "example/eval/$c.tsv" "$d/queries.bin"
	done
	echo complete
} 2>&1 | tee "$e/report.txt"
tail -n 1 "$e/report.txt" | grep -q '^complete$'
