---
title: Feasibility of version 1 in AIL
last-verified: 2026-11-21
sources: [conversation 2026-11-21, REQUIREMENTS.md, AGENTS.md, docs/language.md and compiler/tables.aiw of the AIL repository at 7dea612, prototypes in ~/.cache/aildb-study/proto]
status: current
---
# Feasibility of version 1 in AIL

**Summary.** Version 1 can be written in AIL. Nothing blocks it; the one dependency outside
this repository is three new statements in the AIL compiler for binary32, which the user
chose over a conversion written with integer statements. A scan of 100,000 vectors of 768
dimensions took 41 ms warm and 187 ms cold with the statement simulated. The figures below
come from throwaway prototypes, not from commands of this repository, and are replaced by
the figures of acceptance check 4 when the engine exists.

## Decisions
- **binary32 through new compiler statements** (user, 2026-11-21). A dot product that reads
  binary32, and the two conversions, are added to the AIL repository and aildb pins the
  revision that has them. Rejected: the conversion with integer statements as the scoring
  path (exact, but 3.4 times slower, measured below; it stays as the oracle of the tests),
  and a widened copy made when a file is opened (614 MB of doubles for 100,000 vectors,
  converted again by every process).
- **`build` normalizes** (user, 2026-11-21). The input is any finite, non-zero vector;
  `build` divides by the norm in binary64 and rounds each element to binary32. Rejected:
  requiring normalized input (a burden on whoever makes the embeddings), and storing the
  vectors as given with a binary64 norm apiece (departs from "use normalized vectors").
- **Practically everything in AIL** (user, 2026-11-21), also when the language or the
  compiler needs something new for it: the independent cosine implementation of acceptance
  check 2, the measuring harness and the chunker of the example. Outside AIL stay the
  embedding model and LanceDB, which cannot be AIL.
- **One accumulator, added left to right, for version 1** (follows from `REQUIREMENTS.md`:
  approximate indexes and parallel scans are decided by acceptance check 4). A loop with
  eight partial sums was 1.6 times faster on the whole scan but gives other bits, so it is
  a question for that check.

- **The three statements were written on 2026-11-21** under the proposed names, as the
  commits `d5f236b` (`f4to8`, `f8to4`) and `a5b4559` (`fdot4`) of the branch `binary32` of
  the AIL checkout, which is not pushed: rows of `optab`, with tests against bits computed
  outside the compiler and against the loop of `load4`, `f4to8`, `fmul` and `fadd`.
  `f8to4` rounds to nearest, ties to even, and gives an infinity for a double beyond the
  binary32 range, so `build` must check the rounded value where it matters. The text under
  "What is missing" below is the proposal as it was before they existed.

## What AIL at 7dea612 has
- Any system call by number: `fsync` 74, `flock` 73, `ftruncate` 77, `pread64` 17,
  `fadvise64` 221 and `mincore` 27 as `const`s; `mmap`, `rename`, `openat`, `fstat`, `kill`
  and `getpid` have names. An error is the negated number of the kernel. The prototypes
  used `open`, `fstat`, `mmap` of a file, `pread64`, `fsync`, `fadvise64`, `mincore` and
  `wait4` with a `rusage`.
- `lib/std/proc.aiw` starts and waits for children and reads the monotonic clock, which is
  what the interruption tests and a measuring harness need.
- `alloc` is one `mmap` a call, so the buffers of a scan are allocated once, as the
  requirements ask anyway.

## What is missing, and where it goes
- **Three statements in the compiler** (AIL repository; a row of `optab` in
  `compiler/tables.aiw`, a case in `tests/insn.cases`, tests, documents; `fdot` was two
  lines of compiler in a commit of 18 files). Names are proposals:
  - `fdot4 a p q n as x`: `a` plus the products of the `n` binary32 at `p`, 4 bytes apart,
    each widened, with the `n` doubles at `q`, each product rounded and then added, in
    order. The loop is `movss xmm1,[rdi]` / `cvtss2sd xmm1,xmm1` / `mulsd xmm1,[rsi]` /
    `addsd xmm0,xmm1`. **Not `cvtss2sd xmm1,[rdi]`**: that form keeps the upper half of
    `xmm1`, so each round waits for the product of the one before, and the scan was 3.2
    times slower.
  - `f4to8 a as x`: the binary32 in the low 32 bits of `a` as a double (`cvtss2sd`), for
    the query and for the oracle.
  - `f8to4 a as x`: the double `a` rounded to binary32, in the low 32 bits (`cvtsd2ss`),
    for `build`.
- **In AIL code, here or in the libraries of AIL:** a double written in decimal and as
  16 hexadecimal digits; a heap of k pairs of score and ordinal (`lib/std/heap.aiw` orders
  one unsigned word); CRC-32; reading an unsigned number, a prefix test, lines of a file.

## Measurements
2026-11-21, Intel Core i7-12700H, Linux 7.0.0-44, every process bound to CPU 2
(`taskset -c 2`), AIL at `7dea612`, files on ext4 on a WD Green SN350 NVMe. The sources of
the prototypes are in `~/.cache/aildb-study/proto` on the user's machine, outside any
repository; the statements were simulated by machine code in a `data` line called with
`callp`, which works. Data: `gen FILE N` writes N vectors of 768 random elements,
normalized, as binary32. `scan FILE KERNEL READ` scores every vector against the first and
keeps the 10 best; `run ROUNDS COLD FILE CMD...` starts it ROUNDS times and prints the wall
time of each child and its peak resident memory (`ru_maxrss` of `wait4`). Times are the
median and the 95th percentile in milliseconds; "scan" is read inside the program around
the scan, "wall" from before `fork` until `wait4` returns.

Scoring, mapped file, warm cache, 31 rounds
(`taskset -c 2 ./run 31 0 FILE ./scan FILE K m`):

| Scoring | 10,000 scan | 10,000 wall | 100,000 scan | 100,000 wall |
|---|---|---|---|---|
| `cvtss2sd` from memory (K=1) | 14.742, 15.252 | 15.301, 15.963 | 143.199, 146.804 | 147.778, 151.640 |
| `movss` then `cvtss2sd`, the proposed `fdot4` (K=2) | 4.546, 4.986 | 4.975, 5.468 | 40.918, 43.664 | 44.770, 48.171 |
| eight partial sums, `cvtps2pd` (K=3) | 2.637, 2.908 | 3.044, 3.336 | 24.812, 28.310 | 29.200, 32.532 |
| integer conversion into a buffer, then `fdot` (K=4) | 15.496, 16.100 | 16.005, 16.622 | 153.367, 161.006 | 157.690, 165.670 |
| integer conversion, loop of `fmul` and `fadd` (K=5) | 23.814, 24.604 | 24.363, 25.254 | 238.403, 242.386 | 243.154, 247.247 |

The sum of the bits of all scores was the same for K=1, 2, 4 and 5 on both files, so the
proposed statement gives the bits of the plain loop on converted values. K=3 gives others
(the best score differed by 10 units in the last place).

How the file is read, proposed `fdot4`, in a second run of the same commands (READ `m` a
private read-only mapping, `p` the same with `MAP_POPULATE`, `r` `pread64` of 256 vectors
at a time into one buffer). Warm is 31 rounds; cold is 15 rounds with `run 15 1`, which
before each round calls `fadvise64` with `POSIX_FADV_DONTNEED` on the file and counts the
pages `mincore` still reports (0 every time, without root):

| File, cache | mapping: scan; wall | populated: scan; wall | `pread64`: scan; wall |
|---|---|---|---|
| 10,000 warm | 4.767, 5.255; 5.228, 5.868 | 4.468, 4.705; 4.903, 5.227 | 5.653, 6.071; 5.783, 6.225 |
| 100,000 warm | 41.563, 48.333; 45.562, 52.602 | 46.445, 48.411; 50.091, 53.266 | 57.812, 59.184; 58.022, 59.353 |
| 10,000 cold | 18.480, 18.727; 18.799, 19.276 | 21.357, 22.994; 21.621, 23.263 | 19.674, 20.921; 19.908, 21.170 |
| 100,000 cold | 186.823, 190.292; 187.803, 191.371 | 217.782, 224.003; 218.790, 225.064 | 184.784, 187.678; 185.137, 188.005 |

Peak resident memory was 29,952 KiB and 299,904 KiB with a mapping (the pages of the file,
which the kernel may take back) and 640 KiB with `pread64`. The files are 30,720,000 and
307,200,000 bytes. A mapping is faster warm (by a fifth at 100,000) and the same cold,
where the disk decides.

Conversion (`./conv`): over all 2^32 bit patterns the integer conversion (`f4to8` of
`f4to8.inc`) gave the bits of `cvtss2sd` for every pattern but the 8,388,606 signalling
NaNs, which the instruction makes quiet. `build` rejects values that are not finite, so the
difference cannot reach a file.

Checksums (`taskset -c 2 ./crc FILE` on the file of 100,000 vectors, mapped and populated,
three runs, megabytes of 10^6 bytes a second):

| Checksum | MB/s |
|---|---|
| CRC-32, one table, a byte at a time | 376 to 379 |
| CRC-32, eight tables, 8 bytes at a time | 1728 to 1758 |
| FNV-1a of 64 bits, a byte at a time | 1127 to 1142 |
| a multiplication for each 8 bytes | 5883 to 6049 |

Both CRC loops gave 3672490334, the value of `zlib.crc32` of Python 3 for the file.

## Precision
A binary32 widens to a binary64 without rounding, so the only rounding of a score is that
of the 768 products and sums in binary64. An implementation that adds in the same order
gets the same bits. One that adds in another order differs by at most about
768 × 2^-53 × Σ|x·y| ≤ 8.6e-14 for vectors of norm 1; the documented tolerance for such a
comparison is still to be fixed (open items). The stored vector is the normalized one
rounded to binary32, so its norm is 1 within about 1e-7, and so is the score against the
cosine of the vectors as they were given.

## Not measured
- LanceDB on the same inputs (acceptance check 4).
- The loop inside the compiler: the simulated statement pays a `callp` for each vector.
- Power-loss behaviour; only the system calls were checked to be reachable.
