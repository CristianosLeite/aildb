---
title: The snapshot format, version 1
last-verified: 2026-11-22
sources: [docs/format.md, REQUIREMENTS.md, architecture/requirements-decisions.md, architecture/feasibility.md]
status: current
---
# The snapshot format, version 1

**Summary.** `docs/format.md` is the format; this page has the choices behind it. The user
decided what the file stores, the two CRC-32, the normalization and the tolerances. The
layout in detail and the limits were chosen by the agent on 2026-11-21 when the page was
written, before any reader existed, and are the user's to change until a release.

## Decisions (agent, 2026-11-21, not yet reviewed by the user)
- **A header of 128 bytes with every offset and size written out**, although most can be
  computed from the count, the dimension and the size of the strings. A reader requires
  each to have the one value the others allow. Reason: `REQUIREMENTS.md` asks that offsets
  be documented and that lengths, offsets, counts and arithmetic be validated; a redundant
  field that must agree finds a damaged number before the checksum is even computed, and a
  later version can move a part without a new header. Rejected: a header of count,
  dimension and string size only (nothing to cross-check, the size of the file aside).
- **One canonical form**: the parts in one order, the vectors at the first multiple of
  4096 after the strings, zeros between, reserved bytes zero, flags exactly 1. Reason: a
  reader has no choices to follow, so nothing in a file can steer it. Rejected: free
  offsets with only bounds checks.
- **Records of 24 bytes, strings by offset and length of 32 bits** in one section, with
  sharing allowed. Paths repeat for the chunks of a file, so `build` shares a string with
  the record before; 32 bits bound the strings at 4 GiB. Rejected: strings inline in
  records of variable size (no access by ordinal), and NUL-terminated strings (a scan to
  find a length, and a missing terminator to guard against).
- **The CRC-32 of the header and metadata covers everything before the vectors, its own
  field taken as zero**, and the CRC-32 of the vectors lies inside that range, so the two
  form a chain: the metadata check vouches for the value the vector check is compared
  with.
- **Strings are well-formed UTF-8 without control bytes, checked by the reader.** Reason:
  a path goes into a JSON line, which must be valid for whoever parses it; with the rule
  in the reader, `build` validating its temporary file is also the check of its input.
  The cost is a pass over the strings in every `search`, to be measured in acceptance
  check 4. Rejected: checking only in `build` (a file of another writer could make
  `search` print invalid JSON), and replacing bad bytes in the output (a path the caller
  cannot open).
- **The query stays in binary64 after normalization**; only stored vectors are rounded to
  binary32. This is the definition of the score in the design review notes of
  `REQUIREMENTS.md`.
- **Limits**: dimension 1 to 65536, records up to 2^32-1, a path 1 to 4095 bytes (the
  limit of a path for the AIL file library), a language up to 255, model identifier 1 to
  255, source revision up to 255, lines and the result limit 1 to 2^32-1. With them no
  product or sum of the validation can wrap 64 bits.
- **An empty language is allowed** (a file whose language the producer does not know); an
  empty path is not.

- **A stored element that is not finite makes a snapshot invalid** (review of `76104ec`,
  2026-11-21). The review showed `search` printing `"score":,` for a vector with an
  infinity, since the checksum of the vectors is not read by `search` and the decimal
  formatter writes nothing for such a value; the heap of the best records also assumes
  scores that compare. `search` now rejects the snapshot before a result is printed when
  a score is not finite, which costs one test for each scored record and keeps the single
  scan. A finite query and finite elements cannot give such a score (65536 products of at
  most 3.4e38 are far below the largest binary64), so the test is exactly "an element of
  this vector is not finite". `check` looks at every element after the checksum, as step
  12 of the validation, so that a snapshot `check` accepts is never rejected by `search`:
  a file someone wrote with right checksums and an infinity would otherwise pass one and
  fail the other. Not done: a test of the norm, or of zero vectors, which only give
  scores that mean little.

- **A path is relative and stays below the top of the repository, as text** (review of
  `76104ec`, 2026-11-21). `build` accepted `/tmp/source.aiw` and `../source.aiw`, and
  `search` gave them back as locations an agent opens. `textinside` is the one check,
  used by the metadata parser and by the reader, so a snapshot from elsewhere is held to
  it too: no leading `/`, and no `..` that goes above the start when the parts are
  followed from the left. Chosen over refusing every `.`, `..` and empty part, which
  would also refuse `./a` from a producer that writes it; the cost is that a path has no
  single form, and `-p` compares bytes. Symbolic links are not looked at: aildb never
  opens a path.

## Learned
- **The size of the strings is the one number of the layout that nothing else fixes**
  (2026-11-21, from the tests of invalid files): a header that says 54 bytes where 53 are
  named is a valid snapshot, since the byte is a zero that belongs to the strings now and
  the vectors still start at the same multiple of 4096. The format allows bytes that
  nothing names, so this is no fault; "one form" holds for the layout, not for the
  contents of the strings.
- **A snapshot is opened without blocking** (`O_NONBLOCK`; item 14 of `docs/TODO.md`, a
  review the user added on 2026-11-22; fixed by the agent the same day): the reader asked
  for the kind of the file after the open, and the open of a named pipe that has no writer
  waits, so `check` and `search` hung before the check of a regular file. The flag changes
  nothing for a regular file, and the mapping does not use it. `mapfile` of `build -v` had
  the same order and has the same fix. Rejected: `stat` of the path before the open, which
  asks about a name that may be another file by the time it is opened. Left as it is: `-m`
  and `-q`, which are read and not mapped and may be a pipe; a pipe that never gets a
  writer is waited for there, as any reader of one waits (`build` holds its lock then).
  `tests/cli_fifo.aiw`.

## Unchecked
- Nothing of the engine writes the format yet. The reader is checked against files that
  `tests/lib/mk.aiw` writes from the page (`tests/snap_open.aiw`,
  `tests/cli_check.aiw`, `tests/cli_check_invalid.aiw`); `search` on a damaged file is a
  test of step 8.
