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
- [x] Overlapping builds: `flock` on `<destination>.lock` (user, 2026-11-21).
- [x] Semantics: path prefix by bytes, language by equality, the empty
  index valid, a filter that matches nothing gives no line and status 0;
  the statuses 0 success, 2 usage, 3 invalid file or input, 4 I/O, 5 build
  in progress, 6 published without confirmed durability (user,
  2026-11-21).
- [x] The limits of k, dimension and count: in `docs/format.md`, chosen by
  the agent when the format was written.

## 1. binary32 in AIL (work in the AIL repository)

- [x] `f4to8 a as x` and `f8to4 a as x`: rows of `optab`, cases in
  `tests/insn.cases`, tests, `docs/language.md`.
- [x] `fdot4 a p q n as x`, with the loop `movss` / `cvtss2sd reg,reg` /
  `mulsd` / `addsd`; a test that its bits are those of `f4to8`, `fmul` and
  `fadd` in order.

Both are commits of the branch `binary32` of the AIL checkout (`d5f236b`
and `a5b4559`, 2026-11-21), not pushed; `make test` passed there.

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
