---
title: Starting point
last-verified: 2026-11-21
sources: [conversation 2026-11-21, REQUIREMENTS.md, AGENTS.md and docs/language.md of the AIL repository at 7dea612]
status: current
---
# Starting point

**Summary.** aildb was started on 2026-11-21 with `REQUIREMENTS.md` and no code. This page
separates what that file already decides from what it leaves open, and records what AIL
offers for the work, so that the first design conversation starts from the same facts.

## Decided
- **Written in AIL** (user, 2026-11-21): the file reader, the scoring loop and the top-k
  selection are AIL, which makes the project a use of the language outside its own
  repository and its benchmarks. Embedding generation stays outside the engine.
- **A rebuildable index, not a database of record** (`REQUIREMENTS.md`): the sources are
  authoritative, an index is one file, a rebuild writes a whole new snapshot. This is what
  lets version 1 do without a journal, incremental writes and transactions. If mutable
  authoritative data is needed later, SQLite is evaluated before a format of our own.
- **Exhaustive search first** (`REQUIREMENTS.md`): cosine similarity over every eligible
  record, as a dot product of normalized vectors, serial, with filters applied before
  scoring and ties broken by record ordinal. Approximate indexes and parallel scans are
  decided by the measurement of acceptance check 4, not before.
- **Vectors are stored as little-endian binary32**, contiguous and of one dimension.
- **Publication by atomic rename** of a temporary file in the destination directory,
  flushed and validated first, with the directory flushed after; one builder, readers
  that keep the file they opened.
- **The repository starts without git and without a build** (user, 2026-11-21): knowledge
  base, `AGENTS.md`, `README.md` and `CLAUDE.md` first, the rest after discussion.
- **The rules for commits, pull requests and written text are those of the AIL
  repository** (user, 2026-11-21): English text even when the conversation is in another
  language, `type: subject` commits with a prose body, one backlog item or fix a commit,
  no trailers or attribution lines in commits and pull request descriptions. They are
  written out in `AGENTS.md` here, so that a session in this repository needs no other
  file to follow them. Sources indented with one tab a block and figures only from
  commands that were run come from the same repositories.

## What AIL offers and lacks
Found in the AIL repository at `7dea612`, the revision ail-bench pins on 2026-11-21.
- System calls are a statement, so mapping a file, `fsync`, `rename` and locking need no
  library. `lib/std/file.aiw` reads and writes whole files, `lib/std/proc.aiw` has the
  monotonic clock, `lib/std/heap.aiw` is a heap of 64-bit values in the unsigned order.
- **Floating point is binary64 only.** `fdot` is the loop a scan wants, but over doubles
  8 bytes apart. `docs/language.md` there has no statement that reads or converts a
  binary32, and `load4` gives its bits as an integer. Scoring binary32 data therefore
  needs one of: new statements in the compiler (a conversion, or arithmetic on singles),
  a conversion written with integer statements, or a widened copy made when a file is
  opened. `REQUIREMENTS.md` asks for exactly this to be verified and documented; it is
  the first open item.
- The measurements of dot products in ail-bench are of doubles, so they say nothing yet
  about a scan of binary32.
- The library prints integers (`putn`) and has no output of a double; a similarity score
  in machine-readable results needs a way to be written. ail-bench has `tools/lib/fmt.aiw`
  (`fmtfix`), which is not in the AIL repository.

## Open
The list is in [open items](../status/open-items.md).
