# TODO

The steps to version 1, in the order in which one unblocks the next.
`REQUIREMENTS.md` says what version 1 is; the decisions behind these steps
are in `.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 0. Decisions before the first code

- [ ] `REQUIREMENTS.md`: the link of acceptance check 4 names the JS
  documentation of LanceDB while the Python binding is used.
- [ ] Stop points of the interruption tests: confirm that a second
  executable, built by the tests from the same sources, is what was meant.
- [ ] Tolerances: the same bits for a sum in the order of the engine, 1e-12
  for another order, about 1e-5 against LanceDB (all proposed).
- [ ] Semantics: path prefix by bytes, language by equality, the empty
  index, a filter that matches nothing, the limits of k, dimension and
  count, one exit status for each class of error.
- [ ] Overlapping builds: `flock` on `<destination>.lock` (proposed).
- [ ] Git: the remote, the published name and the licence. The repository
  was initialized on 2026-11-21, with a `.gitignore`.

## 1. binary32 in AIL (work in the AIL repository)

Steps 2 to 5 do not wait for this one; `build` and `search` do.

- [ ] `f4to8 a as x` and `f8to4 a as x`: rows of `optab`, cases in
  `tests/insn.cases`, tests, `docs/language.md`.
- [ ] `fdot4 a p q n as x`, with the loop `movss` / `cvtss2sd reg,reg` /
  `mulsd` / `addsd`; a test that its bits are those of `f4to8`, `fmul` and
  `fadd` in order.
- [ ] Float literals (user's proposal): not needed for version 1.

## 2. Skeleton

- [ ] `ail.pin`, `tools/ail.sh` and the link `lib -> ail/lib`, as ail-bench
  has them.
- [ ] `Makefile`: the compiler linked from `ail/`, one executable `aildb`
  from `src/aildb.aiw`, compiled into a temporary file and moved.
- [ ] `tests/run.sh` in the manner of AIL (`name.aiw` with `name.out`,
  `name.code` or `name.err`), and the indentation check.
- [ ] `aildb` with no command or an unknown one: usage on stderr and the
  usage status.

## 3. The documented format

- [ ] `docs/format.md`: header (magic, version, flags, dimension, count,
  offsets and sizes of the sections), the model identifier and the source
  revision, records of fixed size, strings, the vectors aligned to 4096;
  the two CRC-32 and what each covers; how normalization is recorded;
  precision and tolerance of a score; limits.
- [ ] `docs/usage.md`: the three commands, their options and statuses; the
  inputs (raw binary32, TSV columns) and the JSON Lines of the results,
  with the order of the fields.

## 4. Libraries (`src/lib/`, each with tests)

- [ ] CRC-32 with eight tables, tested against known values of zlib.
- [ ] A double as decimal and as 16 hexadecimal digits; a JSON string.
- [ ] An unsigned number from text, lines and tab-separated fields, a
  prefix test.
- [ ] Top-k of (score, ordinal) in a bounded workspace, ties by ordinal.
- [ ] binary32 to binary64 with integer statements, kept for the oracle.

## 5. Reading a snapshot, and `check`

- [ ] Open, `fstat`, map read-only; validate lengths, offsets, counts and
  arithmetic before any access; verify the CRC-32 of header and metadata.
- [ ] `check`: also the CRC-32 of the vectors; prints record count,
  dimension and model identifier.
- [ ] Tests on files written by hand: unknown version, each field out of
  range, truncation, one vector byte changed with the length kept.

## 6. `build`

- [ ] Read the vectors, the TSV, the model identifier and the source
  revision when there is one; reject a wrong length, a value that is not
  finite, a zero vector, a path with a tab; normalize in binary64 and round
  with `f8to4`.
- [ ] Write the file as `docs/format.md` says and validate it with the
  reader of step 5.
- [ ] Publication: lock, temporary file in the destination directory,
  `fsync`, validation, `rename`, `fsync` of the directory; write and sync
  failures reported, and the case of a rename that succeeded with a
  directory sync that failed.
- [ ] `docs/durability.md`: the filesystem and storage assumptions for a
  loss of power.

## 7. `search`

- [ ] Read the query (file or stdin), reject a wrong dimension, a value
  that is not finite, a zero vector, a limit that is not positive, a model
  identifier that differs; normalize.
- [ ] Filters before scoring, the scan with `fdot4` over buffers allocated
  once, top-k, JSON Lines with the first line of source revision and model.

## 8. Acceptance checks 2 and 3

- [ ] The oracle: an AIL program apart from the engine, with its own
  reader and loop; the same top-k and the same bits on generated files.
  Empty collection, a filter with no match, equal scores in record order,
  k above the eligible count. The difference to a cosine that divides by
  the norm of the stored vector is reported apart.
- [ ] Malformed inputs of `build` and `search`, each with its diagnostic
  and status.
- [ ] Interruption: the test executable with stop points before and after
  `rename`, and kills at varying moments of the shipped one; the
  destination is absent, or a complete old or new snapshot.
- [ ] A failed rebuild keeps the previous file; an overlapping build is
  rejected; readers that opened before a rebuild finish on the old file.

## 9. The example, and acceptance check 1

- [ ] The chunker in AIL: files of the AIL repository at the pinned
  revision to the TSV and the text of each chunk.
- [ ] The embedding step outside the engine: choose the tool that runs the
  local model of 768 dimensions (nomic-embed-text is the candidate).
- [ ] `make example`: chunk, embed, build, query; a test with queries whose
  expected lines are known, and the same results from a copy of the file.

## 10. Measurement, and acceptance check 4

- [ ] The harness in AIL: rounds, cold cache by `fadvise64` verified with
  `mincore`, wall time, search time apart from startup, peak resident
  memory, file size.
- [ ] The same stored values, query and limit in LanceDB through its
  Python binding; the boundaries of each time written down, how the cold
  cache is verified for the files of each engine, and how mapped pages
  count in the peak resident memory.
- [ ] `docs/performance.md` with the figures at 10,000 and 100,000 vectors
  and the decision on approximate indexes and parallel scans.

## 11. Release

- [ ] `README.md`: how to build, the three commands, the example.
- [ ] `AGENTS.md`: the section "State" rewritten; the knowledge base
  brought up to date.
