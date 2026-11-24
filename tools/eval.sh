#!/bin/sh
# tools/eval.sh AIL CORPUS... -- the retrieval evaluation (make eval,
# docs/evaluation.md). For each CORPUS, example/eval/CORPUS.pin names a
# repository and a revision and example/eval/CORPUS.tsv has queries with
# the lines each is to find. The files of the revision are cut into
# chunks by "build/chunk -c", or by "build/chunk" without it, as an index
# of a directory cuts every text file, if the word "text" stands after
# the revision in the .pin; build/embed asks a running Ollama for the
# embeddings of the chunks and of the queries, aildb builds a snapshot,
# and build/example-eval says at which place each query finds its lines.
# Everything is in build/eval/, and build/eval/report.txt has what was
# printed: the day, the revisions, the model and how chunks are cut, and
# the places and measures of each corpus.
#
# A variant is the same with something changed, which the environment
# says (tools/eval-variants.sh runs several): EVAL_LINES and EVAL_BYTES
# are the most lines and bytes of a chunk, EVAL_OVERLAP the lines that a
# chunk has in common with the one before it, EVAL_PATH=1 puts the path
# of a file before the text of each of its chunks, EVAL_MODEL and
# EVAL_DIM are the model and the elements of its vectors, EVAL_DOCPREFIX
# and EVAL_QUERYPREFIX what stands before a chunk and before a query,
# which may be set to nothing, and EVAL_OUT the directory in the place
# of build/eval.
set -eu
ail=$1
shift
b=build
e=${EVAL_OUT:-$b/eval}
model=${EVAL_MODEL:-nomic-embed-text}
dim=${EVAL_DIM:-768}
lines=${EVAL_LINES:-$(sed -n 's/^const chunkmaxlines //p' src/lib/chunk.aiw)}
bytes=${EVAL_BYTES:-$(sed -n 's/^const chunkmaxbytes //p' src/lib/chunk.aiw)}
overlap=${EVAL_OVERLAP:-0}
corpora=$*
chunkopts="-n $lines -b $bytes -o $overlap"
[ "${EVAL_PATH:-0}" = 0 ] || chunkopts="$chunkopts -p"
rm -rf "$e"
mkdir -p "$e"
# build/embed with the model of the run; a prefix may have a space and
# may be empty, so the two are arguments of their own
embed() {
	if [ -n "${EVAL_DOCPREFIX+x}" ] && [ -n "${EVAL_QUERYPREFIX+x}" ]; then
		$b/embed -m "$model" -d "$dim" -D "$EVAL_DOCPREFIX" -Q "$EVAL_QUERYPREFIX" "$@"
	else
		$b/embed -m "$model" -d "$dim" "$@"
	fi
}
{
	date -u '+%Y-%m-%d %H:%M UTC'
	printf 'aildb: %s' "$(git rev-parse --short HEAD)"
	[ -z "$(git status --porcelain)" ] || printf ' with changes'
	printf '\nAIL: %s\n' "$("$ail" version)"
	embed model
	printf 'chunks: at most %s lines and %s bytes, ' "$lines" "$bytes"
	if [ "$overlap" = 0 ]; then printf 'no overlap'; else printf '%s lines of overlap' "$overlap"; fi
	case $chunkopts in *-p) printf ', the path before the text' ;; esac
	printf '\n'
	if [ -n "${EVAL_DOCPREFIX+x}" ] && [ -n "${EVAL_QUERYPREFIX+x}" ]; then
		printf 'prefixes: "%s" before a chunk and "%s" before a query\n' "$EVAL_DOCPREFIX" "$EVAL_QUERYPREFIX"
	fi
	for c in $corpora; do
		url=$(awk '!/^#/ && NF {print $1}' "example/eval/$c.pin")
		pin=$(awk '!/^#/ && NF {print $2}' "example/eval/$c.pin")
		how=$(awk '!/^#/ && NF {print $3}' "example/eval/$c.pin")
		mode=-c
		[ "$how" != text ] || mode=
		d=$e/$c
		mkdir -p "$d/src"
		printf '\n%s: %s at %s' "$c" "$url" "$pin"
		[ -n "$mode" ] || printf ', every text file'
		printf '\n'
		git clone -q --no-checkout "$url" "$d/repo"
		git -C "$d/repo" archive "$pin" | tar -x -C "$d/src"
		git -C "$d/repo" ls-tree -r --name-only "$pin" > "$d/list"
		$b/chunk $mode $chunkopts "$d/src" "$d/meta.tsv" "$d/text.jsonl" < "$d/list"
		embed document "$d/text.jsonl" "$d/vectors.bin" >/dev/null
		embed query "example/eval/$c.tsv" "$d/queries.bin" >/dev/null
		$b/aildb build -o "$d/$c.idx" -v "$d/vectors.bin" -m "$d/meta.tsv" -d "$dim" -i "$model" -r "$pin"
		$b/example-eval $b/aildb "$d/$c.idx" "example/eval/$c.tsv" "$d/queries.bin"
	done
	echo complete
} 2>&1 | tee "$e/report.txt"
tail -n 1 "$e/report.txt" | grep -q '^complete$'
