# TODO

Work remaining after version 1. Completed steps and items are in
`BACKLOG.md`. Version 1 was stated in `REQUIREMENTS.md`, which left the
repository on 2026-11-21 (its last form is at commit `ddc2b4d`). Its four
acceptance checks are met. `BACKLOG.md` quotes the first and fourth under
their steps. The decisions behind the steps are in
`.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 1. binary32 in AIL (work in the AIL repository)

The statements are written and in `main` of AIL, and float literals are
in AIL since its version 0.1.2 (`docs/BACKLOG.md`).

Nothing is left of this step here.

## 12. aildb as a package

AIL has packages (a manifest `Ailfile`, `use "name:path"`, the command
`ail`; its pull requests 17 to 26, in its `main` since 2026-11-22). aildb
is one, and `example/consumer` imports it.

Nothing is left of this step (`BACKLOG.md`).

## 11. Release

Versions 0.1.0, 0.1.1 and 0.1.2 are tagged, and each release has its archive
(`BACKLOG.md`). The release of `v0.1.0` is a draft: to publish it is the
user's.

## 13. The measurements in a repository of their own

The programs are in the repository
[aildb-bench](https://github.com/CristianosLeite/aildb-bench) (`BACKLOG.md`).

- [ ] The measurements of filters, of a process that stays and of
  1,000,000 records are made (`BACKLOG.md`; the figures are in
  `docs/performance.md` of aildb-bench). Left: make the run again on a
  machine that is left alone, state a latency target, and decide with
  both whether to prototype a parallel scan or an approximate index
  (user, 2026-11-22: measure only, for now).

## 14. Snapshot input handling

Nothing is left of this step (`BACKLOG.md`).

## 15. Semantic retrieval evaluation

The fixed queries, their places, the measures and the comparison of
variants are done (`BACKLOG.md`, [evaluation.md](evaluation.md)). Whether
a default changes for what the comparison showed is the user's to decide
(`.agents/knowledge/status/open-items.md`).

## 16. MCP server for coding agents

The server is written (`BACKLOG.md`, [mcp.md](mcp.md)).

- [ ] If the measurements of aildb-bench justify keeping a mapping open,
  an AIL worker on `src/lib/search.aiw` in place of a command a query,
  with a test of its reload across atomic replacements.

## 17. On-demand indexing and text search

The user wants indexing to run only when the aildb CLI is invoked, with
no daemon or filesystem watcher, and wants to choose an embedding provider
independently of the LLM that asks the questions. It is written
([install.md](install.md), [index.md](index.md), [provider.md](provider.md)).

The eight findings of the review of `5eeba0b` are fixed but one, the
six of the review of `6c707bc` but the same one, and the four others
of the review of `cb9285a`, the three of the review of `b515e72` and
the one of the review of `acb1a70` all (`BACKLOG.md`); their choices
wait for the user's review
(`.agents/knowledge/status/open-items.md`).

Nothing of them is open: the AIL that `Ailfile` asks for is 0.1.2
since 2026-11-24 (`BACKLOG.md`).

## 18. The runtime of AIL, and Windows

The user wants aildb on the version 0.2.1 of AIL and on Windows (user,
2026-11-26). AIL 0.2 has a runtime, the statement `rt`, whose services
have the same names on x86-64 Linux and on x86-64 Windows, and a
compiler that writes executables of Windows; the statement `sys` is no
statement there, so a source with one is not compiled for Windows. The
first part is done: `Ailfile` asks for 0.2.1 and what the runtime has
is asked of it (`BACKLOG.md`). The decisions are in
`.agents/knowledge/architecture/runtime-and-windows.md`.

What is left needs services that AIL 0.2.1 has not, and so a later
version of AIL (the user's to give); the 76 statements `sys` that are
left, 40 of them in `src/`, `adapters/` and `mcp/src/`, are the ones
that wait for them.

In the AIL repository:

- [ ] Services of the runtime, each in both runtimes with a test that
  runs under Wine: a file mapped to be read; a file and a directory
  flushed; the kind, size and times of a file, by a descriptor and by
  a path that is not followed; a position in a file, a write at a
  position, a file cut to a length; a lock that does not wait; the
  time of day; random bytes; a file with no name for the input and the
  outputs of a child; a process ended; a file opened below an open
  directory with no link followed, and the path of an open descriptor;
  which platform the program runs on.
- [ ] A target for `ail build` and `ail test`, the tests of a target
  for Windows run under Wine on Linux, with a list of the tests that
  are not for it; the compiler for Windows in the archive of a release.
- [ ] Before either: whether Windows lets a snapshot be replaced while
  another process has it mapped, under Wine and on Windows itself. If
  it does not, a reader there reads the file into memory, and
  `docs/performance.md` says what that costs.

Here, on that version of AIL, one commit each:

- [ ] `src/lib/os.aiw`: what differs by platform, in one file: the
  separator and a path from the root, the paths of a snapshot kept with
  `/`, the directory of the user's configuration, the directories of
  `PATH` and the endings of a program's name, the device that is empty.
- [ ] The snapshot on the runtime: `src/lib/snap.aiw`, `src/main.aiw`,
  `src/lib/cache.aiw` and `src/hook.aiw` with no `sys`.
- [ ] No link on the way, without `/proc`: `src/lib/below.aiw`,
  `src/index.aiw` and `src/lib/trust.aiw` on the two services for it.
- [ ] The files of an index looked at with the runtime
  (`src/lib/tree.aiw`), and the time a run starts.
- [ ] A child with files that have no name in place of files in memory
  (`src/lib/run.aiw`, `mcp/src/run.aiw`, `adapters/llama.aiw`), and a
  program found as Windows finds one.
- [ ] A line that ends with CR and LF in a configuration and in the
  metadata of `build`.
- [ ] The tests without a shell: the steps of `tests/lib/dir.aiw` and
  of the tests that run `/bin/sh` written in AIL, a process ended by
  the runtime, and the list of the tests that only Linux has (named
  pipes, limits of a process, links a test makes, `/dev/full`).
- [ ] The archive for Windows (`tools/dist.sh`), its check under Wine,
  and the tests of the target for Windows on GitHub.
- [ ] The documents: what a build assumes of NTFS in
  `docs/durability.md`, and the paths, the limits (a path of 260
  bytes, names that are not UTF-8) and the installation on Windows.
- [ ] A run of the archive on Windows itself, noted with its day and
  machine, before a version says it supports Windows.
