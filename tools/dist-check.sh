#!/bin/sh
# tools/dist-check.sh [IMAGE] -- try the archive of make dist where
# there is no AIL (make dist-check): in a container of IMAGE, which
# Docker runs without a network, the checksum is verified, the archive
# unpacked, and the executable builds a snapshot of two records, checks
# it and searches it. What the three commands print is compared with
# the lines below, which are what docs/usage.md says of these inputs:
# the vectors (1,0) and (0,1) and the query (1,0), whose cosines are
# exactly 1 and 0.
set -eu
image=${1:-debian:stable-slim}
d=build/dist
set -- "$d"/aildb-*-x86_64-linux.tar.gz
[ -f "$1" ] && [ $# -eq 1 ] || { echo "dist-check: run make dist first" >&2; exit 1; }
archive=$(basename "$1")
want='{"records":2,"dimension":2,"model":"m","source_revision":"r"}
{"records":2,"dimension":2,"model":"m","source_revision":"r"}
{"source_revision":"r","model":"m"}
{"rank":1,"score":1.000000,"score_bits":"3ff0000000000000","path":"a.aiw","start_line":1,"end_line":9}
{"rank":2,"score":0.000000,"score_bits":"0000000000000000","path":"b.md","start_line":2,"end_line":3}'
got=$(docker run --rm --network none -v "$(readlink -f "$d"):/dist:ro" "$image" sh -euc '
	cd /dist
	sha256sum -c --quiet '"$archive"'.sha256
	mkdir /work
	cd /work
	tar -xzf /dist/'"$archive"'
	cd aildb-*
	test -s LICENSE
	test -s NOTICE
	test -s BUILD
	printf "\000\000\200\077\000\000\000\000\000\000\000\000\000\000\200\077" > v.bin
	printf "\000\000\200\077\000\000\000\000" > q.bin
	printf "a.aiw\t1\t9\tail\nb.md\t2\t3\tmarkdown\n" > m.tsv
	./aildb build -o x.idx -v v.bin -m m.tsv -d 2 -i m -r r
	./aildb check x.idx
	./aildb search x.idx -k 5 -i m < q.bin
')
if [ "$got" = "$want" ]; then
	echo "dist-check: $archive builds, checks and searches in $image"
else
	echo "dist-check: $archive printed in $image" >&2
	echo "$got" >&2
	exit 1
fi
