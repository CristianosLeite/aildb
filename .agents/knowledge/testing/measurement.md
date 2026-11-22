---
title: How a query is measured
last-verified: 2026-11-21
sources: [conversation 2026-11-21, docs/performance.md, bench/run.aiw, bench/hook.aiw, bench/scan.aiw, tests/bench_tools.aiw]
status: current
---
# How a query is measured

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

## What is tested and what is not

`tests/bench_stat.aiw` has the median, the percentile and the rounding to milliseconds.
`tests/bench_tools.aiw` has the generator's bytes (the 16 elements it prints were
computed in Python as well), that `aildb-times` prints what `aildb` prints and says its
moments in order, that the scan finds the records and bits of `search` in each way, and
the names of the lines of the harness. No test checks a time, and none checks that
`fadvise64` empties the cache: that is what the count of `mincore` in a report shows.
