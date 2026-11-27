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

## 18. A provider for searches

A provider is a process a request, so a search by text loads the model
before it embeds the one text of its query, and on a graphics card that
load is most of the search
([provider.md](provider.md#on-a-graphics-card-with-cuda)). The user asked
for a provider that serves searches (2026-11-26): the model stays
loaded between two of them. Step 17 has no daemon and no watcher of
files, and that stays so for the index: this is of the provider alone,
and whoever wants nothing running keeps `aildb-llama` as it is.

- [ ] Decide what it is, with the user, before it is written: who
  starts the process that holds the model and who ends it (the user, the
  first search, `aildb-mcp -d` for the time of its session), how a
  request reaches it (a socket of the user under `XDG_RUNTIME_DIR`, or
  `llama-server` of llama.cpp over HTTP as `aildb-ollama` asks Ollama),
  and what the rule of which commands are run and the identity of a
  configuration mean for a process that was started before the search.
  The decision goes into `.agents/knowledge/architecture/`.
- [ ] The provider, as an adapter in `adapters/` that speaks the
  protocol of `docs/provider.md` unchanged, so `aildb` needs no word of
  it: a query is answered by the model that is loaded, and a search with
  no such process running fails with a line that says how it is
  started, or falls back to a process a request, as decided. Its tests
  run against a program in the place of the model, as
  `tests/adapter_llama.aiw` does, and one kills the process between two
  searches.
- [ ] `docs/provider.md` and `docs/install.md` say how it is set up, on
  the processor and on a card, and what was checked: the same vectors
  as `aildb-llama` gives for the same program and model, and the time
  of a search with and without it, by a command of this repository or
  of aildb-bench.
