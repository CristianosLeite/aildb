---
title: How a query is measured
last-verified: 2026-11-22
sources: [conversation 2026-11-21, docs/performance.md, bench/run.aiw, bench/hook.aiw, bench/scan.aiw, bench/bench.sh, bench/lance_make.py, bench/lance_query.py, tests/bench_tools.aiw]
status: current
---
# How a query is measured

**Where the programs are.** Since 2026-11-22 they are in the repository aildb-bench
(user, 2026-11-22; [the decision](../architecture/requirements-decisions.md)), and the
paths `bench/...` and `tests/bench_...` of this page are paths there. This page is about
the run of 2026-11-21, made with the programs as they were here at `4a21a3e`.

**Summary.** The harness of acceptance check 4 is `build/bench-run`, an AIL program that
starts a command once a round and reads the clock around it. The parts of a search are
told apart by a hook, `hookmark`, that is empty in the shipped executable and notes the
time in a second one, `build/aildb-times`. `docs/performance.md` defines each time.

## Decisions

- **The times of the parts come from a second executable, not from an option of
  `search`** (agent, 2026-11-21). `src/main.aiw` calls `hookmark 1` to `4`;
  `src/hook.aiw` has it empty and `bench/hook.aiw` reads the clock and, at the last,
  writes the four moments and three lines of `/proc/self/status` to stderr. This is the
  way the stop points of `build` are reached, so the interface of `search` has nothing
  for measuring and the shipped executable no code of it. Rejected: an option `-t`,
  which is an interface to document and keep; and a time for startup taken as the wall
  time of a run that does nothing, which is a difference of two medians.
- **A moment is the monotonic clock in nanoseconds, written by the child and read by
  the harness** (agent, 2026-11-21): `CLOCK_MONOTONIC` is the same in every process, so
  startup is the time from the harness's reading to the child's first, and the end is
  the time from the child's last to the harness's after `wait4`. Any program can write
  the lines, which is how the Python side of the comparison is timed.
- **stderr of the child is a file in memory** (`memfd_create`), and stdin and stdout
  are `/dev/null`: no file of the disk is written in a round.
- **Cold is `fsync`, `fadvise64` with `POSIX_FADV_DONTNEED`, then `mincore` on a
  mapping of the file** (decided with the prototypes, 2026-11-21): no root is needed,
  and the count of pages left is in the report. Only the files of the data are cold;
  executables and libraries stay cached, and the document says so.
- **The 95th percentile is by the nearest rank** (agent, 2026-11-21): a value that was
  measured, with no interpolation between two rounds.
- **The scan read in three ways is a program of its own** (agent, 2026-11-21),
  `bench/scan.aiw`: the engine has one way of reading and gets no second one for a
  measurement. It uses `fdot4` and `src/lib/topk.aiw` and validates nothing.
- **LanceDB gets the vectors of the snapshot, not those given to `build`** (agent,
  2026-11-21): `bench/lance_make.py` reads the normalized binary32 out of the snapshot,
  so "the same stored vector values" holds bit for bit. With cosine as the metric the
  ranking would be the same from the raw vectors, but not the bytes.
- **LanceDB is measured on one processor and on all** (agent, 2026-11-21), since the
  question of parallel scans is one of the things the figures decide.
- **The fetch of the rows is in LanceDB's search time** (agent, 2026-11-21): `to_arrow`
  runs the query and returns its rows, and nothing in the binding ends a search before
  that. The document says so beside the boundary.
- **The Python environment is outside the repository** (agent, 2026-11-21): a virtual
  environment made with `uv` at `~/.cache/aildb-bench/venv` on the user's machine,
  Python 3.12 with lancedb 0.41.0, named to `make bench` as `PY`.

## What the figures decided (agent, 2026-11-21, for the user to review)

`make bench` at `4a21a3e`, i7-12700H, processor 2, ext4 on NVMe; `docs/performance.md`
has every figure. At 100,000 vectors of 768 dimensions: 38 ms warm and 182 ms cold end
to end, 35.6 ms of search warm; LanceDB 0.41.0 in a process a query 0.85 to 0.98
seconds, its search 284 ms on one processor and 217 ms on all.

- **The read-only mapping stays**: a fifth faster than `pread64` warm, within a tenth
  cold. `MAP_POPULATE` was measured and refused: 38 percent slower cold.
- **No approximate index in version 1**: exact search is fast enough at the sizes the
  first use reaches, and an index gives up reproducible results and the plain file.
- **No parallel scan in version 1**: 36 ms to divide warm at 100,000, and cold the
  drive decides. To be measured again near a million vectors.
- The comparison is a process a query, which was the decision of 2026-11-21; a LanceDB
  process that stays was not measured and the document says so.
- Not explained: `bench-scan` with a mapping is a tenth slower at 100,000 than the
  engine reading the same way (41.9 against 38.1 ms).

`tests/bench_stat.aiw` has the median, the percentile and the rounding to milliseconds.
`tests/bench_tools.aiw` has the generator's bytes (the 16 elements it prints were
computed in Python as well), that `aildb-times` prints what `aildb` prints and says its
moments in order, that the scan finds the records and bits of `search` in each way, and
the names of the lines of the harness. No test checks a time, and none checks that
`fadvise64` empties the cache: that is what the count of `mincore` in a report shows.
The Python programs have no test in `make test`, which is to need no LanceDB; `make
bench` stops unless `bench/lance_same.py` finds the same ten records from both engines.
