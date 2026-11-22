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
  share (user, 2026-11-22): the manifest `ail.pkg` and the command `ail`
  of AIL, its pull requests 17 to 25.

## 12. aildb as a package

- [x] The search as a library, `src/lib/search.aiw`: `searchquery`,
  `searchrun`, `searchcount` and `searchhit`, taken out of `query`,
  `scan` and `results` of `src/main.aiw`, which now calls them; the files
  of `src/lib/` name what they need with `use`. `tests/lib_search.aiw`.
- [x] aildb as a package: `ail.pkg` with its executables, built and
  tested by `ail`; `ail.pin`, `tools/ail.sh`, `tests/run.sh` and
  `tests/indent.sh` are gone, the Makefile is the command and the two
  targets it has no word for, and the corpus of the example has its own
  pin.
- [x] A project that imports aildb, `example/consumer`: made with
  `ail new` and `ail add --path`, it searches a snapshot through
  `use "aildb:src/lib/search.aiw"`, and its test shows the bits of the
  scores that the command prints. `docs/library.md`.
