# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

aildb is a local, file-based vector search engine written in AIL (https://github.com/CristianosLeite/ail), a programming language designed to cost few tokens when an AI writes it. The first application is semantic search over a source repository: given a query embedding, return ranked source locations that an agent can open. An index is one portable file, rebuilt from the sources, and a query runs locally without a server. The model is the convenience of SQLite, with LanceDB as the reference for vector search.

Version 1 is the commands `build`, `search` and `check`, the snapshot file, the way a snapshot is published, and four acceptance checks. It was stated in a file `REQUIREMENTS.md`, the user's text, which the user took out of the repository on 2026-11-21; its last form is in the history, at the commit `ddc2b4d` (`git show ddc2b4d:REQUIREMENTS.md`), and the knowledge base cites it under that name. What it asked for is now in the documents below and in the tests, and what is still to be done, with the words of acceptance check 4, in `docs/TODO.md`; those of acceptance check 1 are in `docs/BACKLOG.md`. Read those before proposing or writing anything.

## State

The implementation started on 2026-11-21 (user). Steps 0 to 9 of `docs/TODO.md` are done: the three commands work and the acceptance checks 1, 2 and 3 pass. The revision `76104ec` was reviewed on 2026-11-21, in a file `REVIEW.md` that was never part of the repository; its findings in the code were fixed in the commits after it (the temporary file and the lock, a vector element that is not finite, the length of a query, a path outside the repository, an output that cannot be written), and `ail.pin` names a revision that builds the engine. The example is step 9: `make example` indexes AIL at the pinned revision with nomic-embed-text and passed as acceptance check 1 on 2026-11-21; it needs a running Ollama and is no part of `make test`. What is left is the measurements against LanceDB (step 10, acceptance check 4) and the release. An item that is completed is moved to `docs/BACKLOG.md`. The questions that are open are in `.agents/knowledge/status/open-items.md`; a decision taken in a conversation goes into the knowledge base the same day. aildb is distributed under the Apache License 2.0 (user, 2026-11-21), the file `LICENSE`. Git has the branch `main` and no remote; every implementation is one commit under the rules below (user, 2026-11-21). Do not add a remote or push before the user says so.

The documents the code follows, each changed in the commit that changes what it describes:

- `docs/usage.md`: the three commands, their options, inputs, JSON Lines and exit statuses (0, 2 usage, 3 invalid snapshot or input, 4 I/O, 5 build in progress, 6 published without confirmed durability).
- `docs/format.md`: the snapshot file, version 1, the validation a reader does, the definition of a score, the tolerances and the limits.
- `docs/durability.md`: what a build leaves when it is interrupted and what it assumes for a loss of power.
- `docs/example.md`: the example: how the chunker cuts the files of a repository, how `example/embed.py` gets the embeddings from nomic-embed-text run by Ollama, what `make example` does and what it showed.

The layout and the limits of the format, the option letters and the form of the output lines were chosen by the agent and wait for the user's review (open items).

How it is built and tested:

- `make` runs `tools/ail.sh`, which puts AIL at `ail/` (a clone at the revision of `ail.pin`, or a link: `make AIL=../ailang`) and links `lib`; builds the compiler there, links it as `build/ailc`, and compiles `src/aildb.aiw` to `build/aildb`. `build/tools/indent file.aiw` indents a source.
- `make test` also builds `build/aildb-stops` and `build/chunk`, the chunker of the example (`example/chunk.aiw`, with `tests/example_chunk.aiw`), and runs `tests/run.sh` and `tests/indent.sh`. A test is `tests/<name>.aiw` with `<name>.out`, an optional `<name>.code`, or `<name>.err`; it is compiled and started at the top of the repository and works in the directory of `AILDB_TMP`. `make test T=<name>` runs one.
- `make example` builds `build/example-check` from `example/check.aiw` and runs the example in `build/example/`, with the queries and their expected lines of `example/queries.tsv`.
- The expected output of a test that prints what the engine wrote is made by running the test once and reading the result against what was reasoned or computed outside (Python for bits of floating point, CRC-32 and UTF-8); say in the commit how it was checked.

Where things are:

- `src/aildb.aiw` compiles `src/main.aiw`, the commands and the only file that prints and exits, with the hooks of `src/hook.aiw`, which do nothing. `tests/lib/stops.aiw` compiles the same commands with `tests/lib/hook.aiw` into `build/aildb-stops`, which stops or fails a sync where the file `aildb.hook` of a test asks. Nothing of the test hooks may be in `build/aildb` (`tests/cli_build_publish.aiw` checks it).
- `src/lib/`: `crc.aiw` (CRC-32, eight tables), `fmt.aiw` (a double in decimal and as bits, a JSON string), `text.aiw` (a number, lines and fields, a prefix, a valid string, a path that stays in the repository), `topk.aiw` (the best pairs of score and ordinal in a fixed workspace), `snap.aiw` (a snapshot mapped and validated), `pack.aiw` (the part of a snapshot before its vectors), `meta.aiw` (the metadata of `build`), `norm.aiw` (normalization). Each has `tests/lib_<name>.aiw` or, for the reader, `tests/snap_open.aiw`.
- `tests/lib/`: `cmd.aiw` (start `aildb` and print what it did; `aildb` and `aildb-stops` are found in `build/`), `mk.aiw` (a snapshot written from `docs/format.md` with no code of the engine), `wide.aiw` and `oracle.aiw` (the independent implementation of acceptance check 2).
- The tests of the commands are `tests/cli_*.aiw`; `tests/oracle_search.aiw` is acceptance check 2, and `tests/cli_check_invalid.aiw`, `tests/cli_malformed.aiw`, `tests/kill_build.aiw`, `tests/cli_build_publish.aiw` and `tests/readers_rebuild.aiw` are acceptance check 3; `tests/cli_output_closed.aiw` is the output that cannot be written.

## Rules

The rules for commits, pull requests and written text are those of the AIL repository (user, 2026-11-21); when its `AGENTS.md` changes one of them, it changes here too.

- All repository text is in English: documentation, code comments, commit messages, test names, tool messages and the knowledge base. This holds even when the conversation is in another language.
- AIL sources have the extension `.aiw` and are indented with one tab for each block; `build/tools/indent` of the AIL repository sets it.
- A commit message is `type: subject` (`feat`, `fix`, `test` or `docs`, no scope, lower case, no full stop) and a prose body wrapped at about 70 columns: the problem, what changed and why, how it was verified. One backlog item or fix is one commit, with its tests and documentation.
- Commit messages and pull request descriptions carry no trailers or attribution lines: no `Co-Authored-By`, no `Signed-off-by`, no "Generated with" footer. This holds even when the tool in use suggests one.
- A figure in a document is one that a command of this repository printed; say with which command, on which day, on which hardware and against which revision of AIL. Do not edit a figure by hand or carry one over from a run that was not made.
- A requirement is met when a test shows it. What is to be documented (precision, tolerance, the integrity check, storage assumptions) is written where the format is documented, not left in the code.

## AIL

The language, its compiler and its libraries are in the AIL repository; its `AGENTS.md` and `docs/language.md` describe them, and they are read before AIL is written here. A checkout is usually beside this repository (`../ailang` on the user's machine; the published name is `ail`). Nothing of it is copied here. This repository gets it as the repository ail-bench (https://github.com/CristianosLeite/ail-bench) does (user, 2026-11-21): the file `ail.pin` has the address and the revision, and `tools/ail.sh` makes `ail/` a clone at that revision, or with a path a link to that checkout (`tools/ail.sh ../ailang`), and then the link `lib -> ail/lib`. Git ignores `ail` and `lib`.

What AIL gives this project, as of its revision `a5b4559` (2026-11-21):

- The compiler reads a source on stdin and writes a static, position-independent x86-64 Linux executable on stdout; a `use "path"` is opened relative to the directory the compiler runs in.
- Raw system calls (`sys`), so `mmap`, `fsync`, `rename`, `flock` and the like need no library; a call the compiler has no name for is a `const` with its number.
- `lib/std/io.aiw` (output, arguments), `lib/std/bytes.aiw` (a buffer of bytes that grows), `lib/std/file.aiw` (whole files, directories), `lib/std/proc.aiw` (child processes, the monotonic clock), `lib/std/vec.aiw`, `queue.aiw`, `heap.aiw` and `map.aiw` (collections of 64-bit values), `lib/std/task.aiw` (tasks on a pool of threads) and `lib/nd/` (arrays of doubles).
- Floating point is computed in IEEE binary64: `fadd`, `fmul` and the others on one double, the statements on two doubles at an address (`padd`, `pmul`, `pmadd`), and `fsum` and `fdot`, whose loops keep the sum in a register.
- binary32, which the snapshot file stores, has three statements, written for this project on 2026-11-21: `f4to8 a as x` (the binary32 in the low 32 bits as a double, exact), `f8to4 a as x` (a double rounded to the nearest binary32, ties to even) and `fdot4 a p q n as x` (the start `a` plus the products of `n` binary32 at `p` with `n` doubles at `q`, each product rounded and then added, in order). They are the commits `d5f236b` and `a5b4559` of the branch `binary32` of the AIL repository, and `ail.pin` names the second since 2026-11-21; the branch is not merged into `main` there.
- There are no float literals and no formatted output of a double in the library.

A library function here follows the rules of the AIL libraries: every name starts with the prefix of its file, a descriptor is bytes owned by the caller, and an error is returned, not a reason to end the program. Only the entry point of a command prints and exits.

## Knowledge base

`.agents/knowledge/INDEX.md` lists the pages: `architecture/` for decisions and their reasons, `testing/` for how things are checked and what goes unchecked, `status/open-items.md` for pending decisions (the work itself is in `docs/TODO.md`). A page starts with front matter (`title`, `last-verified`, `sources`, `status`), then a summary and the decisions, each with who took it and when, and what was rejected and why. Write a page when a decision is taken or something non-obvious is learned, add its line to the index, and tick or add open items in the same change.
