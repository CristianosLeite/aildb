---
title: The independent implementation of acceptance check 2
last-verified: 2026-11-21
sources: [tests/lib/oracle.aiw, tests/lib/wide.aiw, tests/oracle_search.aiw, REQUIREMENTS.md, architecture/feasibility.md]
status: current
---
# The independent implementation of acceptance check 2

**Summary.** `tests/lib/oracle.aiw` searches a snapshot without any code of the engine,
and `tests/oracle_search.aiw` requires `aildb search` to print its lines: the same records
in the same order with the same 64 bits of every score. On 2026-11-21 all 60 cases were
the same.

## Decisions
- **What the oracle shares with the engine is the compiler and nothing else** (user,
  2026-11-21: an AIL program apart from the engine, with its own loop). It reads the file
  by the offsets of `docs/format.md` without validating it, widens a binary32 with shifts
  and masks (`tests/lib/wide.aiw`) where the engine uses `f4to8` and `fdot4`, scores with
  a loop of `fmul` and `fadd`, normalizes the query with its own loop, compares a prefix
  with its own loop, and selects by scanning every score for the best one left, as often
  as there are results, where the engine keeps a heap. It writes hexadecimal and JSON
  strings itself.
- **The comparison is of bytes.** The oracle writes the lines of `search` without the
  field `score`, and the test removes that field from what the engine printed. The decimal
  form is therefore not checked here; `tests/lib_fmt.aiw` checks it against Python.
- **Ties come from the data**: every third record has the vector of the record two before
  it, so equal scores are in every result list, and the first query is a stored vector,
  whose two copies are the two best. The oracle keeps the first of equal scores it finds,
  which is the lower ordinal.
- **Two differences are reported apart**, as the design review notes ask: to a sum in the
  opposite order (the documented tolerance, 1e-12, held with a margin of more than three thousand)
  and to a cosine that divides by the norm of the stored vector (about 5e-9 at 96
  dimensions). `docs/format.md` has the table.
- **The test has teeth**: with the comparison of ordinals turned round in
  `src/lib/topk.aiw`, and with a start of 2^-52 in place of 0 in the sum of squares of
  `src/lib/norm.aiw`, it fails (tried by hand on 2026-11-21, then restored).

## Unchecked
- What the compiler does wrong in both programs alike. The statements the two share are
  `fmul`, `fadd`, `fdiv`, `fsqrt`, `flt` and the loads; `tests/lib_norm.aiw` compares the
  bits of a normalization with Python's, which is a check outside the compiler.
- Snapshots that `build` did not make: the oracle trusts the file.
