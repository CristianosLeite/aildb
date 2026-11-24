# Backlog

The work that is done: every item that was in [TODO.md](TODO.md) and has been
completed, under the section it had there.

## 0. Decisions before the first code

- [x] `REQUIREMENTS.md`: the amendment drafted on 2026-11-21 was accepted by
  the user the same day and applied, eleven passages: tests, harness and
  chunker in AIL; raw binary32 and tab-separated inputs; the AIL repository
  and a local open model for the example; JSON Lines with the score also as
  bits; `build` normalizes; a read-only mapping and the binary32 statements
  of AIL; two CRC-32; no stop point in the shipped executable; the oracle in
  AIL; the Python binding of LanceDB.
- [x] Stop points of the interruption tests: a second executable,
  built by the tests from the same sources, is what was meant (user,
  2026-11-21).
- [x] Tolerances: the same bits for a sum in the order of the engine, 1e-12
  for another order, about 1e-5 against LanceDB (user, 2026-11-21).
- [x] The licence: aildb is distributed under the Apache License 2.0
  (user, 2026-11-21); its text is the file `LICENSE`.
- [x] Overlapping builds: `flock` on `<destination>.lock` (user, 2026-11-21).
- [x] Semantics: path prefix by bytes, language by equality, the empty
  index valid, a filter that matches nothing gives no line and status 0;
  the statuses 0 success, 2 usage, 3 invalid file or input, 4 I/O, 5 build
  in progress, 6 published without confirmed durability (user,
  2026-11-21).
- [x] The limits of k, dimension and count: in `docs/format.md`, chosen by
  the agent when the format was written.
- [x] Git: the repository was initialized on 2026-11-21, with a
  `.gitignore`. Its remote is https://github.com/CristianosLeite/aildb,
  public, under the name `aildb`, made and pushed to on 2026-11-21
  (user).

## 1. binary32 in AIL (work in the AIL repository)

- [x] `f4to8 a as x` and `f8to4 a as x`: rows of `optab`, cases in
  `tests/insn.cases`, tests, `docs/language.md`.
- [x] `fdot4 a p q n as x`, with the loop `movss` / `cvtss2sd reg,reg` /
  `mulsd` / `addsd`; a test that its bits are those of `f4to8`, `fmul` and
  `fadd` in order.

Both are commits of the branch `binary32` of the AIL checkout (`d5f236b`
and `a5b4559`, 2026-11-21); `make test` passed there.
- [x] Move `ail.pin` to the revision that has the three statements:
  `a5b4559`, the head of the branch `binary32`, which was on the remote of
  the AIL repository on 2026-11-21. A clone of this repository on that day
  fetched it, built the compiler from the seed and passed `make test`.
  The branch was merged into `main` there afterwards (`e8acf57`) with
  its commits kept, so the pin stays.

## 2. Skeleton

- [x] `ail.pin`, `tools/ail.sh` and the link `lib -> ail/lib`, as ail-bench
  has them.
- [x] `Makefile`: the compiler linked from `ail/`, one executable `aildb`
  from `src/aildb.aiw`, compiled into a temporary file and moved.
- [x] `tests/run.sh` in the manner of AIL (`name.aiw` with `name.out`,
  `name.code` or `name.err`), and the indentation check.
- [x] `aildb` with no command or an unknown one: usage on stderr and the
  usage status.

## 3. The documented format

- [x] `docs/format.md`: header (magic, version, flags, dimension, count,
  offsets and sizes of the sections), the model identifier and the source
  revision, records of fixed size, strings, the vectors aligned to 4096;
  the two CRC-32 and what each covers; how normalization is recorded;
  precision and tolerance of a score; limits.
- [x] `docs/usage.md`: the three commands, their options and statuses; the
  inputs (raw binary32, TSV columns) and the JSON Lines of the results,
  with the order of the fields.

## 4. Libraries (`src/lib/`, each with tests)

- [x] CRC-32 with eight tables, tested against known values of zlib.
- [x] A double as decimal and as 16 hexadecimal digits; a JSON string.
- [x] An unsigned number from text, lines and tab-separated fields, a
  prefix test.
- [x] Top-k of (score, ordinal) in a bounded workspace, ties by ordinal.
- [x] binary32 to binary64 with integer statements, kept for the oracle:
  `tests/lib/wide.aiw`, with the tests and not in `src/lib/`, since the
  oracle shares nothing with the engine.

## 5. Reading a snapshot, and `check`

- [x] Open, `fstat`, map read-only; validate lengths, offsets, counts and
  arithmetic before any access; verify the CRC-32 of header and metadata.
- [x] `check`: also the CRC-32 of the vectors; prints record count,
  dimension and model identifier.
- [x] Tests on files written by hand: unknown version, each field out of
  range, truncation, one vector byte changed with the length kept.

## 6. `build`

- [x] The part of the file before the vectors put together in memory as
  `docs/format.md` says (`src/lib/pack.aiw`): split from the item that
  wrote the file, whose rest went to the items of the inputs and of the
  publication.
- [x] Read the vectors, the TSV, the model identifier and the source
  revision when there is one; reject a wrong length, a value that is not
  finite, a zero vector, a path with a tab; normalize in binary64 and round
  with `f8to4`; write the file as `docs/format.md` says, through a
  temporary file and a rename.
- [x] Publication: lock, temporary file in the destination directory,
  `fsync`, validation with the reader of step 5, `rename`, `fsync` of the
  directory; write and sync
  failures reported, and the case of a rename that succeeded with a
  directory sync that failed.
- [x] `docs/durability.md`: the filesystem and storage assumptions for a
  loss of power.

## 7. `search`

- [x] Read the query (file or stdin), reject a wrong dimension, a value
  that is not finite, a zero vector, a limit that is not positive, a model
  identifier that differs; normalize.
- [x] Filters before scoring, the scan with `fdot4` over buffers allocated
  once, top-k, JSON Lines with the first line of source revision and model.

## 8. Acceptance checks 2 and 3

- [x] The oracle: an AIL program apart from the engine, with its own
  reader and loop; the same top-k and the same bits on generated files.
  Empty collection, a filter with no match, equal scores in record order,
  k above the eligible count. The difference to a cosine that divides by
  the norm of the stored vector is reported apart.
- [x] Malformed inputs of `build` and `search`, each with its diagnostic
  and status.
- [x] Interruption: the test executable with stop points before and after
  `rename`, and kills at varying moments of the shipped one; the
  destination is absent, or a complete old or new snapshot.
- [x] A failed rebuild keeps the previous file; an overlapping build is
  rejected; readers that opened before a rebuild finish on the old file.

## 9. The example, and acceptance check 1

Acceptance check 1: build a snapshot for a real repository, query it end
to end, and verify that results identify the expected source lines; copy
the file to another path and verify the same query results.

- [x] The chunker in AIL: `build/chunk`, from `example/chunk.aiw`, cuts
  the `.aiw` and `.md` files of a list into chunks of whole lines, a
  function or a section each, 40 lines and 1500 bytes at most, and writes
  the TSV and the text of each chunk; `docs/example.md` has the rules.
- [x] The embedding step outside the engine: nomic-embed-text (user,
  2026-11-21) run by Ollama, asked by `example/embed.py`, a Python
  program of the standard library that writes the raw binary32.
- [x] `make example`: chunk, embed, build, check, copy, and
  `build/example-check` with the queries of `example/queries.tsv`, whose
  expected lines are among the five results, and the same bytes from the
  copy. Passed on 2026-11-21; `docs/example.md` has the output and the
  four queries of ten that were taken out.

## 10. Measurement, and acceptance check 4

Acceptance check 4: measure top-10 at 10,000 and 100,000 vectors of 768
dimensions. Report median and p95 end-to-end latency for cold and warm
file-cache conditions, search time apart from startup, peak resident
memory, and file size. Compare exact search with the Python binding of
LanceDB on the same inputs and report the hardware, revisions, commands,
cache procedure, and rounds. Use the results to decide whether approximate
indexing or parallel scans are warranted, and measure again the choice of
a read-only mapping. Give both engines the same stored vector values,
query and result limit; define the timing boundaries for process startup,
snapshot or table opening, search and result materialization; document
how cold-cache conditions are verified for each engine's files and how
mapped pages contribute to reported peak resident memory.

- [x] The harness in AIL: `build/bench-run` runs a command for a number
  of rounds, warm or with the files put out of the cache by `fadvise64`
  and verified with `mincore`, and reports wall time, the parts of it
  that `build/aildb-times` says (startup, opening, search, output), the
  processor time and the peak resident memory; `bench-gen` makes the
  inputs and `bench-scan` reads the vectors in three ways.
- [x] The same stored values, query and limit in LanceDB through its
  Python binding: `bench/lance_make.py` copies the vectors of a snapshot
  into a table, `bench/lance_query.py` searches it and says its moments,
  `bench/lance_same.py` compares the answers, and `make bench` runs all
  of it. `docs/performance.md` has the boundaries of each time, how the
  cold cache is verified for the files of each engine, and how mapped
  pages count in the peak resident memory.
- [x] `docs/performance.md` with the figures at 10,000 and 100,000 vectors
  of `make bench` on 2026-11-21, and the decisions: the read-only mapping
  stays, and version 1 has no approximate index and no parallel scan.

## 11. Release

- [x] `README.md`: how to build, the three commands on an index of
  three vectors with the output they print, the example, and the times of
  a query from `docs/performance.md`.
- [x] The MIT notice of AIL for an executable that is passed on, since
  the code of its library is compiled into `build/aildb`: the file
  `NOTICE`, which goes with an executable beside `LICENSE`.
- [x] `AGENTS.md` and the knowledge base brought up to date for the
  release: the section "State" says that version 1 is written and not
  released, and the pages that spoke of work to come say what was done.
- [x] A mechanism of versions that AIL and everything derived from it
  share (user, 2026-11-22): the manifest `Ailfile` and the command `ail`
  of AIL, its pull requests 17 to 26.
- [x] The release: the tag `v0.1.0`, the version in `Ailfile`, at
  `467b91b` (2026-11-22, at the user's word), after the packages were in
  `main` of AIL and AIL had its own tag `v0.1.0`, at its `9b94a9b`. No
  executable is published.
- [x] The archive of a release: `make dist` (`tools/dist.sh`) takes the
  sources of a tag out of git, builds them with the command of AIL and
  packs `aildb`, `LICENSE`, `NOTICE` and `BUILD`, which names the
  revisions of aildb and of AIL, into
  `build/dist/aildb-<version>-x86_64-linux.tar.gz`, with its `.sha256`;
  `make dist-check` (`tools/dist-check.sh`) runs `build`, `check` and
  `search` of the unpacked executable in a Docker container without AIL.
  The archive is for `v0.1.0` (user, 2026-11-22). Attaching it to the
  release is left in `TODO.md`.
- [x] The version 0.1.1 (user, 2026-11-22: every package of the family
  to 0.1.1, with AIL): `Ailfile`, `mcp/Ailfile` and
  `example/consumer/Ailfile` say it and ask for AIL 0.1.1, the server
  names ail-extensions 0.1.1, and the tag `v0.1.1` names the merge of
  the change. It is the first version with the fix of the named pipe,
  the evaluation, the archive of a release and the MCP server.

## 12. aildb as a package

- [x] The search as a library, `src/lib/search.aiw`: `searchquery`,
  `searchrun`, `searchcount` and `searchhit`, taken out of `query`,
  `scan` and `results` of `src/main.aiw`, which now calls them; the files
  of `src/lib/` name what they need with `use`. `tests/lib_search.aiw`.
- [x] aildb as a package: `Ailfile` with its executables, built and
  tested by `ail`; `ail.pin`, `tools/ail.sh`, `tests/run.sh` and
  `tests/indent.sh` are gone, the Makefile is the command and the two
  targets it has no word for, and the corpus of the example has its own
  pin.
- [x] A project that imports aildb, `example/consumer`: made with
  `ail new` and `ail add --path`, it searches a snapshot through
  `use "aildb:src/lib/search.aiw"`, and its test shows the bits of the
  scores that the command prints. `docs/library.md`.
- [x] `example/consumer` names aildb by its address and the version
  0.1.0, in place of its directory: `ail add` with the address wrote the
  line `dep` and `Ailfile.lock`, with the revision of the tag `v0.1.0`.
- [x] `example/consumer` names aildb by the version 0.1.1: `ail add`
  wrote the line `dep` and the lock, with the revision of the tag
  `v0.1.1`.

## 13. The measurements in a repository of their own

- [x] `bench/`, `make bench` and the tests `bench_stat` and `bench_tools`
  moved to the repository aildb-bench (user, 2026-11-22), a package of
  AIL that names aildb as a dependency; `src/hook.aiw` and the moments of
  `search` stay. Its report names the revisions of the engine, of the
  harness and of the compiler and the command of each measurement.
  `docs/performance.md` keeps the figures of 2026-11-21, made here at
  `4a21a3e`.
- [x] In aildb-bench, the measurements extended: the two filters, a
  process that keeps the snapshot or the table open (`bench-stay`, on
  `src/lib/search.aiw`; `LANCE_STAY` for LanceDB), with the opening apart
  from a search, warm and cold for both, and 1,000,000 records. Run on
  2026-11-22 for aildb 0.1.0; no target and no decision (user,
  2026-11-22).
- [x] In aildb-bench, `bench_tools` takes a memory line of 0 as a
  measurement (its commit `119c533`): a line `=` is to be there with a
  number, and the reader of `/proc/self/status`, `hooknumber`, says no
  number for a line that is absent or has no digit, with a test of its
  own.
- [x] aildb-bench published (2026-11-22, at the user's word): https://github.com/CristianosLeite/aildb-bench,
  public, its `main` pushed as it was.

## 14. Snapshot input handling

- [x] A named pipe given as a snapshot or as the vectors of `build` is
  refused at once. `snapopen` and `mapfile` opened the path before they
  asked for its kind, and the open of a named pipe waits for a writer;
  they open with `O_NONBLOCK` now, so the check of a regular file that
  was there is reached. `tests/cli_fifo.aiw` gives `check`, `search` and
  `build -v` a pipe that has no writer and two seconds each. The metadata
  and the query are read, not mapped, and may be a pipe as before.

## 15. Semantic retrieval evaluation

- [x] The queries of the evaluation, written before they were embedded:
  the ten of the first run of the example for AIL at `a5b4559`, and ten
  new ones for aildb at `v0.1.0` (user, 2026-11-22: these two corpora).
- [x] `make eval`: for each corpus the place of the first result that has
  the expected lines, among all records, how many queries have it in the
  first 1, 5 and 10, and the mean reciprocal rank (`example/eval.aiw`,
  `tools/eval.sh`, `tests/example_eval.aiw`); the report has the digest of
  the model and the limits of a chunk. `docs/evaluation.md` has the run
  of 2026-11-22. The example stays as it was.

## 16. MCP server for coding agents

- [x] `aildb-mcp`, in `mcp/`: a server of the Model Context Protocol
  over stdio with the tool `search` (a query in words, `k` up to 50, a
  path prefix and a language), written in AIL (user, 2026-11-22: no
  Python; JSON, the decimal to double and HTTP are libraries of AIL, and
  the MCP SDK a module of ail-extensions). It asks the model at an
  endpoint for the vector, checks its dimension, and starts `aildb
  search` with the vector on stdin; the result has the model, the
  revision and the hits as the command printed them. `mcp/tests/search.aiw`
  with an embedding service that answers from a table; `docs/mcp.md`.
- [x] A snapshot replaced by one of another dimension and the same
  model is searched from the next call on: the server compared the
  length of a vector with the dimension it had read when it started, and
  now leaves that to `aildb search`, which compares it with the snapshot
  it opens. `mcp/tests/search.aiw` replaces a snapshot of two dimensions
  by one of three in a session: the vector of three is taken and the one
  of two refused.
- [x] A search asked by an agent: from Claude Code on 2026-11-22, the
  lines of the first hit opened at the revision (`docs/mcp.md`), and from
  Codex, which the user validated the same day and reported as passed in
  full. A session of `codex exec` run by the agent had discovered the
  tool and been stopped at the approval of the call, which a session
  that is not interactive cannot give.
- [x] The server SDK named by its address and a version:
  ail-extensions is a package since 2026-11-22 and has the tag `v0.1.0`
  (user, 2026-11-22); `ail add` with the address wrote the line `dep`
  of `mcp/Ailfile` and `mcp/Ailfile.lock`, with the revision `4493f9d`.
- [x] aildb asks for AIL 0.1.1 (user, 2026-11-22), the first version
  with the libraries of the MCP server, in `Ailfile` and `mcp/Ailfile`;
  the test of `mcp/` is a part of `make test`.
- [x] The index of a repository in one command (user, 2026-11-23: the
  installation of the server asks for an index, and a clone has none):
  `make index REPO=<directory>`, which is `tools/index.sh REPO OUT
  [REVISION]`, the steps of the example for a repository of git at a
  revision, and `docs/mcp.md` with the installation from a clone, the
  index first. `tests/tools_index.aiw`, against the service of
  `tests/lib/embedfake.aiw`, and a run against Ollama on 2026-11-23,
  aildb itself at `39fcca3`, searched through the server (`docs/mcp.md`).
- [x] Every text file in the index of a repository (user, 2026-11-23:
  the chunker took `.aiw` and `.md` and no other file): without `-c`,
  `build/chunk` cuts every file that is well-formed UTF-8 without
  control bytes, by its lines and with the language its path names,
  passes over a file above 1048576 bytes, which `tools/index.sh` does
  not take out of git, and cuts a line above 1500 bytes where a
  character ends; `-c` is the chunker of before, for `make example` and
  `make eval`, whose three lists it cuts into the same bytes
  (`docs/example.md`). `textutf8` of `src/lib/text.aiw` is the check of
  UTF-8 that `textvalid` shares. A run against Ollama on 2026-11-23,
  aildb at `510bf11`, searched through the server (`docs/mcp.md`).
- [x] The text of a PDF file in the index of a repository (user,
  2026-11-23): a file named `.pdf` that starts with `%PDF-` is read by
  the module `pdf` of ail-extensions, which `Ailfile` names as a
  dependency, and each page is cut into chunks that have the number of
  the page as their lines and the language `pdf`. A page that cannot
  be read is passed over, a file that cannot be read or costs too much
  is passed over whole, with what was cut of it, and a PDF file may
  have 33554432 bytes, which `tools/index.sh` knows. Tests in
  `tests/example_chunk.aiw` and `tests/tools_index.aiw`; a run against
  Ollama on 2026-11-23, the manual of bzip2, searched by page through
  the server (`docs/mcp.md`).
- [x] Two findings of a review of the pull request 17 at `50c4fe2`
  (2026-11-23): the chunker reads a file into the room the file has,
  not into that of the longest, so a short PDF file is read under a
  limit of 32 MiB; and the chunks of one PDF file may be 16777216
  bytes of metadata and text, `pdfkept`, above which the file is
  passed over whole. Tests in `tests/example_chunk.aiw`.

## 17. On-demand indexing and text search

The user wants an index that the command `aildb` makes and refreshes
when it is run, with no daemon and no watcher, and an embedding provider
chosen apart from the LLM that asks (2026-11-24). The index of a
directory, its configuration, its manifest and its kept vectors are in
`DIRECTORY/.aildb/` (user, 2026-11-24).

- [x] Before the items: `cmdbegin`, `cmdadd` and `cmdshowv` of
  `tests/lib/cmd.aiw` run a command whose arguments have spaces; the
  chunker is the library `src/lib/chunk.aiw`, of which `build/chunk` is
  the command, with the same output; and `src/lib/sha.aiw` is SHA-256,
  checked against `hashlib` of Python.
- [x] The embedding provider interface: two operations, `documents` for
  a batch of chunks and `query` for one query, in a request of JSON that
  carries the model, its revision, the dimension and the settings, so
  that a provider applies the prefix or the parameters of each
  (`provrequest` of `src/lib/provider.aiw`). The provider of an index is
  configured once, in `.aildb/config` (`src/lib/config.aiw`), and
  `confident` gives the configuration an identity, the SHA-256 of the
  provider, the model, its revision, the dimension and the settings,
  which tells apart embeddings of one dimension. `provparse` validates
  an answer where it enters: the count, the index of each vector, the
  dimension, finite binary32, and no vector of zeros, the last two with
  `normwide`, which `build` uses. Tests `lib_config` and `lib_provider`,
  with answers written in the test for both operations and for each
  malformed answer; the identities and the bits against Python.
  `docs/provider.md`.
- [x] The local command adapter: `provdocs` and `provquerytext` of
  `src/lib/provider.aiw` start the command of the configuration once
  for each request, directly, with the request of version 1 of the
  protocol as its stdin and its answer on stdout, both files in memory;
  32 texts a request and 120000 ms unless the configuration says
  others, after which the process is killed; a status that is not 0, a
  signal and a program that cannot be started are reasons, each with
  the first line of what the provider said. `aildb-llama`
  (`adapters/llama.aiw`) is the runner without a socket: it runs
  `llama-embedding` of llama.cpp on a model file, which is built from
  the sources of llama.cpp since its release archives have no such
  program. `aildb-ollama` (`adapters/ollama.aiw`) wraps the protocol of
  Ollama behind the same interface, with `adapters/lib/ollama.aiw`
  shared with `build/embed`. Tests `provider_command` (a subprocess,
  `build/provider-fake`, and no service of HTTP), `adapter_llama`
  (against `build/llama-fake`) and `adapter_ollama`; both adapters were
  run by hand on 2026-11-24 against llama.cpp `b12676` and Ollama
  0.40.17 (`docs/provider.md`). Indexing and a query through them are
  the tests of the items below.
- [x] `aildb index [DIRECTORY]`: the index of a directory, the current
  one if none is named, made in one run from the files as they are on
  disk, uncommitted edits too, and published as `.aildb/index` by the
  path of `build`, under its lock. The provider is named by options the
  first time and read from `.aildb/config` after that. In a work tree
  git lists the files, so its ignore rules hold; a directory without
  git gives every file. `.aildb` and `.git` are left out at any depth,
  a symbolic link is neither followed nor taken, and the chunker is the
  one of text and PDF files (`src/lib/chunk.aiw`). The revision of git
  is recorded only for a tree that is clean and has the line ends of
  git. `src/index.aiw`, `src/lib/tree.aiw`, `src/lib/run.aiw`; status 7
  for a provider that failed. Tests `cli_index` (new and edited files
  without commits, a removal, an ignored path, a link), `cli_index_plain`
  (a directory outside git) and `lib_tree`; `tools/index.sh` and
  `make index` are unchanged for an index of a revision
  (`tests/tools_index.out` is the same). Two runs against
  nomic-embed-text on 2026-11-24, one with each adapter
  (`docs/index.md`). This run makes the index anew each time; the item
  below makes it incremental.
- [x] Incremental refresh: `.aildb/manifest` has, for each file, its
  size, its times, the SHA-256 of its bytes and its chunks, and a file
  that it has unchanged is neither read nor cut; `.aildb/cache/` has
  the vectors, each under the SHA-256 of the identity of the provider
  and the exact text, so a new or edited file is cut again and asks
  only for the texts that have no vector, a moved file asks for none
  and gets its new path and lines, a removed file has no record, and
  another model or setting, being another identity, uses none of the
  old vectors. A whole snapshot is published by the path of `build`;
  the manifest is written after it and believed only for the snapshot
  it names, so a provider that fails and a run that is killed leave
  the snapshot that was there usable and the next run finds the
  manifest stale. Two runs of a directory: the second ends with status
  5. `src/lib/cache.aiw`, `src/lib/manifest.aiw`. Tests
  `cli_index_refresh` (unchanged input, one edit, a move, the removal
  of the last document, a change of the provider, a provider that
  fails) and `kill_index` (runs killed at four points, and two at
  once), `lib_cache`, `lib_manifest`. `docs/index.md`,
  `docs/durability.md`.
- [x] `aildb search [DIRECTORY] --text QUERY`: the text search of a
  directory. It reads the configuration of the index, makes or
  refreshes the snapshot if the files are not what the manifest has,
  asks the same provider for the vector of the query with the
  operation `query`, and prints the ranked paths with their lines, or
  the page of a PDF file, as `search` does. An index that is up to
  date, which is found from sizes and times alone, costs the one
  request for the query. `search INDEX`, `build` and `check` are as
  they were (`tests/cli_search*.out` changed in the line of the usage
  alone). Test `cli_search_text`: the first search, a second one with
  no request for documents, and a search right after an edit that is
  not committed; two runs against nomic-embed-text on 2026-11-24
  (`docs/index.md`).
- [x] MCP as an optional adapter of the text search: `aildb-mcp -d
  DIRECTORY`, started by the client with the directory in its
  configuration, forwards the query, the limit and the filters of each
  call to `aildb search DIRECTORY --text`, which owns the refresh of
  the index and the embedding of the query; the server knows no model,
  so the LLM that calls can change without the index being made again.
  `-s -i -e` stays for a snapshot. Test `mcp/tests/directory.aiw`: the
  first search and a search after an edit through the server, with the
  results and the failure of a provider those of the command; a run by
  hand against the model on 2026-11-24 (`docs/mcp.md`).
- [x] The workflow of a fresh installation, documented and verified:
  `docs/install.md` goes from the archive to a directory searched in
  words with the local adapter, with the provider set up once
  (`llama-embedding` built from llama.cpp, a model file), where the
  index and the kept vectors are, how the model is changed, and the MCP
  server as an option. The managed workflow is in the installed
  command: `tools/dist.sh` packs `aildb`, `aildb-llama`,
  `aildb-ollama` and `aildb-mcp`, and `tools/dist-check.sh` indexes a
  directory, searches it by text, writes a file and searches again,
  also through `aildb-mcp`, in a container without AIL, git and
  network, with a script as the provider. Both were run on 2026-11-24
  on the archive of `c32fb1b`, whose executables then indexed and
  searched the directory `docs` of a clone with `aildb-llama` and
  llama.cpp `b12676` (`docs/install.md`). Not run: the steps with an
  archive of a release, which no release has yet.
