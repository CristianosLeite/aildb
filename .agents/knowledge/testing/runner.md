---
title: How the tests run
last-verified: 2026-11-22
sources: [Makefile, Ailfile, docs/cli.md of AIL, tests/run.sh and tests/indent.sh as they were at 03f56e1]
status: current
---
# How the tests run

**Since 2026-11-22** the runner is `ail test` of AIL, which does what `tests/run.sh` did,
and the indentation check is `ail fmt --check`; both scripts are gone, and the directory of
a test is named in `AIL_TMP`, where this page says `AILDB_TMP`. `make test` runs both and
the tests of `example/consumer`: 26 programs, and 1 there. What follows is the convention,
which did not change, and the decisions as they were taken for the scripts
([the package](../architecture/package.md) has the change).

**Summary.** `make test` runs `tests/run.sh` and `tests/indent.sh`. A test is an AIL
program `tests/<name>.aiw` with the output and exit status expected of it; the shell only
compiles it, runs it under a deadline and compares. What a test needs beyond that (starting
`build/aildb`, writing input files, reading results) is written in AIL, as
`REQUIREMENTS.md` asks.

`make test` also builds what some tests start and what is no part of the shipped
executable: `build/aildb-stops` (the stop points), `build/chunk` (the chunker of the
example) and the programs of the measurements (`build/bench-run`, `bench-gen`,
`bench-scan`, `aildb-times`). As of the release of version 1 there are 25 test programs
and the indentation check. `make example` and `make bench` are not tests of `make test`:
the first needs Ollama and the second LanceDB.

## Decisions
- **The runner is the one of AIL and ail-bench** (TODO step 2; written 2026-11-21):
  `name.aiw` with `name.out`, an optional `name.code`, or `name.err` when the compiler must
  refuse the source. It has no `name.aiw.sh` form, which AIL needs for sources a file
  cannot hold; nothing here does.
- **A test is compiled and run from the top of the repository**, so a `use` names
  `lib/std/...` and `src/lib/...` as the engine does, and `build/aildb` is the executable
  under test.
- **Files a test makes go to the directory in `AILDB_TMP`**, one for each test of each
  run, which the runner makes and removes. Rejected: a fixed directory under `build/`,
  which two runs at the same time would share.
- **A deadline of 10 seconds a program**, enforced with `SIGKILL` to the process group, so
  a child that a test started ends with it.
- **The indentation check reads the sources git knows or would add** (`git ls-files
  --cached --others --exclude-standard`), so a new source is checked before its first
  commit; ail-bench lists only the committed ones.

- **A test starts the executable through `tests/lib/cmd.aiw`** (2026-11-21): its `use`
  makes the directory of `AILDB_TMP` the current one, so a test names its files without a
  directory and no path that changes from run to run reaches the expected output; a
  program named without a slash is the one of `build/` in the repository (`aildb check
  x`). `cmdshow` takes a command line, runs it with `/dev/null` as stdin and prints the
  line, its stdout, its stderr and its exit status or signal, which is what the `.out` of
  the test then holds; `cmdrun` gives the two outputs in buffers and takes a descriptor for stdin. An
  argument of `cmdshow` has no space in it and is not empty; a test that needs such an
  argument builds the argument addresses itself and calls `cmdrun`.

- **Snapshots for the tests are written by `tests/lib/mk.aiw`** (2026-11-21), from
  `docs/format.md` and with no code of the engine: its own layout and a CRC-32 of one bit
  at a time. A test of an invalid file makes a valid one in memory, changes bytes, calls
  `mkseal` again when the change is to pass the checksum of header and metadata, and saves
  it, whole or cut. Reason: a reader checked only against the writer it ships with would
  agree with that writer's mistakes. On 2026-11-21 both checksums of a file it wrote were
  also those of `zlib.crc32` of Python 3, computed by hand.

## Unchecked
- The runner itself has no test in the repository. On 2026-11-21 it was tried by hand with
  temporary tests: one that passes, a wrong output, a wrong status, an expected status, an
  expected compiler error, a program that never ends (killed, FAIL), a read of
  `AILDB_TMP`, and a source indented with spaces (reported with its line).
