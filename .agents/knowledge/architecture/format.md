---
title: The snapshot format, version 1
last-verified: 2026-11-21
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

## Unchecked
- Nothing reads or writes the format yet; the page was written first, as step 3 of
  `docs/TODO.md` has it, and the tests of steps 5 to 8 are what will show it holds.
