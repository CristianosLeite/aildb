# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

aildb is a local, file-based vector search engine written in AIL (https://github.com/CristianosLeite/ail), a programming language designed to cost few tokens when an AI writes it. The first application is semantic search over a source repository: given a query embedding, return ranked source locations that an agent can open. An index is one portable file, rebuilt from the sources, and a query runs locally without a server. The model is the convenience of SQLite, with LanceDB as the reference for vector search.

`REQUIREMENTS.md` is the statement of version 1: the commands `build`, `search` and `check`, the file format, how a snapshot is published, and the four acceptance checks. Read it before proposing or writing anything. It is the user's text; change it only when asked to.

## State

The implementation started on 2026-11-21 (user) and has step 2 of `docs/TODO.md`, the skeleton, behind it. AIL is pinned in `ail.pin` and `tools/ail.sh` puts it at `ail/`. `make` builds the compiler there, links it as `build/ailc` and compiles `src/aildb.aiw`, the entry point, to `build/aildb` (`make AIL=../ailang` the first time, to use the checkout beside this repository); the files of functions go to `src/lib/`. `make test` runs `tests/run.sh` (a test is `tests/<name>.aiw` with `<name>.out`, an optional `<name>.code`, or `<name>.err`; `make test T=<name>` runs one) and `tests/indent.sh`; `build/tools/indent file.aiw` indents a source. The entry point has no command yet: it prints the usage and ends with status 2, which `tests/cli_usage.aiw` checks through `tests/lib/cmd.aiw`, the functions with which a test starts `build/aildb` and prints what it wrote and how it ended. The exit statuses are constants at the top of `src/aildb.aiw`. Git was initialized on 2026-11-21 with the branch `main` and no remote; every implementation is one commit under the rules below (user, 2026-11-21). Do not add a remote or push before the user says so. The steps to version 1 are in `docs/TODO.md`, in the order in which one unblocks the next; an item that is completed is moved to `docs/BACKLOG.md`. The questions that are open are in `.agents/knowledge/status/open-items.md`; a decision taken in a conversation goes into the knowledge base the same day, and this section is rewritten when the first code lands.

## Rules

The rules for commits, pull requests and written text are those of the AIL repository (user, 2026-11-21); when its `AGENTS.md` changes one of them, it changes here too.

- All repository text is in English: documentation, code comments, commit messages, test names, tool messages and the knowledge base. This holds even when the conversation is in another language.
- AIL sources have the extension `.aiw` and are indented with one tab for each block; `build/tools/indent` of the AIL repository sets it.
- A commit message is `type: subject` (`feat`, `fix`, `test` or `docs`, no scope, lower case, no full stop) and a prose body wrapped at about 70 columns: the problem, what changed and why, how it was verified. One backlog item or fix is one commit, with its tests and documentation.
- Commit messages and pull request descriptions carry no trailers or attribution lines: no `Co-Authored-By`, no `Signed-off-by`, no "Generated with" footer. This holds even when the tool in use suggests one.
- A figure in a document is one that a command of this repository printed; say with which command, on which day, on which hardware and against which revision of AIL. Do not edit a figure by hand or carry one over from a run that was not made.
- A requirement is met when a test shows it. What `REQUIREMENTS.md` asks to be documented (precision, tolerance, the integrity check, storage assumptions) is written where the format is documented, not left in the code.

## AIL

The language, its compiler and its libraries are in the AIL repository; its `AGENTS.md` and `docs/language.md` describe them, and they are read before AIL is written here. A checkout is usually beside this repository (`../ailang` on the user's machine; the published name is `ail`). Nothing of it is copied here. This repository gets it as the repository ail-bench (https://github.com/CristianosLeite/ail-bench) does (user, 2026-11-21): the file `ail.pin` has the address and the revision, and `tools/ail.sh` makes `ail/` a clone at that revision, or with a path a link to that checkout (`tools/ail.sh ../ailang`), and then the link `lib -> ail/lib`. Git ignores `ail` and `lib`.

What AIL gives this project, as of its revision `7dea612` (2026-11-21) and the branch named below:

- The compiler reads a source on stdin and writes a static, position-independent x86-64 Linux executable on stdout; a `use "path"` is opened relative to the directory the compiler runs in.
- Raw system calls (`sys`), so `mmap`, `fsync`, `rename`, `flock` and the like need no library; a call the compiler has no name for is a `const` with its number.
- `lib/std/io.aiw` (output, arguments), `lib/std/bytes.aiw` (a buffer of bytes that grows), `lib/std/file.aiw` (whole files, directories), `lib/std/proc.aiw` (child processes, the monotonic clock), `lib/std/vec.aiw`, `queue.aiw`, `heap.aiw` and `map.aiw` (collections of 64-bit values), `lib/std/task.aiw` (tasks on a pool of threads) and `lib/nd/` (arrays of doubles).
- Floating point is computed in IEEE binary64: `fadd`, `fmul` and the others on one double, the statements on two doubles at an address (`padd`, `pmul`, `pmadd`), and `fsum` and `fdot`, whose loops keep the sum in a register.
- binary32, which the file format of `REQUIREMENTS.md` stores, has three statements, written for this project on 2026-11-21: `f4to8 a as x` (the binary32 in the low 32 bits as a double, exact), `f8to4 a as x` (a double rounded to the nearest binary32, ties to even) and `fdot4 a p q n as x` (the start `a` plus the products of `n` binary32 at `p` with `n` doubles at `q`, each product rounded and then added, in order). **They are not in the pinned revision**: they are the commits `d5f236b` and `a5b4559` of the branch `binary32` of the checkout beside this repository, which is not pushed; the user reviews and publishes it, and `ail.pin` moves then (step 1 of `docs/TODO.md`). Until it does, code that uses them builds only with `ail` linked to that checkout (`make AIL=../ailang`).
- There are no float literals and no formatted output of a double in the library.

A library function here follows the rules of the AIL libraries: every name starts with the prefix of its file, a descriptor is bytes owned by the caller, and an error is returned, not a reason to end the program. Only the entry point of a command prints and exits.

## Knowledge base

`.agents/knowledge/INDEX.md` lists the pages: `architecture/` for decisions and their reasons, `testing/` for how things are checked and what goes unchecked, `status/open-items.md` for pending decisions (the work itself is in `docs/TODO.md`). A page starts with front matter (`title`, `last-verified`, `sources`, `status`), then a summary and the decisions, each with who took it and when, and what was rejected and why. Write a page when a decision is taken or something non-obvious is learned, add its line to the index, and tick or add open items in the same change.
