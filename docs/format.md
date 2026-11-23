# The snapshot file

An index is one file, a snapshot: `aildb build` writes it whole, and nothing
changes it afterwards. This page is its format, version 1. A program that
reads a snapshot checks everything under [Validation](#validation) before it
uses a byte of the records, the strings or the vectors.

The format was fixed on 2026-11-21, before the reader and the writer were
written; both follow this page, and the tests build snapshots from it
with no code of the engine.

## Layout

Every number is an unsigned integer, little-endian. An offset counts bytes
from the start of the file unless it is said to count from the start of the
strings. The file has four parts, in this order and with nothing else:

| Part | Starts at | Bytes |
|---|---|---|
| header | 0 | 128 |
| records | 128 | 24 for each record |
| strings | the end of the records | as the header says |
| zeros | the end of the strings | as many as reach the next multiple of 4096, none if it is one |
| vectors | that multiple of 4096 | 4 for each element of each vector |

The vectors start at a multiple of 4096 so that a mapping of the file has
them at the start of a page and every element at a multiple of 4.

## Header

| At | Bytes | Holds |
|---:|---:|---|
| 0 | 8 | the magic: the bytes of `AILDBIDX` |
| 8 | 4 | the format version, 1 |
| 12 | 4 | the flags; bit 0 says that the vectors are normalized, and the other bits are 0 |
| 16 | 8 | the size of the file |
| 24 | 8 | the number of records, which is the number of vectors |
| 32 | 8 | the dimension: the number of elements of each vector |
| 40 | 8 | the offset of the records, 128 |
| 48 | 8 | the offset of the strings |
| 56 | 8 | the size of the strings |
| 64 | 8 | the offset of the vectors |
| 72 | 8 | the size of the vectors |
| 80 | 4 | the model identifier: its offset in the strings |
| 84 | 4 | and its length |
| 88 | 4 | the source revision: its offset in the strings |
| 92 | 4 | and its length; 0 says that there is none, and the offset is then 0 |
| 96 | 4 | the CRC-32 of the vectors |
| 100 | 4 | the CRC-32 of the header and the metadata |
| 104 | 24 | zeros |

Several fields can be computed from others. They are written all the same,
and a reader requires each to have the one value the others allow, so a
snapshot has one form and a damaged number is found by what it contradicts.

The model identifier names the embedding model the vectors came from, as the
caller of `build` gave it; `search` compares it with the one a caller gives.
The source revision is what the caller of `build` said the sources were at,
so that a caller of `search` can tell locations that may be stale.

## Records

Record `i`, counted from 0, is the 24 bytes at `128 + 24*i`, and vector `i`
belongs to it. The number `i` is the ordinal of the record: the order of the
lines of metadata that `build` was given, and the order that decides between
equal scores.

| At | Bytes | Holds |
|---:|---:|---|
| 0 | 4 | the path: its offset in the strings |
| 4 | 4 | and its length |
| 8 | 4 | the language: its offset in the strings |
| 12 | 4 | and its length, which may be 0 |
| 16 | 4 | the first line, counted from 1 |
| 20 | 4 | the last line, not below the first |

The two lines are numbers that a reader gives back as they are: what
they count is the producer's to say. In the snapshots of `make index`
they are lines of a text file and, for a record whose language is `pdf`,
the number of a page ([example.md](example.md#pdf-files)).

## Strings

The strings are bytes without terminators; a record and the header name one
by its offset from the start of the strings and its length. Two names may
share bytes: `build` writes the path or the language of a record once when
the record before it has the same. Bytes that nothing names are allowed.

A string is well-formed UTF-8 (no surrogate, no overlong form, nothing above
U+10FFFF) and has no byte below 0x20 and no byte 0x7F.

A path is relative to the top of the source repository, with `/` between
its parts, as the producer of the metadata wrote it; aildb compares its
bytes and never opens it. It names something in or below that top, read as
text: it does not start with `/`, and when its parts are followed from the
left, an empty part and `.` changing nothing, `..` going one step back and
any other part one step down, no `..` goes above the start. So `a/../b` is
a path and `/tmp/a`, `../a` and `a/../../b` are none. What a link in the
repository points to is not looked at. A path is not brought to one form:
`./a` and `a` are different bytes to the prefix filter.

## Vectors

Vector `i` is the `4*dimension` bytes at the offset of the vectors plus
`4*dimension*i`: its elements in order, each an IEEE 754 binary32,
little-endian.

**Normalization.** `build` accepts any vector whose elements are finite and
not all zero. It makes each element a binary64, which rounds nothing, adds
their squares in the order of the elements from +0, each square rounded and
then added, takes the square root, divides each element by it and rounds the
quotient to the nearest binary32, a tie to the one whose last bit is 0. Those
are the stored elements. Bit 0 of the flags records that this was done, and
version 1 writes and accepts no snapshot without it. A stored vector
therefore has the norm 1 within about 1e-7, not exactly: its elements were
rounded after the division. The norm is not stored and not checked again.

Every stored element is finite: no infinity and nothing that is no number,
which is an element whose eight bits of exponent are all 1. `build` writes
no other, and a file that has one is no valid snapshot.

## Integrity checks

Both checks are the CRC-32 of zlib, PNG and Ethernet: the polynomial
0xEDB88320 with the bits reflected, started from 0xFFFFFFFF and inverted at
the end; the CRC-32 of the nine bytes `123456789` is 0xCBF43926.

- **Header and metadata.** The field at 100 is the CRC-32 of all bytes from
  0 up to the offset of the vectors (the header, the records, the strings
  and the zeros after them), computed with the four bytes of the field
  itself taken as zero. Every command that opens a snapshot verifies it.
- **Vectors.** The field at 96 is the CRC-32 of all bytes of the vectors; of
  no bytes it is 0. It lies in the header, so the first check covers it.
  `check` verifies it. `search` does not, since that would read every vector
  before the first is scored: a vector byte that changed is found by
  `check`, not by a query.

A CRC-32 finds damage; it does not show who wrote a file. A file that
someone made to pass the checks passes them.

## Validation

A reader opens a regular file only; a directory, a device or a named pipe
is a file that cannot be opened, an I/O failure and not an invalid
snapshot. The path is opened without blocking and the kind of the file is
asked of the descriptor, so a named pipe that has no writer is refused at
once and not waited for. It takes the
size of the file from the kernel and rejects the file unless all of the
following hold. They are checked in this order, so that
each number is known to be in range before it is used in a product or a sum,
and none of them can wrap 64 bits within the limits below.

1. The file has at least 128 bytes.
2. The magic is `AILDBIDX` and the version is 1. Another version is
   reported as such, apart from a file that is no snapshot.
3. The flags are exactly 1, and the 24 bytes from 104 are zero.
4. The size in the header is the size of the file.
5. The dimension is from 1 to 65536, the number of records at most
   4294967295 and the size of the strings at most 4294967295.
6. The offset of the records is 128; the offset of the strings is
   `128 + 24*records`; the offset of the vectors is the first multiple of
   4096 that is not below the end of the strings; the size of the vectors
   is `4*dimension*records`; the size of the file is the offset of the
   vectors plus their size.
7. The CRC-32 of the header and the metadata is the one in the header.
8. The model identifier lies within the strings and has from 1 to 255
   bytes; the source revision has at most 255, lies within the strings, and
   has the offset 0 if its length is 0.
9. For every record: the path lies within the strings and has from 1 to
   4095 bytes; the language lies within the strings and has at most 255;
   the first line is at least 1 and the last line not below it.
10. Every string named by the header or a record is as
    [Strings](#strings) says, and every path stays in or below the top of
    the repository as it says.
11. Only `check`: the CRC-32 of the vectors is the one in the header.
12. Only `check`: every element of every vector is finite. `search` does
    not read the vectors of records that a filter leaves out; of those it
    scores it rejects the snapshot, before it prints a result, when a
    score is not finite, which is the case exactly when an element of that
    vector is not.

A snapshot without records is valid: the vectors start at 4096 and have no
bytes.

## Scores

The score of a record for a query is the cosine similarity of the query and
the stored vector, computed as a dot product in binary64:

- The query is `dimension` binary32, finite and not all zero. It is made
  binary64 and divided by its norm as a vector is by `build`, and stays in
  binary64: it is not rounded back to binary32.
- The score is the sum, from +0 and in the order of the elements, of the
  products of each stored element, made a binary64, with the element of the
  normalized query; each product is rounded to binary64 and then added to
  the sum, which is rounded again. Nothing is added in another order, in
  pairs or with a fused multiplication. This is what the statement `fdot4`
  of AIL computes, and its widening of a binary32 (`cvtss2sd`) rounds
  nothing.

So the only roundings of a score are those of the products and the sums in
binary64, and they are determined:

- **An implementation that adds in the same order gets the same bits.** The
  independent implementation of the tests does, and is compared for
  equality of the 64 bits.
- **One that adds in another order** differs by at most about
  `dimension * 2^-53 * Σ|x·y|`, which is 8.6e-14 for 768 dimensions and
  vectors of norm 1. The documented tolerance for such a comparison is
  1e-12, absolute.
- **Against the cosine of the vectors as they were given to `build`** the
  score differs by about 1e-7, the rounding of the stored elements to
  binary32. An implementation that divides the dot product by the norm of
  the stored vector differs from the score by the distance of that norm
  from 1, of the same size; the tests report that difference apart from the
  one of the order of adding.
- **LanceDB computes in binary32.** Its scores are compared within about
  1e-5, and records whose scores are that close may come in another order.

`tests/oracle_search.aiw` measures two of these on generated snapshots; it
printed, on 2026-11-21 with AIL at `a5b4559`, for every record of each
snapshot against one query:

| Snapshot | Largest difference to the sum in the opposite order | Records above 1e-12 | Largest difference to the cosine by the stored norm |
|---|---|---|---|
| 3000 records of 96 dimensions, the query a stored vector | 2.22e-16 | 0 | 5.3e-9 |
| the same, a random query | 2.77e-16 | 0 | 4.2e-9 |
| 200 records of 768 dimensions, a random query | 1.94e-16 | 0 | 5.8e-10 |

The figures are the same on every machine, since the data come from a fixed
seed and every operation is determined.

A score is finite: the elements of a valid snapshot are, the normalized
query has no element above 1, and 65536 products of that size add up to
far less than the largest binary64. A sum that is not finite therefore
shows a damaged vector, and `search` ends with status 3 and prints no
result. A score may lie outside -1 to 1 by the roundings above.

## Limits

| What | Limit |
|---|---|
| dimension | 1 to 65536 |
| records | 0 to 4294967295 |
| all strings together | 4294967295 bytes |
| a path | 1 to 4095 bytes |
| a language | 0 to 255 bytes |
| the model identifier | 1 to 255 bytes |
| the source revision | none, or 1 to 255 bytes |
| a line number | 1 to 4294967295 |
| the result limit of `search` | 1 to 4294967295 |

The largest file these allow is below 2^51 bytes, so no size or offset of a
valid snapshot comes near 64 bits. What a machine can map and what a query
of a given size costs are other limits, which `docs/performance.md` is to
measure.
