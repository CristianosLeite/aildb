#!/bin/sh
# tools/eval-variants.sh AIL CORPUS... -- the retrieval evaluation of
# tools/eval.sh once for each of several ways to cut and to embed (make
# eval-variants, docs/evaluation.md): the chunks as they are, smaller
# and larger ones, chunks with lines in common, the path of a file
# before the text of its chunks, and another embedding model. Each run
# is in build/eval/<variant>/ with its report.txt, and
# build/eval/variants.txt has a line for each variant and corpus: the
# chunks, the queries found among the first 1, 5 and 10 results, and
# the mean reciprocal rank, read from those reports.
#
# It needs a running Ollama that has both models, nomic-embed-text and
# mxbai-embed-large. The second is told what a query is for and nothing
# before a chunk, as its authors say it wants.
set -eu
ail=$1
shift
out=build/eval
rm -rf "$out"
mkdir -p "$out"
run() {
	name=$1
	shift
	echo "== $name"
	env EVAL_OUT="$out/$name" "$@" tools/eval.sh "$ail" $corpora > "$out/$name.log" 2>&1 || {
		tail -n 5 "$out/$name.log" >&2
		echo "eval-variants: the variant $name failed" >&2
		exit 1
	}
}
corpora=$*
run base
run small EVAL_LINES=20 EVAL_BYTES=750
run large EVAL_LINES=80 EVAL_BYTES=3000
run overlap EVAL_OVERLAP=10
run path EVAL_PATH=1
run mxbai EVAL_MODEL=mxbai-embed-large EVAL_DIM=1024 EVAL_DOCPREFIX= "EVAL_QUERYPREFIX=Represent this sentence for searching relevant passages: "
{
	printf '%-8s %-8s %7s %6s %6s %6s %7s\n' variant corpus chunks first1 first5 first10 mrr
	for v in base small large overlap path mxbai; do
		awk -v v="$v" '
			/^[a-z0-9]+: https?:/ { c = $1; sub(":", "", c) }
			/ files, [0-9]+ chunks$/ { n = $3 }
			/^in the first 1:/ { a = $5 }
			/^in the first 5:/ { b = $5 }
			/^in the first 10:/ { d = $5 }
			/^mean reciprocal rank:/ { printf "%-8s %-8s %7s %6s %6s %6s %7s\n", v, c, n, a, b, d, $4 }
		' "$out/$v/report.txt"
	done
} | tee "$out/variants.txt"
