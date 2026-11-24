#!/bin/sh
# tools/dist-check.sh [IMAGE] -- try the archive of make dist where
# there is no AIL (make dist-check): in a container of IMAGE, which
# Docker runs without a network, the checksum is verified, the archive
# unpacked, and the executable builds a snapshot of two records, checks
# it and searches it. What the three commands print is compared with
# the lines below, which are what docs/usage.md says of these inputs:
# the vectors (1,0) and (0,1) and the query (1,0), whose cosines are
# exactly 1 and 0.
#
# An archive that has aildb-llama has the index of a directory and the
# search by text (docs/install.md), which are tried too, with a
# provider that is a script of four lines written in the container, no
# model and no network: its vector is (1,0) for a text with "alpha" in
# it and (0,1) for any other. A directory of two files is indexed and
# searched by text; a third file is written and the search made again,
# which is to find it with no command between; the same search is made
# through aildb-mcp; and the two providers that are shipped say their
# usage. The container has no git, so the directory is one that is in
# no work tree.
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
managed='{"records":2,"dimension":2,"model":"m","source_revision":null,"files":2,"embedded":2,"published":true}
{"source_revision":null,"model":"m"}
{"rank":1,"score":1.000000,"score_bits":"3ff0000000000000","path":"a.txt","start_line":1,"end_line":1}
{"rank":2,"score":0.000000,"score_bits":"0000000000000000","path":"b.txt","start_line":1,"end_line":1}
{"source_revision":null,"model":"m"}
{"rank":1,"score":1.000000,"score_bits":"3ff0000000000000","path":"a.txt","start_line":1,"end_line":1}
{"rank":2,"score":1.000000,"score_bits":"3ff0000000000000","path":"c.txt","start_line":1,"end_line":1}
{"rank":3,"score":0.000000,"score_bits":"0000000000000000","path":"b.txt","start_line":1,"end_line":1}
mcp: 3 hits, the second c.txt
aildb-llama: status 2
aildb-ollama: status 2'
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
	test -x aildb-llama || exit 0
	# the index of a directory and the search by text
	here=$PWD
	printf "#!/bin/sh\nif grep -q alpha; then v=1,0; else v=0,1; fi\nprintf \047{\"aildb\":1,\"embeddings\":[{\"index\":0,\"vector\":[%%s]}]}\\n\047 \"\$v\"\n" > provider.sh
	chmod +x provider.sh
	mkdir proj
	printf "alpha one\n" > proj/a.txt
	printf "beta two\n" > proj/b.txt
	./aildb index proj -i m -d 2 -b 1 -- "$here/provider.sh"
	./aildb search proj --text "the alpha" -k 5
	printf "alpha again\n" > proj/c.txt
	./aildb search proj --text "the alpha" -k 5
	{
		echo "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2025-11-25\",\"capabilities\":{},\"clientInfo\":{\"name\":\"check\",\"version\":\"0\"}}}"
		echo "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"
		echo "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"search\",\"arguments\":{\"query\":\"the alpha\",\"k\":5}}}"
		sleep 2
	} | ./aildb-mcp -d proj -a "$here/aildb" > mcp.out
	tail -n 1 mcp.out | grep -q "\"isError\":false"
	hits=$(tail -n 1 mcp.out | sed "s/structuredContent.*//" | grep -o "rank" | wc -l)
	second=$(tail -n 1 mcp.out | sed "s/.*structuredContent//" | grep -o "\"rank\":2[^}]*" | grep -o "[a-z]\.txt")
	echo "mcp: $hits hits, the second $second"
	for p in aildb-llama aildb-ollama; do
		st=0
		./$p -x </dev/null 2>/dev/null || st=$?
		echo "$p: status $st"
	done
')
case $got in *"aildb-ollama: status"*) want="$want
$managed" ;; esac
if [ "$got" = "$want" ]; then
	case $got in
	*"aildb-ollama: status"*) echo "dist-check: $archive builds, checks and searches, and indexes and searches a directory by text, in $image" ;;
	*) echo "dist-check: $archive builds, checks and searches in $image" ;;
	esac
else
	echo "dist-check: $archive printed in $image" >&2
	echo "$got" >&2
	exit 1
fi
