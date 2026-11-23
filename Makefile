# aildb is a package of AIL (Ailfile), built and tested by the command
# ail: "ail build" compiles build/aildb from src/aildb.aiw, and
# "ail test" runs the tests. The targets all, test and clean are those
# commands, for whoever types make; the others are what the
# command does not do. AIL names the command, if it is not on PATH:
#   make AIL=../ail/build/ail
AIL ?= ail
# the same from another directory: a path is made one from the root
AILCMD := $(if $(findstring /,$(AIL)),$(abspath $(AIL)),$(AIL))
B := build

all:
	$(AIL) build

# Every test, the indentation of every source, and the tests of the two
# packages that are in directories of this one: example/consumer, a
# program that uses aildb as a package (docs/library.md), and mcp, the
# MCP server (docs/mcp.md), which is started with the build/aildb that
# the first line made. Or with T the tests named there:
# make test T="name name".
test:
ifeq ($(T),)
	$(AIL) test
	$(AIL) fmt --check
	cd example/consumer && $(AILCMD) test
	cd mcp && $(AILCMD) test && $(AILCMD) fmt --check
else
	$(AIL) test $(T)
endif

# The example, acceptance check 1 (docs/example.md): the files of the
# repository and revision in example/corpus.pin are cut into chunks,
# build/embed asks a running Ollama for the embeddings of the
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
	$(AIL) build embed
	rm -rf $(E)
	mkdir -p $(E)/src $(E)/copy
	git clone -q --no-checkout $(URL) $(E)/repo
	git -C $(E)/repo archive $(PIN) | tar -x -C $(E)/src
	git -C $(E)/repo ls-tree -r --name-only $(PIN) > $(E)/list
	$(B)/chunk $(E)/src $(E)/meta.tsv $(E)/text.jsonl < $(E)/list
	$(B)/embed document $(E)/text.jsonl $(E)/vectors.bin
	$(B)/embed query example/queries.tsv $(E)/queries.bin
	$(B)/aildb build -o $(E)/ail.idx -v $(E)/vectors.bin -m $(E)/meta.tsv -d 768 -i nomic-embed-text -r $(PIN)
	$(B)/aildb check $(E)/ail.idx
	cp $(E)/ail.idx $(E)/copy/moved.idx
	$(B)/example-check $(B)/aildb $(E)/ail.idx $(E)/copy/moved.idx example/queries.tsv $(E)/queries.bin

# The retrieval evaluation (docs/evaluation.md): for each corpus of
# CORPORA, a repository and revision in example/eval/<corpus>.pin with
# the queries of example/eval/<corpus>.tsv, the place at which each query
# finds its lines, how many are among the first 1, 5 and 10, and the mean
# reciprocal rank. It needs a running Ollama, as the example does, and
# writes build/eval/report.txt.
CORPORA ?= ail aildb
eval:
	$(AIL) build
	$(AIL) build chunk
	$(AIL) build example-eval
	$(AIL) build embed
	tools/eval.sh $(AIL) $(CORPORA)

# The MCP server alone, mcp/ (docs/mcp.md), a package of its own: its
# test and its indentation, which make test runs too.
mcp-test:
	$(AIL) build
	cd mcp && $(AILCMD) test && $(AILCMD) fmt --check

# The archive of a release (README.md, "The executable"): the
# executable of the revision REV, by default the tag of the version in
# Ailfile, built by this command of AIL from the sources that git has at
# that revision, with LICENSE, NOTICE and a file BUILD that names the
# two revisions: build/dist/aildb-<version>-x86_64-linux.tar.gz and its
# .sha256. dist-check unpacks it in a container that has no AIL, of the
# image IMAGE, and runs build, check and search there; it needs Docker.
REV ?= v$(shell sed -n 's/^version //p' Ailfile)
IMAGE ?= debian:stable-slim
dist:
	tools/dist.sh $(REV) $(AIL)

dist-check:
	tools/dist-check.sh $(IMAGE)

clean:
	$(AIL) clean

.PHONY: all test example eval mcp-test dist dist-check clean
