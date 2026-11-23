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
their corpora. A PDF file is cut page by page, its text read by the module `pdf` of
ail-extensions. The decisions of the first chunker are on [the example
page](example.md), those of the reader on the page `architecture/pdf-reader.md` of
ail-extensions.

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

- **A PDF file is one by its name and its header, both** (agent, 2026-11-23, for the
  user to review). The user pointed out that with the header alone deciding, the end of
  a path would no longer say whether the numbers of a result are lines or a page, and
  the result of a search has no language. So `.pdf` and `%PDF-` are both asked for, and
  either without the other is passed over with a line.
- **The limitation of a search of all languages is recorded, not solved** (user,
  2026-11-23): the result has a path and two numbers; who reads it tells a page from
  lines by the `.pdf` of the path, or asks with `language` `pdf`. The language in the
  result would change the interface of `search` and of the tool, which is the user's to
  decide.
- **A page that cannot be read is passed over; a document that is spent is taken back
  whole** (user, 2026-11-23, for the rule that a caller which drops a document must
  drop its chunks; agent for which error does which). The module gives a page all or
  nothing. An error of a page (contents not well formed, a filter not known) loses
  that page; an error of the document (spent, no memory) after pages were cut cuts
  `META`, `TEXT` and the count back to where the file began.
- **A PDF file that gives no chunk has a line** (user, 2026-11-23, reviewing: a valid
  file with an empty page gave `1 files, 0 chunks` and nothing on standard error). It
  is passed over with `a PDF file with no text` and not counted.
- **33554432 bytes for a PDF file, 64 units of work a byte and a million, 256 MiB**
  (agent, 2026-11-23, for the user to review). The most work a byte among 394 files
  read on 2026-11-23 was 5.5 (`pdf/README.md` of ail-extensions).
- **16777216 bytes of metadata and text for the chunks of one PDF file, and a file read
  into the room it has** (agent, 2026-11-23, after a review of the pull request 17 at
  `50c4fe2`, for the user to review). The review found that `readmax` asked for the
  33554433 bytes of the longest PDF file before it read one, so that a file of 146 KB
  ended the chunker with the status 4 under a limit of 32 MiB, and that the 256 MiB are
  the memory of the reader alone: the chunks of a file, which stay in the two buffers
  until the last file is cut, were bounded by the work only, about a kilobyte of text
  for each byte of the file. `readmax` now asks for the size that `fstat` gives and a
  byte, and goes on in steps of 65536 for a file that gives more. `emit` adds no chunk
  of a PDF file once its chunks are more than `pdfkept`, and `pdffile` then takes back
  what was cut, as for a spent document. The number is the agent's: a book of a
  thousand pages has a few megabytes of text. Not done: a limit for all files together,
  and the room of the buffer of a page, which is the reader's to bound (its README).
- **The dependency is in the `Ailfile` of the top** (agent; the user: acceptable for
  this pull request). A program that uses aildb as a library then fetches
  ail-extensions too, since dependencies are followed, though only the chunker reads
  it. The other way was a package of its own for the chunker and `embed`.
  `mcp/Ailfile` names the same version, since a build takes one version of a package. The version is 0.1.2
  (`0b06b29`), the first with the module, whose tag `v0.1.2` the agent gave at the
  user's word on 2026-11-23.

## What was seen and is not decided
- The expected outputs of tests (`tests/*.out`) and every other text file of a
  repository are indexed now; a search of this repository for "make target that runs
  the retrieval evaluation" among `text` gave `mcp/tests/search.out` as its second
  result. There is no way to leave paths out of an index.
- A file without units is cut by the limits alone, so a chunk of Python may end in
  the middle of a function. `make eval` has no corpus in another language to measure
  it with.
