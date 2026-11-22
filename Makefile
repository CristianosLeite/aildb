# aildb is a package of AIL (ail.pkg), built and tested by the command
# ail: "ail build" compiles build/aildb from src/aildb.aiw, and
# "ail test" runs the tests. The targets all, test and clean are those
# commands, for whoever types make; example and bench are what the
# command does not do. AIL names the command, if it is not on PATH:
#   make AIL=../ail/build/ail
AIL ?= ail
# the same from another directory: a path is made one from the root
AILCMD := $(if $(findstring /,$(AIL)),$(abspath $(AIL)),$(AIL))
B := build

all:
	$(AIL) build

# Every test, the indentation of every source, and the tests of the
# package in example/consumer, a program that uses aildb as a package
# (docs/library.md); or with T the tests named there:
# make test T="name name".
test:
ifeq ($(T),)
	$(AIL) test
	$(AIL) fmt --check
	cd example/consumer && $(AILCMD) test
else
	$(AIL) test $(T)
endif

# The example, acceptance check 1 (docs/example.md): the files of the
# repository and revision in example/corpus.pin are cut into chunks,
# example/embed.py asks a running Ollama for the embeddings of the
# chunks and of the queries, build makes the snapshot, and
# build/example-check searches it and a copy of it at another path for
# the lines each query is to find.
E := $(B)/example
URL := $(shell awk '!/^\#/ && NF {print $$1}' example/corpus.pin)
PIN := $(shell awk '!/^\#/ && NF {print $$2}' example/corpus.pin)

example:
	$(AIL) build
	$(AIL) build chunk
	$(AIL) build example-check
	rm -rf $(E)
	mkdir -p $(E)/src $(E)/copy
	git clone -q --no-checkout $(URL) $(E)/repo
	git -C $(E)/repo archive $(PIN) | tar -x -C $(E)/src
	git -C $(E)/repo ls-tree -r --name-only $(PIN) > $(E)/list
	$(B)/chunk $(E)/src $(E)/meta.tsv $(E)/text.jsonl < $(E)/list
	python3 example/embed.py document $(E)/text.jsonl $(E)/vectors.bin
	python3 example/embed.py query example/queries.tsv $(E)/queries.bin
	$(B)/aildb build -o $(E)/ail.idx -v $(E)/vectors.bin -m $(E)/meta.tsv -d 768 -i nomic-embed-text -r $(PIN)
	$(B)/aildb check $(E)/ail.idx
	cp $(E)/ail.idx $(E)/copy/moved.idx
	$(B)/example-check $(B)/aildb $(E)/ail.idx $(E)/copy/moved.idx example/queries.tsv $(E)/queries.bin

# The measurements of acceptance check 4 (docs/performance.md), against
# the Python binding of LanceDB, with the programs of bench/: the
# harness, the generator of the inputs, the scan with three ways of
# reading, and the engine with hooks that say the times of its parts.
# PY is a Python that has the package lancedb.
PY ?= python3
bench:
	$(AIL) build
	for p in bench-run bench-gen bench-scan aildb-times; do $(AIL) build $$p || exit 1; done
	AIL=$(AIL) bench/bench.sh $(PY)

clean:
	$(AIL) clean

.PHONY: all test example bench clean
