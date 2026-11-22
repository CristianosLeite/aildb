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

The programs are in the repository aildb-bench (`BACKLOG.md`), which
is on the user's machine and not published.

- [ ] Publish aildb-bench: a repository for it and its first push are
  the user's to make or to ask for. Then `docs/performance.md` and
  `README.md` link to it.

- [ ] In aildb-bench: extend the benchmark to cover filtered queries, larger corpora and
  repeated queries in a process with an open snapshot or table. Keep the
  same stored vectors, queries and result limits across engines. Report
  startup and open time separately from query latency. Measure warm and
  cold file-cache runs for both process models. Use the results and a
  stated latency target to decide whether to prototype a parallel scan
  or an approximate index.

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

- [ ] Implement a local, read-only Model Context Protocol server for
  Codex and Claude Code. Start with a separate `aildb-mcp` process over
  [stdio](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports).
  Consider the [official Python SDK](https://github.com/modelcontextprotocol/python-sdk)
  for the adapter and keep ranking in AIL. Configure one snapshot path
  and a local embedding endpoint at startup. Use stdout for MCP messages
  and stderr for diagnostics.

  Expose a `search` tool accepting query text, a bounded `k` and the
  optional path-prefix and language filters. Generate the query vector
  with the model and query prefix used by the indexed corpus. Check the
  embedding dimension and pass the configured model identifier to
  `aildb search`. Invoke the CLI without a shell and send binary32
  query bytes on stdin. Return an object with the model, source revision
  and ranked hits with paths, line ranges, scores and `score_bits`.
  Define input and output schemas using the
  [MCP tools contract](https://modelcontextprotocol.io/specification/2025-11-25/server/tools).

  Keep snapshot publication in the `build` CLI. Keep the snapshot path,
  model and embedding endpoint in server configuration. Apply timeouts
  to embedding and search, and report snapshot, model and provider
  failures as tool errors. A CLI call per query opens the current
  snapshot after a rebuild. If measurements justify keeping a mapping
  open, consider an AIL worker using `src/lib/search.aiw` and test its
  reload behavior across atomic replacements.

  Test discovery and calls over stdio with a deterministic embedding
  provider and a fixture snapshot. Compare ranks, filters and score bits
  with the CLI. Cover empty results, mismatched models, provider
  failures and snapshot replacement. Document installation and verify
  one search from Codex and Claude Code, including opening the returned
  source lines at the reported revision.
