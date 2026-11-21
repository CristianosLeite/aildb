---
title: The command line and the interchange formats
last-verified: 2026-11-21
sources: [docs/usage.md, src/aildb.aiw, architecture/requirements-decisions.md]
status: current
---
# The command line and the interchange formats

**Summary.** `docs/usage.md` is the interface of version 1. The user decided the three
commands, raw binary32 and TSV as inputs, JSON Lines as output with the score in decimal
and as bits, and the exit statuses. What is below was chosen by the agent on 2026-11-21
when the page was written, and is the user's to change until a release.

## Decisions (agent, 2026-11-21, not yet reviewed by the user)
- **Options are one letter and a value**, in any order, each once: `build -o -v -m -d -i
  [-r]`, `search INDEX -k [-q] [-p] [-l] [-i]`, `check INDEX`. Reason: a caller, often a
  model, reads what an argument is from its letter, and the parser is a loop of a few
  lines. Rejected: positional arguments (six of them for `build`, easy to swap) and long
  options (more tokens, more parser).
- **`build` takes the dimension as an option** and requires the size of the vectors to be
  4 times it times the number of lines. Rejected: deriving it from the two sizes, which
  would accept a file cut at a multiple of the line count.
- **The metadata is strict**: four fields, a line feed after every line, numbers without
  sign, no control characters, UTF-8. A file that does not end with a line feed is
  refused, since a cut file looks like that.
- **`check` and `build` print one JSON object**: `records`, `dimension`, `model`,
  `source_revision`. `build` prints it only after the directory was synced; it is the
  report of a durable commit that `REQUIREMENTS.md` asks for.
- **A result line has exactly the six fields the user decided**, without the language or
  the ordinal: every field is tokens for the caller that reads it.
- **`score` has six digits after the point**, correctly rounded from the exact value.
  Reason: the decimal is for reading and `score_bits` for comparing, so the 17 digits
  that would give the bits back are tokens spent twice. Rejected: the shortest decimal
  that gives the bits back (an algorithm of its own, for a value that is already there in
  hexadecimal).
- **A query is exactly `4*dimension` bytes**, from a file or from standard input read to
  its end; more or fewer is invalid input. Only that many bytes and one more are read
  (review of `76104ec`, 2026-11-21): the dimension is known before the query is, and an
  input read to its end made a wrong length cost memory without a bound and, when the
  memory failed, status 4 in the place of 3. The line for an input that is too long says
  "more than" the length, not its size.
- **An empty `-l` takes the records without a language; an empty `-p` takes all.**
