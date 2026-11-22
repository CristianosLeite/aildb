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

- [ ] An executable published with a release (user, 2026-11-22):
  `build/aildb` of the tagged revision, with `LICENSE` and `NOTICE`.
  Build from the release tag with an identified AIL revision and attach
  a Linux x86-64 archive and its SHA-256 checksum to the release.
  Smoke-test the extracted executable's `build`, `check` and `search`
  on a clean Linux x86-64 environment without AIL installed. Decide
  whether to add an archive to `v0.1.0` or start with the next release.

## 13. The measurements in a repository of their own

- [ ] Move `bench/` to a repository `aildb-bench` (user, 2026-11-22), as
  the benchmarks of AIL are in ail-bench: the programs of the
  measurements, `make bench` and their tests leave this repository, and
  `docs/performance.md` says where its figures come from.
  Record the engine, harness and compiler revisions alongside the commands
  and environment for each run. Keep the original report tied to the
  revisions used to produce it.

- [ ] Extend the benchmark to cover filtered queries, larger corpora and
  repeated queries in a process with an open snapshot or table. Keep the
  same stored vectors, queries and result limits across engines. Report
  startup and open time separately from query latency. Measure warm and
  cold file-cache runs for both process models. Use the results and a
  stated latency target to decide whether to prototype a parallel scan
  or an approximate index.

## 14. Snapshot input handling

Nothing is left of this step (`BACKLOG.md`).

## 15. Semantic retrieval evaluation

- [ ] Create a fixed query set with expected source locations at a pinned
  corpus revision. Start with all ten queries from the original example
  run, including the four outside the top five, and add queries from other
  repositories before tuning. Record the embedding model digest and
  chunking settings. Record the rank of the first matching location for
  each query and report hit rate at k and mean reciprocal rank. Use the
  same queries to compare chunk sizes, overlap and embedding models.
  Keep the existing example as a smoke test for the path from source
  files to ranked locations and for snapshot copies. See the [original
  example results](example.md#what-it-showed).

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
