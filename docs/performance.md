# Performance

How long a query takes and how much memory it needs, how that was
measured, and what was decided from it. This is acceptance check 4.

## How it is measured

The programs are AIL. They were in `bench/` of this repository when the
figures below were made, at the revision `4a21a3e`, and are in a
repository of their own since 2026-11-22, **aildb-bench**, which names
aildb as a dependency and builds them into its `build/`. A run made
there says in its report which revisions of aildb, of aildb-bench and of
AIL made it, and its figures are in the `docs/performance.md` of that
repository; the figures of this page are those of the run of 2026-11-21
and are not changed.

| Program | Is |
|---|---|
| `bench-gen` | the inputs: random vectors, their metadata and a query, the same bytes on every run |
| `bench-run` | the harness: starts a command for a number of rounds and reports times and memory |
| `aildb-times` | the engine, compiled from the same `src/main.aiw` with hooks that note the time at four moments of `search` |
| `bench-scan` | the scan of `search` with the vectors read in three ways |

### A round

`bench-run ROUNDS CPU COLD CMD ARG...` starts the command `ROUNDS` times,
one process after the other, bound to the processor `CPU` (`-` for no
binding), with `/dev/null` as standard input and output. A query is a
process: this is how `aildb` is used, and every time below has the start
and the end of a process in it.

The clock is `CLOCK_MONOTONIC`, which a parent and its child read alike,
so a moment that the child notes can be set against one of the harness.

| Time | From | To |
|---|---|---|
| wall, the end-to-end latency | the harness reads the clock, then makes the child (`fork`, `execve`) | `wait4` has returned in the harness and it reads the clock |
| to entry: process startup | the same start | the first statement of the program runs: the kernel has made the process and mapped the executable, which is static |
| to opened: snapshot opening | entry | the snapshot is mapped and validated as [format.md](format.md#validation) says, which reads the header, the records and the strings and computes their CRC-32; the query is read and normalized |
| to searched: search | opened | every record is scored and the ten best are in order |
| to printed: result materialization | searched | the lines of JSON are made and written to standard output |
| to the end | printed | the harness knows the child is gone: the process ends and the kernel takes its mapping apart |
| cpu | | the processor time of the child, user and system, all threads (`ru_utime` and `ru_stime` of `wait4`) |

"Search time apart from startup" is the line "to searched". The parts are
measured on `aildb-times` and the wall time also on the shipped `aildb`,
whose hooks are empty; the two are the same code but for four readings of
the clock and, after the last, three lines read from `/proc/self/status`.

Of the rounds the harness prints the median and the 95th percentile. The
percentile is by the nearest rank: the smallest value that at least 95 of
100 values are not above, which of 101 rounds is the 96th in order and of
31 the 30th. The median of an even number is the mean of the two in the
middle.

### Warm and cold

**Warm** means that the file cache is as two rounds that are not counted
left it: every page of the snapshot is in memory.

**Cold** means that before each round the harness puts the files of the
engine out of the file cache and checks that they are out. For each file
it calls `fsync`, since a page that is not written cannot be given up,
then `posix_fadvise` with `POSIX_FADV_DONTNEED` for the whole file, then
maps the file and asks `mincore` which of its pages are in memory, and
counts them. The report has the largest count of any round, and a cold
figure is only one if that count is 0. This needs no root. The files are
the snapshot for aildb and every file of the table directory for LanceDB.

Cold is the data, not the machine: the executables, the libraries of
Python and the directory entries stay in memory, so a cold round shows
the cost of reading the data from the device and not that of a first run
after a boot. The drive has its own cache, which nothing here empties.

### Memory

"Peak resident" is `ru_maxrss` as `wait4` reports it for the child, the
most memory the process had resident at one moment. **A mapped page of
the snapshot that the process touched counts in it**, although it is a
page of the file cache that the kernel can take back at once and that
other processes share: `search` touches every page of the vectors, so its
peak is about the size of the file. The lines `RssAnon` and `RssFile`,
which the child reads from `/proc/self/status` after it printed, tell the
two apart: `RssAnon` is memory of the process itself, `RssFile` pages of
files, the mapped snapshot and the executable. What a query costs in
memory that nothing else can use is `RssAnon`.

### The inputs

`bench-gen RECORDS 768 ...` writes vectors whose elements are spread
evenly from -1 to 1, by a generator with a fixed start, and one more as
the query; `aildb build` normalizes them and makes the snapshot. Random
vectors of 768 dimensions are all nearly at a right angle to the query,
which is no matter for an exact search: it does the same work for every
vector, whatever the scores.

### The scan read in three ways

The choice of a read-only mapping was made on prototypes. `bench-scan
SNAPSHOT QUERY HOW` measures it again with the statement `fdot4` of the
compiler and the selection of the engine: `m` maps the file as the engine
does, `p` adds `MAP_POPULATE`, and `r` reads 256 vectors at a time with
`pread64` into one buffer. It validates nothing, so it is not `search`,
and `tests/bench_tools.aiw` checks that it finds the records and the bits
of `search` in each of the three ways.

## The comparison with LanceDB

LanceDB is measured through its Python binding, a process a query, by
the same harness. `bench/lance_make.py` and `bench/lance_query.py` are
the two programs; they need the packages `lancedb`, `pyarrow` and
`numpy`.

**The same stored values.** `lance_make.py SNAPSHOT DIRECTORY` reads the
snapshot that `aildb build` made and writes a table with a row for each
record, in order: the ordinal, the path, the two lines, and the vector as
the snapshot stores it, the normalized binary32 bit for bit, in a column
of fixed-size lists of `float32`. So both engines score the same numbers.
No index is made; the plan of the query is `KNNVectorDistance` over a
read of the whole column, an exact search.

**The same query and limit.** `lance_query.py DIRECTORY QUERY 10` reads
the file of the query that `aildb search -q` reads, and asks for the ten
rows of the least cosine distance with the columns that `aildb` prints.
It prints them as lines of JSON, the score as 1 less the distance.

**The same answer.** Before anything is timed, `bench/lance_same.py`
compares what the two printed: the same records in the same order, and
no score further apart than 1e-5, the tolerance of
[format.md](format.md#scores) for an engine that computes in binary32.

The boundaries of the times, which `lance_query.py` writes as the engine
with hooks does:

| Time | From | To |
|---|---|---|
| wall | as for aildb | as for aildb |
| to entry: process startup | the harness reads the clock | the first line of the program runs: the interpreter of Python has started |
| to imported: startup as well | entry | `lancedb` and `numpy` are imported, which loads the native library of Lance and `pyarrow` |
| to opened: table opening | imported | the database is connected, the table is open and the query is read from its file |
| to searched: search | opened | the search has run and its ten rows are an Arrow table (`to_arrow`) |
| to printed: result materialization | searched | the rows are Python values, formatted and written |
| to the end | printed | the harness knows the child is gone: the interpreter and the threads of Lance end |

The startup of LanceDB is "to entry" and "to imported" together; its
search time apart from startup is "to searched". `to_arrow` both runs the
search and brings back the rows, so the fetch of ten rows of four small
columns is in "to searched" and not in "to printed".

**Cold** for LanceDB is every file of the directory of the table: the
data file, the manifest, the transaction file and the version hint. The
harness finds them itself, puts each out of the cache and counts with
`mincore` as for a snapshot.

**Memory.** Lance reads its data file into memory of its own and does
not map it, so the vectors it reads count in `RssAnon` and no page of the
table in `RssFile`; what is in `RssFile` there is the libraries of Python
and Lance. The two peaks are therefore not the same kind of memory: that
of aildb is pages of the file cache that the kernel can take back, that
of LanceDB is memory of the process.

**One processor and all.** aildb scans on one thread. Lance has a pool
of threads, so it is measured twice: bound to the one processor that
aildb is bound to, and bound to none.

**What this comparison is not.** A process a query is how aildb is
meant to be used and the worst case for a library in an interpreter:
most of the wall time of LanceDB below is the start of Python and the
import, and a program that keeps a table open pays them once. The line
"to searched" is the one to set against the search of aildb, and it too
is the first search of a fresh process, with nothing of Lance's own
caches filled. A search in a process that stays was not measured.

## Running it

In a checkout of aildb-bench:

```
make bench PY=/path/to/python
```

`bench/bench.sh` makes the inputs, the snapshots and the tables at 10,000
and 100,000 records of 768 dimensions below `build/bench/`, compares the
answers and runs the harness for every case; the report is printed and
kept as `build/bench/report.txt`. The run for the figures below took
four minutes.
The environment variables `CPU`, `WARM`, `COLD`, `LWARM`, `LCOLD` and
`SIZES` change the processor, the rounds and the sizes.

## Results

`make bench` printed the figures below on 2026-11-21 (its report has the
date of UTC, 2026-11-22), for aildb at `4a21a3e`:

- **Machine:** Intel Core i7-12700H, 20 processors, 63016 MiB, Linux
  7.0.0-44. The processes were bound to processor 2, a performance core;
  the frequency governor was `powersave` of `intel_pstate` with turbo
  on, and nothing was done to still the machine beyond leaving it alone.
- **Files:** ext4 on a WD Green SN350 1TB NVMe drive.
- **AIL:** the compiler built from `13ffd53`, whose `compiler/` and
  `lib/` are those of the pinned `a5b4559` (`git diff` of the two is
  empty there).
- **LanceDB:** lancedb 0.41.0 with pyarrow 26.0.1 on Python 3.12.13.
- **Rounds:** 101 warm and 31 cold for aildb and `bench-scan`, 31 warm
  and 15 cold for LanceDB. Before every cold round of every case, 0 pages
  of the files were in memory.
- **Commands:** `build/aildb search build/bench/sN.idx -k 10 -q
  build/bench/qN.bin` and `python bench/lance_query.py build/bench/lN
  build/bench/qN.bin 10`, each under `build/bench-run ROUNDS 2 COLD`,
  with `-` for the processor in the columns "every processor".

Times are milliseconds, the median and then the 95th percentile.

### Sizes and answers

| Records | Snapshot | Table of LanceDB | The ten results |
|---:|---:|---:|---|
| 10,000 | 30,965,760 bytes | 30,769,776 bytes in 4 files | the same records in the same order, scores within 5.2e-07 |
| 100,000 | 309,628,928 bytes | 307,708,178 bytes in 4 files | the same records in the same order, scores within 4.9e-07 |

The vectors are 30,720,000 and 307,200,000 bytes; the rest of a snapshot
is its header, records and strings, rounded up to a page.

### 10,000 records

| | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---:|---:|---:|
| wall, warm | 3.966, 4.136 | 625.528, 648.392 | 662.306, 702.821 |
| wall, cold | 17.529, 23.770 | 650.351, 669.598 | 698.736, 728.433 |
| wall of the engine with hooks, warm | 4.040, 4.261 | | |
| startup, warm: to entry | 0.093, 0.133 | 7.712, 8.210 | 11.843, 12.661 |
| startup, warm: to imported | | 519.020, 531.315 | 544.121, 584.544 |
| to opened, warm | 0.198, 0.222 | 1.375, 1.553 | 4.021, 5.271 |
| to searched, warm | 3.623, 3.813 | 28.034, 31.977 | 31.784, 33.485 |
| to printed, warm | 0.012, 0.015 | 0.115, 0.138 | 0.113, 0.121 |
| to the end, warm | 0.110, 0.137 | 68.537, 77.888 | 69.369, 75.622 |
| cpu, warm | 4.010, 4.228 | 624.193, 647.095 | 2584.381, 2595.396 |
| wall of the engine with hooks, cold | 17.588, 17.800 | | |
| startup, cold: to entry | 0.118, 0.145 | 7.801, 9.392 | 10.657, 12.655 |
| startup, cold: to imported | | 520.216, 536.691 | 550.946, 585.429 |
| to opened, cold | 0.488, 0.514 | 12.661, 12.876 | 15.533, 16.881 |
| to searched, cold | 16.831, 17.045 | 39.154, 43.188 | 47.030, 50.378 |
| to printed, cold | 0.014, 0.016 | 0.110, 0.124 | 0.112, 0.124 |
| to the end, cold | 0.130, 0.140 | 67.343, 81.570 | 69.961, 77.504 |
| cpu, cold | 6.362, 6.543 | 632.018, 652.151 | 2591.896, 2612.431 |

| KiB, median and largest | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---:|---:|---:|
| peak resident | 30252, 30252 | 229028, 229136 | 247152, 248180 |
| RssAnon | 52, 56 | 76424, 76456 | 101376, 101544 |
| RssFile | 30284, 30284 | 120428, 120548 | 120280, 120420 |

### 100,000 records

| | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---:|---:|---:|
| wall, warm | 38.158, 39.558 | 879.656, 886.882 | 850.140, 878.769 |
| wall, cold | 182.471, 188.200 | 948.246, 986.144 | 983.460, 1005.232 |
| wall of the engine with hooks, warm | 38.135, 40.421 | | |
| startup, warm: to entry | 0.103, 0.132 | 7.676, 7.851 | 9.722, 12.560 |
| startup, warm: to imported | | 517.080, 521.505 | 544.620, 575.870 |
| to opened, warm | 1.732, 1.806 | 1.357, 1.417 | 3.896, 5.321 |
| to searched, warm | 35.606, 37.693 | 283.965, 289.159 | 216.586, 223.556 |
| to printed, warm | 0.012, 0.015 | 0.112, 0.118 | 0.112, 0.118 |
| to the end, warm | 0.681, 0.830 | 68.357, 75.632 | 73.737, 84.436 |
| cpu, warm | 38.100, 40.377 | 878.089, 885.601 | 3276.185, 3312.279 |
| wall of the engine with hooks, cold | 182.152, 185.758 | | |
| startup, cold: to entry | 0.143, 0.176 | 7.879, 9.090 | 9.058, 12.715 |
| startup, cold: to imported | | 519.875, 526.921 | 550.547, 564.780 |
| to opened, cold | 2.453, 2.546 | 12.641, 12.927 | 15.186, 16.679 |
| to searched, cold | 178.791, 182.297 | 339.999, 379.739 | 332.201, 358.520 |
| to printed, cold | 0.017, 0.021 | 0.109, 0.114 | 0.113, 0.170 |
| to the end, cold | 0.807, 0.965 | 66.606, 78.845 | 73.939, 96.902 |
| cpu, cold | 64.850, 67.327 | 921.665, 959.608 | 3299.634, 3454.172 |

| KiB, median and largest | aildb | LanceDB, one processor | LanceDB, every processor |
|---|---:|---:|---:|
| peak resident | 302380, 302380 | 638428, 638548 | 662792, 678004 |
| RssAnon | 52, 56 | 76688, 76856 | 247268, 262524 |
| RssFile | 302416, 302416 | 120436, 120552 | 120296, 120388 |

### What the figures say

- **End to end, aildb answers in 4 ms at 10,000 records and 38 ms at
  100,000 with the file in memory, and in 17.5 ms and 182 ms when it has
  to be read from the drive.** Startup is 0.1 ms, since the executable is
  static and small; nearly all of the time is the scan.
- **The search itself is about a third of a microsecond for a vector
  warm** (35.6 ms for 100,000), on one thread, and ten times the records
  took 9.8 times as long.
- **Cold, the drive decides.** At 100,000 records the processor time is
  65 ms of 182 ms: the process waits for 310 MB to arrive, which is 1.7
  GB a second.
- **LanceDB as a process a query takes 0.63 to 0.98 seconds**, of which
  the start of Python and the import are 0.53 to 0.56 and the end of the
  process 0.07. That part is the price of the form of the comparison, not of the
  engine.
- **Search against search, aildb is about 8 times faster warm on one
  processor** at both sizes (3.6 against 28 ms, 35.6 against 284 ms), and
  6 times faster than LanceDB with every processor at 100,000 (217 ms).
  Cold the distance is smaller, 1.9 times at 100,000, since both wait for
  the same bytes. Why the search of LanceDB takes the time it does was
  not looked into; it is the first search of a new process, and it reads
  the column into memory of its own.
- **Memory.** aildb has 52 KiB of its own at any size; its peak is the
  pages of the mapped file, 295 MiB at 100,000, which are the file cache.
  LanceDB at 100,000 has 75 to 240 MiB of its own and a peak of 620 to
  650 MiB, twice its table.
- **The files are the same size** within one percent.

### The mapping, measured again

`bench-scan` at 10,000 and then at 100,000 records:

| | mapped (`m`) | mapped and populated (`p`) | `pread64` (`r`) |
|---|---:|---:|---:|
| wall, warm | 3.838, 4.026 | 3.949, 4.092 | 4.999, 5.211 |
| to opened, warm | 0.016, 0.017 | 0.348, 0.391 | 0.012, 0.013 |
| to searched, warm | 3.618, 3.785 | 3.383, 3.533 | 4.848, 5.031 |
| cpu, warm | 3.809, 3.996 | 3.918, 4.066 | 4.974, 5.182 |
| wall, cold | 18.053, 20.839 | 20.849, 26.395 | 19.429, 19.857 |
| to opened, cold | 0.176, 0.196 | 17.138, 22.800 | 0.105, 0.119 |
| to searched, cold | 17.586, 20.410 | 3.420, 3.477 | 19.164, 19.560 |
| cpu, cold | 6.386, 6.938 | 6.313, 6.653 | 8.053, 8.816 |
| peak resident, KiB | 30096 | 30256 | 800 |
| RssAnon, KiB | 36 | 36 | 808 |

| | mapped (`m`) | mapped and populated (`p`) | `pread64` (`r`) |
|---|---:|---:|---:|
| wall, warm | 41.892, 43.819 | 37.764, 39.421 | 52.722, 54.298 |
| to opened, warm | 0.018, 0.022 | 3.242, 3.466 | 0.013, 0.016 |
| to searched, warm | 40.913, 42.675 | 33.688, 34.975 | 52.545, 54.049 |
| cpu, warm | 41.781, 43.761 | 37.718, 39.386 | 52.689, 54.251 |
| wall, cold | 180.901, 183.468 | 248.951, 262.022 | 192.995, 199.367 |
| to opened, cold | 0.178, 0.184 | 214.364, 227.432 | 0.117, 0.139 |
| to searched, cold | 179.791, 182.141 | 33.631, 34.727 | 192.629, 199.021 |
| cpu, cold | 63.178, 65.319 | 62.159, 63.644 | 79.529, 89.532 |
| peak resident, KiB | 300148 | 302352 | 800 |
| RssAnon, KiB | 36 | 36 | 808 |

- **A mapping is faster than `pread64` warm by a fifth** (41.9 against
  52.7 ms at 100,000, 3.8 against 5.0 at 10,000): the read copies every
  byte once more. Cold the two are within a tenth of each other, the
  mapping ahead (181 against 193 ms at 100,000). This is what the prototypes
  showed.
- **`pread64` needs 800 KiB of memory and the mapping the whole file**,
  as pages the kernel can take back.
- **`MAP_POPULATE` is not worth it.** Warm it scans faster (33.7 against
  40.9 ms) but pays 3.2 ms in `mmap`, for 37.8 against 41.9 ms in all;
  cold it is 38 percent slower (249 against 181 ms), since the file is
  read to its end before the first vector is scored.
- The mapped scan of `bench-scan` took 41.9 ms where the engine, which
  reads the same way, took 38.1 for all of a search. The two programs
  have the same loop at different addresses; the difference was not
  explained.

## Decisions

Taken from these figures by the agent on 2026-11-21, for the user to
review:

- **The read-only mapping stays.** It is the fastest of the three ways
  warm but for a populated mapping, which loses much more cold, and no
  slower than reading cold. Its costs are as they were accepted: a peak
  resident memory of the size of the file, made of pages that can be
  taken back, and `SIGBUS` for an I/O error on a mapped page.
- **No approximate index in version 1.** An exact search of 100,000
  vectors of 768 dimensions takes 38 ms warm; the example repository has
  3,266 chunks. An approximate index buys time at a size that the first
  use does not reach, and costs what version 1 is built on: results that
  an independent implementation reproduces bit for bit, and a file that
  is its vectors and nothing to keep in step with them. It would help
  most where exact search is slowest, cold, by reading less of the file.
- **No parallel scan in version 1.** Warm, the scan is processor time
  and would divide among threads; at 100,000 records there are 36 ms to
  divide. Cold, two thirds of the time is waiting for the drive, which
  threads do not shorten. A scan on several threads also has to merge
  its selections in a way that keeps the order of equal scores.
- **When to look again.** If the time keeps growing with the records as
  it did between the two sizes, a million vectors would be about 0.4
  seconds warm and 1.8 seconds cold in a file of 3.1 GB. That was not
  measured. A collection of that size is where a parallel scan, and then
  an approximate index, should be measured before it is refused again.

## What was not measured

- Sizes above 100,000 records, other dimensions, a limit other than 10,
  and searches with a filter, which score fewer records.
- LanceDB in a process that stays, with a table already open, and LanceDB
  with an index.
- A cold start of the machine: executables and libraries were in memory.
- Other drives and filesystems, and a machine under load.
