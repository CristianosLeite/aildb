---
title: The chunker of an index
last-verified: 2026-11-23
sources: [conversation 2026-11-23, example/chunk.aiw, tools/index.sh, tests/example_chunk.aiw, tests/tools_index.aiw, src/lib/text.aiw, docs/example.md, docs/mcp.md]
status: current
---
# The chunker of an index

**Summary.** Since 2026-11-23 `build/chunk` cuts every text file of a repository, not
only `.aiw` and `.md`, for `make index`; with `-c` it is the chunker of before, which
`make example` and `make eval` keep so that their published results stay those of
their corpora. The text of a PDF is the next step: its reader is to be a module of
ail-extensions, and this page gets its decisions when it is here. The decisions of the
first chunker are on [the example page](example.md).

## Decisions
- **Text files and PDF, the reader of PDF in ail-extensions, a page as the line of a
  record** (user, 2026-11-23). The user reported that the chunker takes `.aiw` and `.md`
  and no other file, "such as PDF", and asked for other formats in AIL. Asked, the user
  chose: text files and PDF, in that order; the reader of PDF as a module of
  ail-extensions, as the MCP SDK is, and not files of this repository; the number of
  the page as the first and the last line of a record of a PDF, with the language
  `pdf`, and no change of the format; streams that are not compressed or FlateDecode,
  classic and stream cross references, simple fonts and ToUnicode as what the reader is
  to know. Commits by implementation and one pull request a repository.
- **A mode of the corpora, `-c`, and not a filter of the list** (user, 2026-11-23,
  reviewing the plan). The first plan filtered the list of `make example` and `make
  eval` to `.aiw` and `.md`. The user showed that this is not enough:
  `tests/infix/edge.aiw` of AIL at `a5b4559` is not UTF-8 (byte 416), its chunks are
  records of both corpora, and the new rule of what is text would drop them. So the
  old rules are a mode of the program, and the proof is a comparison byte for byte of
  `META` and `TEXT` on the lists of the pinned corpora, which was made on 2026-11-23
  (`docs/example.md`). Rejected: making the evaluation again with the new chunker,
  which would change every figure of `docs/evaluation.md` for no gain.
- **What is text is a rule of contents, apart from that of a string of a snapshot**
  (user, 2026-11-23, for the split; agent for the bytes). `textvalid` refuses a tab and
  a line feed, which every file has, so it stays for paths and metadata. The check of
  UTF-8 inside it became `textmore`, which `textvalid` and the new `textutf8` share, so
  there is one statement of what well-formed means; the rule of contents, in
  `example/chunk.aiw`, allows a tab, a line feed, a form feed and a carriage return and
  no other byte below 0x20, and no 0x7F. Rejected: a table of extensions as what
  decides (a name says little of the bytes, and `Makefile` has none).
- **The language is the end of the path, from a table, and `text` otherwise** (agent,
  2026-11-23, for the user to review): 34 ends, lower case only. It is what the
  filter `-l` of `search` and `language` of the MCP tool compare.
- **A line of more than 1500 bytes is cut** (user, 2026-11-23: make the limit
  effective, at boundaries of UTF-8, and repeat the place). The first chunker made
  such a line one chunk, which a minified file turns into megabytes sent to the model
  as one text. Without `-c` it holds for `.aiw` and `.md` too (agent). The pieces have
  the same line as first and last, so several records name one place.
- **1048576 bytes at most, and the limit before the bytes are taken** (user,
  2026-11-23, for where it applies; agent for the number, for the user to review).
  `tools/index.sh` reads the size of each blob from `git ls-tree -l` and does not
  write one that is longer, with a line; it reads the number from the constant
  `maxfile` of `example/chunk.aiw`, as `tools/eval.sh` reads the limits of a chunk.
  The chunker, started by hand, reads `maxfile`+1 bytes at most.
- **The script writes every regular file and the chunker decides** (agent,
  2026-11-23). Before, the script knew the two suffixes of the chunker; now nothing
  of what is indexed is said twice. A path of the list that is not there is still the
  status 4.
- **A path that `build` would not take is passed over with a line without `-c`**
  (agent, 2026-11-23), where `-c` ends with the status 3: with every file a
  candidate, one name that is not UTF-8 would otherwise stop the index of a whole
  repository.

## What was seen and is not decided
- The expected outputs of tests (`tests/*.out`) and every other text file of a
  repository are indexed now; a search of this repository for "make target that runs
  the retrieval evaluation" among `text` gave `mcp/tests/search.out` as its second
  result. There is no way to leave paths out of an index.
- A file without units is cut by the limits alone, so a chunk of Python may end in
  the middle of a function. `make eval` has no corpus in another language to measure
  it with.
