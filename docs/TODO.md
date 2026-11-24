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

Versions 0.1.0 and 0.1.1 are tagged (`BACKLOG.md`).

- [ ] Attach the archive of `make dist` and its `.sha256` to a release
  (user, 2026-11-22: the archive is for `v0.1.0`, whose release is a
  draft without files; `v0.1.1` has no release yet). The archive of
  `v0.1.0` is made and tried (`BACKLOG.md`); it is done at the user's
  word.

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
  dimension and its prefixes constants of `example/embed.aiw`; make them
  arguments, run each variant on both corpora and add the measures to
  `docs/evaluation.md`. Add queries on a repository of another author
  first, in a language the chunker is taught, since both corpora are
  AIL and Markdown.

## 16. MCP server for coding agents

The server is written (`BACKLOG.md`, [mcp.md](mcp.md)).

- [ ] If the measurements of aildb-bench justify keeping a mapping open,
  an AIL worker on `src/lib/search.aiw` in place of a command a query,
  with a test of its reload across atomic replacements.

## 17. On-demand indexing and text search

The user wants indexing to run only when the aildb CLI is invoked, with
no daemon or filesystem watcher, and wants to choose an embedding provider
independently of the LLM that asks the questions. The commands and data
layouts below are implementation suggestions.

- [ ] Refresh indexes incrementally. Consider a per-file content manifest
  to skip unchanged files and a disposable vector cache keyed by the exact
  embedding input and provider identity. Rechunk new or edited files,
  reuse vectors for identical inputs with updated path and line metadata,
  remove records for deleted files, and request embeddings only for cache
  misses. A model or embedding settings change must invalidate incompatible
  vectors. Build a complete replacement with the existing atomic snapshot
  publication path. Coordinate concurrent refreshes and publish the manifest
  only for a matching snapshot, so a failed provider call or interrupted
  refresh leaves the prior snapshot usable and a retry detects stale state.
  Test unchanged inputs, single-file edits, moves, deletion of the last
  document, provider changes, and interrupted or overlapping refreshes.
- [ ] Propose `aildb search [DIRECTORY] --text QUERY` as the text search
  entry point. Resolve the directory's index and provider settings, create
  or refresh the snapshot if needed, embed the query with the same provider
  configuration, and return the usual ranked paths and lines or PDF pages.
  An up-to-date index makes only the query embedding call. Preserve the
  existing vector-input `search`, `build` and `check` commands. Add an
  end-to-end test for the first search, a repeat search without document
  embedding calls, and a search immediately after an uncommitted edit.
- [ ] Make MCP an optional stdio adapter for the same text search command.
  The MCP client starts it and supplies the directory in its configuration.
  Each search request forwards the query, limit and filters to the CLI,
  which owns index refresh and embedding generation. The calling LLM can
  be changed without rebuilding the index. Test the first search and a
  search after an edit through MCP, with the same provider configuration,
  results and error handling as direct CLI use.
- [ ] Document and verify a fresh-install workflow with directory indexing,
  text search and automatic refresh from the CLI using the local adapter.
  Include the one-time provider setup, where the index and cache live,
  how to switch models, and optional MCP setup. Make the managed workflow
  available in the installed CLI and verify it from the packaged artifact.
