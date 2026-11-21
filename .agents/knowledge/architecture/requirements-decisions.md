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
details of each (field order, names of options) are still to be written where the format is
documented.

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
  user has not yet confirmed that reading. Kills from outside at varying moments run
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

## Proposed, not yet decided
- Tolerance: the same bits for an implementation that adds in the order of the engine (the
  AIL oracle does), and 1e-12 absolute for one that adds in another order (the bound is
  8.6e-14). LanceDB computes in binary32, so its scores are compared within about 1e-5 and
  its order may differ between near ties.
- A path prefix is compared byte by byte; a language filter is equality with the field the
  producer gave; an empty index is valid; a filter that matches nothing gives no result
  line and status 0; one exit status for each class of error (usage, invalid file, I/O,
  build in progress).
- Overlapping builds: a non-blocking exclusive `flock` on `<destination>.lock`, with the
  temporary file under one fixed name while the lock is held. `flock` is not reliable on
  every network filesystem, which belongs with the storage assumptions.
