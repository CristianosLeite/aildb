---
title: Requirement decisions for version 1
last-verified: 2026-11-21
sources: [conversation 2026-11-21, REQUIREMENTS.md, architecture/feasibility.md]
status: current
---
# Requirement decisions for version 1

**Summary.** What `REQUIREMENTS.md` left to choose and the user chose on 2026-11-21, after
the feasibility study: a read-only mapping, CRC-32, raw binary32 and TSV as inputs, JSON
Lines as output, stop points only in a test executable, AIL pinned as ail-bench does, the
AIL repository and a local model for the example, the Python binding of LanceDB. The
details of each (field order, names of options) are in `docs/format.md` and
`docs/usage.md`, with their reasons on the pages of the format and of the interface.

## Decisions
- **`search` reads the vectors through a read-only mapping** (user, 2026-11-21). The
  prototypes had it a fifth faster than `pread64` with a warm cache at 100,000 vectors and
  the same cold. Its cost is accepted: peak resident memory is the size of the file (pages
  the kernel may take back), which the documents must say beside any figure, and an I/O
  error on a mapped page is a `SIGBUS`, not a return value. Rejected: `pread64` in blocks
  (640 KiB resident, slower warm) and keeping both behind an option.
- **The integrity check is CRC-32**, the one of zlib (user, 2026-11-21): 1.7 GB/s in AIL
  with eight tables, and any tool can verify it. One over the header and metadata, which
  every `search` verifies, and one over the vectors, which `check` verifies; `search` does
  not read the whole payload for it, so a damaged vector is found by `check`, not by a
  query. Rejected: a 64-bit hash of our own (faster, but nothing outside can check it) and
  SHA-256 (identifies content and resists tampering, which is not asked for).
- **Inputs are raw binary** (user, 2026-11-21): the vectors of `build` as contiguous
  little-endian binary32 in one file, the metadata as TSV with a line a record (path,
  start line, end line, language), the query of `search` as raw binary32 from a file or
  stdin. A path with a tab or a line end is rejected. Rejected: JSON Lines with decimal
  numbers (needs a JSON reader and a correctly rounded decimal reader in AIL, and files
  several times larger) and one binary file of our own form for everything.
- **Float literals in AIL are a separate proposal** (user, 2026-11-21): the compiler could
  turn `1.5` into `0x3ff8000000000000` and emit what it emits for the hexadecimal constant.
  That helps the constants of the engine and of its tests; it does not read a decimal
  number from an input file at run time, which would be a library function. It is not
  needed for version 1 and goes to the AIL repository as its own item.
- **Results are JSON Lines** (user, 2026-11-21): an object a line with `rank`, `score` in
  decimal, `score_bits` (the 16 hexadecimal digits of the binary64, so that a test compares
  exactly), `path`, `start_line` and `end_line`, after a first line with the source
  revision and the model identifier. Rejected: TSV, and both behind an option.
- **Stop points for the interruption tests are set by an environment variable and do not
  exist in the shipped executable** (user, 2026-11-21: "this must not exist in the final
  version"). Read here as: the test suite builds a second executable from the same sources
  with a constant that compiles the stop points in, and the released one has none; the
  user confirmed that reading the same day. Kills from outside at varying moments run
  against the released executable as well.
- **AIL is obtained as in ail-bench** (user, 2026-11-21): a file `ail.pin` with the URL and
  the revision, a script `tools/ail.sh` that clones it or links a local checkout, and the
  link `lib -> ail/lib`. Rejected: a git submodule.
- **The example indexes the AIL repository at the pinned revision with an open model of
  768 dimensions that runs locally** (user, 2026-11-21), nomic-embed-text being the
  candidate; no account and no network at query time. Rejected: an embeddings API, and
  indexing aildb itself (small, and its lines move with every commit).
- **The comparison of acceptance check 4 starts the Python binding of LanceDB**
  (user, 2026-11-21), a process a query, from the harness written in AIL. The start of the
  interpreter is part of its end-to-end time and is reported apart from its search time.

## Decided on the proposals (user, 2026-11-21, when the implementation started)
- **Exit statuses, one for each class of error**: 0 success; 2 wrong usage; 3 an invalid
  snapshot or invalid input (a malformed or corrupted file, a wrong dimension, a value that
  is not finite, a zero vector, a model identifier that differs); 4 an I/O failure (open,
  read, write, sync, map, rename); 5 another build in progress for the destination; 6 the
  snapshot was published but its durability is not confirmed, which is the rename that
  succeeded followed by a sync of the directory that failed. 1 is left unused: it is what
  `die` of the AIL library and a shell give for failures that are none of these. Rejected:
  0, 1 and 2 only, with the diagnostic telling the cases apart, which a caller would have
  to parse.
- **Semantics of `search`**: a path prefix is compared byte by byte; a language filter is
  equality with the field the producer gave; an empty index is valid; a filter that matches
  nothing gives no result line and status 0.
- **Tolerances**: the same bits for an implementation that adds in the order of the engine
  (the AIL oracle does), and 1e-12 absolute for one that adds in another order (the bound
  is 8.6e-14). LanceDB computes in binary32, so its scores are compared within about 1e-5
  and its order may differ between near ties.
- **Overlapping builds**: a non-blocking exclusive `flock` on `<destination>.lock`, with
  the temporary file under one fixed name while the lock is held (the fixed name was
  given up after the review of `76104ec`: `architecture/publication.md`). `flock` is not reliable
  on every network filesystem, which belongs with the storage assumptions.
- **Stop points**: the reading above is confirmed. The test suite builds a second
  executable from the same sources with a constant that compiles the stop points in; the
  shipped `build/aildb` has none.
- **The binary32 statements are added to the AIL repository by the agent, on a branch that
  is not pushed**; the user reviews and publishes it, and `ail.pin` moves to the published
  revision afterwards. Done on 2026-11-21: the branch `binary32` was on the remote with
  `a5b4559` as its head, and `ail.pin` names that commit. It was merged into `main` of
  the AIL repository the same day (`e8acf57`) with its commits kept, so the pin stays.

## Licence (user, 2026-11-21)
- aildb is distributed under the Apache License 2.0. The file `LICENSE` is
  its text as the Apache Software Foundation publishes it, unchanged, and
  `README.md` names it. There is no notice at the head of a source and no
  copyright line of aildb: the user named no copyright holder, and the
  licence asks for neither.
- AIL is under the MIT licence. An executable of aildb has the code of the
  AIL library that its sources `use` compiled in, which the MIT licence
  allows under its own condition, that its notice goes with a copy of that
  code. Nothing of AIL is in this repository. The file `NOTICE` (agent,
  2026-11-21) says what an executable has of AIL and holds the MIT licence
  of AIL whole; it goes with an executable, beside `LICENSE`, and section
  4(d) of the Apache licence has whoever passes aildb on keep it.
  `tests/notice_ail.aiw` checks that it has every byte of `ail/LICENSE`.
  Rejected: a file of another name, which the Apache licence would not
  carry along.

## Limits
- The limits of the result count, the dimension and the record count are in
  `docs/format.md`; the [format page](format.md) has the reasons.
