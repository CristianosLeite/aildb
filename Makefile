# aildb is one executable, build/aildb, compiled from src/aildb.aiw by the
# compiler of AIL. The repository of AIL is at ail/: a clone of the
# address and revision in ail.pin, which the first make fetches, or a
# link to a checkout named once with make AIL=<path>. Nothing of it is
# copied here.
B := build

# tools/ail.sh puts the repository there and makes the link lib whenever
# make reads this file.
AILSAID := $(shell tools/ail.sh $(AIL) 2>&1 || echo failed)
ifneq ($(AILSAID),)
$(error $(AILSAID))
endif

all: $(B)/aildb

# The compiler and the formatter are built where their source is and
# linked here. A link has the time of its file, so a new compiler builds
# everything here again.
$(B)/ailc: FORCE
	@make -s -C ail AIL= build/ailc build/tools/indent
	@mkdir -p $(B)/tools
	@ln -sfn ../ail/build/ailc $(B)/ailc
	@ln -sfn ../../ail/build/tools/indent $(B)/tools/indent

FORCE:

# $(call compile,<compiler>): compile $< to $@.
# Build into a temporary file so a failed compile never leaves a target
# that looks up to date. mktemp creates it unreadable by others, hence
# the full mode.
define compile
@echo "$(1) < $< > $@"
@tmp=$$(mktemp $@.tmp.XXXXXX) || exit 1; \
trap 'rm -f "$$tmp"' EXIT; trap 'exit 1' HUP INT TERM; \
$(1) < $< > "$$tmp" && chmod 755 "$$tmp" && mv "$$tmp" $@
endef

# A source names its files with use, paths from this directory: those of
# src/ and the libraries of AIL under lib/. Every one of them is a
# prerequisite, so an edit of any builds the executable again; the entry
# point stays the first, the one the recipe compiles.
SRC := $(wildcard src/*.aiw src/lib/*.aiw)
AILLIB := $(wildcard lib/std/*.aiw)

$(B)/aildb: src/aildb.aiw $(SRC) $(AILLIB) $(B)/ailc
	$(call compile,$(B)/ailc)

# The executable of the tests of interruption: the same commands with
# hooks that stop and fail where a test asks. It is built for make test
# and is no part of what is shipped.
$(B)/aildb-stops: tests/lib/stops.aiw tests/lib/hook.aiw $(SRC) $(AILLIB) $(B)/ailc
	$(call compile,$(B)/ailc)

# The chunker of the example (docs/example.md), which has a test.
$(B)/chunk: example/chunk.aiw $(SRC) $(AILLIB) $(B)/ailc
	$(call compile,$(B)/ailc)

# Every test, or with T the tests of tests/run.sh named there:
# make test T="name name".
test: all $(B)/aildb-stops $(B)/chunk
ifeq ($(T),)
	@f=0; AILC=$(B)/ailc tests/run.sh || f=1; tests/indent.sh || f=1; exit $$f
else
	@AILC=$(B)/ailc tests/run.sh $(T)
endif

# The example, acceptance check 1 (docs/example.md): the files of AIL at
# the revision of ail.pin are cut into chunks, example/embed.py asks a
# running Ollama for the embeddings of the chunks and of the queries,
# build makes the snapshot, and build/example-check searches it and a
# copy of it at another path for the lines each query is to find.
E := $(B)/example
PIN := $(shell awk '!/^\#/ && NF {print $$2}' ail.pin)

$(B)/example-check: example/check.aiw $(SRC) $(AILLIB) $(B)/ailc
	$(call compile,$(B)/ailc)

example: all $(B)/chunk $(B)/example-check
	rm -rf $(E)
	mkdir -p $(E)/src $(E)/copy
	git -C ail archive $(PIN) | tar -x -C $(E)/src
	git -C ail ls-tree -r --name-only $(PIN) > $(E)/list
	$(B)/chunk $(E)/src $(E)/meta.tsv $(E)/text.jsonl < $(E)/list
	python3 example/embed.py document $(E)/text.jsonl $(E)/vectors.bin
	python3 example/embed.py query example/queries.tsv $(E)/queries.bin
	$(B)/aildb build -o $(E)/ail.idx -v $(E)/vectors.bin -m $(E)/meta.tsv -d 768 -i nomic-embed-text -r $(PIN)
	$(B)/aildb check $(E)/ail.idx
	cp $(E)/ail.idx $(E)/copy/moved.idx
	$(B)/example-check $(B)/aildb $(E)/ail.idx $(E)/copy/moved.idx example/queries.tsv $(E)/queries.bin

clean:
	rm -rf $(B)

.PHONY: all test example clean FORCE
