---
title: The example
last-verified: 2026-11-21
sources: [conversation 2026-11-21, docs/example.md, example/chunk.aiw, example/embed.py, tests/example_chunk.aiw]
status: current
---
# The example

**Summary.** The example of acceptance check 1 indexes the AIL repository at the
revision of `ail.pin` with nomic-embed-text. Its chunker is an AIL program,
`build/chunk`, that cuts `.aiw` and `.md` files into chunks of whole lines: a function
with the comment above it, or a section of Markdown, 40 lines and 1500 bytes at most,
without overlap.

## Decisions

- **The model is nomic-embed-text** (user, 2026-11-21), 768 dimensions, which was the
  candidate since the requirement decisions.
- **The chunker reads a list of paths and does not walk a directory** (agent,
  2026-11-21). The list is what `git ls-tree -r --name-only` prints for the pinned
  revision, so the files and their order are those of the revision and not of whatever
  lies in a checkout. Rejected: reading the directory in AIL, which needs a sort and
  takes in files that are not of the revision.
- **Two kinds of file, by the end of the path** (agent, 2026-11-21): `.aiw` as `ail`
  and `.md` as `markdown`. The expected outputs of the tests of AIL (`.out`, `.err`),
  the shell scripts and the seed are left out: they are not what a query about the
  language looks for. The tests themselves are in, 1166 of the 1242 files.
- **A chunk is a unit of the file, capped** (agent, 2026-11-21): a function with its
  comment in AIL, a section in Markdown, cut again at 40 lines or 1500 bytes. A result
  then names lines that are worth opening. Rejected: windows of a fixed number of
  lines with overlap, which is simpler but ends a chunk in the middle of a function
  and gives two records for the same lines; and a lower bound that would join a short
  unit to its neighbour, which makes the lines of a result harder to foresee (739 of
  the 3266 chunks of AIL are below 60 bytes, most of them a whole small test).
- **1500 bytes** (agent, 2026-11-21) keep a chunk inside what the model reads at once
  whatever the tool that runs it sets as its context. A line of the documents of AIL
  is a paragraph, up to 16983 bytes in `AGENTS.md`; such a line is a chunk of its own
  and the embedding step may read only its start.
- **The text of a chunk goes out as a string of JSON a line** (agent, 2026-11-21),
  written by `fmtjson` of the engine's library. A program in any language reads it,
  and a person can. The bytes are those of the file, so one file of AIL that is not
  UTF-8 (`tests/infix/edge.aiw`) gives a line that is not; the reader of the text
  decides what to do with it.
- **Ollama runs the model, and a Python program of the standard library asks it**
  (agent, 2026-11-21, after the user named the model; the user started Ollama 0.40.17
  and pulled the model). nomic-embed-text is the name the model has there, one command
  fetches it, and its HTTP interface needs no package. Rejected: llama.cpp, a smaller
  download but a model file to fetch and name by hand; sentence-transformers or
  fastembed, which bring PyTorch or ONNX Runtime as packages and had no build for the
  Python 3.14 of the machine checked; and writing the client in AIL, which would need
  a parser of decimal fractions that rounds correctly and an HTTP client for one use.
- **The task prefixes are part of the example** (agent, 2026-11-21): `search_document: `
  for a chunk and `search_query: ` for a query, as the model card of nomic-embed-text
  asks. Ollama does not add them.
- **The path is not part of the embedded text** (agent, 2026-11-21): a chunk is embedded
  as its lines alone. Putting the path in front is a common aid and was not tried.

## How it was checked

`tests/example_chunk.aiw` has each rule on small files. On AIL at `a5b4559` the
metadata of all 3266 chunks was the same as that of a Python statement of the rules
written for the comparison, and every text was the lines its metadata names
(2026-11-21). The Python program was not kept.
