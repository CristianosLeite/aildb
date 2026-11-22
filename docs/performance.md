# Performance

How long a query takes and how much memory it needs, how that was
measured, and what was decided from it. This is acceptance check 4.

## How it is measured

The programs are in `bench/` and are AIL, built by `make test` into
`build/`:

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
