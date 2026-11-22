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

The statements are written and in `main` of AIL (`docs/BACKLOG.md`).

- [ ] Float literals (user's proposal): not needed for version 1.

## 12. aildb as a package

AIL has packages (a manifest `Ailfile`, `use "name:path"`, the command
`ail`; its pull requests 17 to 26, in its `main` since 2026-11-22). aildb
is one, and `example/consumer` imports it.

Nothing is left of this step (`BACKLOG.md`).

## 11. Release

Version 0.1.0 is tagged (`BACKLOG.md`).

- [ ] Attach the archive of `make dist` and its `.sha256` to the release
  `v0.1.0` (user, 2026-11-22: the archive is for `v0.1.0`), which is a
  draft without files; it is done at the user's word. The archive is
  made and tried (`BACKLOG.md`).

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

The fixed queries, their places and the measures are done (`BACKLOG.md`,
[evaluation.md](evaluation.md)).

- [ ] Use the queries of `make eval` to compare chunk sizes, overlap,
  the path as part of the embedded text and embedding models. The limits
  of a chunk are constants of `example/chunk.aiw` and the model, its
  dimension and its prefixes constants of `example/embed.py`; make them
  arguments, run each variant on both corpora and add the measures to
  `docs/evaluation.md`. Add queries on a repository of another author
  first, in a language the chunker is taught, since both corpora are
  AIL and Markdown.

## 16. MCP server for coding agents

The server is written (`BACKLOG.md`, [mcp.md](mcp.md)).

- [ ] Name the server SDK by its address and a version: ail-extensions
  is a package since 2026-11-22, with the SDK as
  `ail-extensions:mcp/src/mcp.aiw`, and `mcp/Ailfile` still names it by
  its directory beside this repository, since it has no tag yet (the
  user's to give). Until then `make mcp-test` is no part of `make test`.
  It also needs a version of AIL that has the libraries (an item of the
  TODO of AIL).
- [ ] If the measurements of aildb-bench justify keeping a mapping open,
  an AIL worker on `src/lib/search.aiw` in place of a command a query,
  with a test of its reload across atomic replacements.
