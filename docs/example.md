# The example

The example indexes a real repository, the one of AIL at the revision of
`example/corpus.pin`, and queries the index end to end: `make example`, which is
acceptance check 1. This page describes its steps and what it showed.
The engine takes no part in making an embedding: it reads vectors that
another program wrote.

## Chunks

A chunk is what one record of the index stands for: some whole lines of
one file. `build/chunk`, an AIL program compiled from `example/chunk.aiw`
by `make test`, cuts the files:

```
build/chunk [-c] ROOT META TEXT < LIST
```

`LIST` is paths relative to the directory `ROOT`, one a line, as `git
ls-tree -r --name-only` prints them. `META` gets a line for each chunk,
in the form `build` takes as metadata: the path as the list has it, the
first line, the last line and the language. `TEXT` gets a line for each
chunk in the same order, the bytes of its lines as a string of JSON, for
the program that makes the embeddings. A line feed is between the lines
of a chunk and none is at its end. The bytes are those of the file: a
carriage return stays.

It has two ways of taking the files. Without `-c` it is the chunker of
an index of any repository, which `make index` runs
([mcp.md](mcp.md)); with `-c` it is the chunker of the corpora of this
example and of [the evaluation](evaluation.md), which `make example` and
`make eval` run.

### Every text file

Without `-c`, every file of the list that is text is cut:

- **What is text.** The bytes of the file are well-formed UTF-8, with no
  byte below 0x20 but a tab, a line feed, a form feed and a carriage
  return, and no byte 0x7F. It is a rule of its own, for contents: a
  string of a snapshot ([format.md](format.md)) has none of those four
  either. A file that is not text is passed over; standard error has
  `chunk: passed over, a file that is not text: <path>` if the end of
  its path is one of the table below, and nothing if it is not, as for
  an image.
- **The language** is named by the end of the path, what follows the
  last dot of its last part when that dot is not the first byte of the
  part: `aiw` is `ail`, `md` is `markdown`, and a table at the top of
  `example/chunk.aiw` has the others (`c`, `cpp`, `python`, `rust`,
  `go`, `java`, `javascript`, `typescript`, `csharp`, `kotlin`, `swift`,
  `ruby`, `php`, `lua`, `shell`, `sql`, `json`, `yaml`, `toml`, `xml`,
  `html`, `css`, and `text` for `txt`). A path with another end or with
  none, as `Makefile`, is `text`. The ends are compared byte for byte,
  so `A.PY` is `text`.
- **The most bytes of a file** are 1048576, the constant `maxfile`. The
  chunker reads one byte more than that at most, and a file that has it
  is passed over with `chunk: passed over, a file of more than 1048576
  bytes: <path>`.
- **A path** that `build` would not take (a byte below 0x20, a byte
  0x7F, what is not UTF-8) or that is absolute or leads out of `ROOT` is
  passed over with a line and is not opened.
- **A line of more than 1500 bytes** is cut into chunks of 1500 bytes at
  most, each of which ends where a character ends, and each has that
  one line as its first and its last: several records then name the
  same place.

The status is 0, with the number of files cut and of chunks on standard
output; 2 for wrong usage; 4 for a file of the list that cannot be read,
or one that cannot be written. Nothing is written after a failure.

### The corpora, `-c`

With `-c` only a path that ends in `.aiw` or `.md` is taken, whatever
bytes the file holds and however long it and its lines are: a line
above 1500 bytes is a chunk of its own, and a file that is not UTF-8
gives a string that is not. Every other path is passed over without a
line, and a path that `build` would not take is the status 3. This is
what the chunker did when the results of this page and of
[evaluation.md](evaluation.md) were written, and the option keeps
them: one of the files of AIL at `a5b4559`, `tests/infix/edge.aiw`, is
not UTF-8, and its chunks are records of both corpora. On 2026-11-23 the
chunker of before the option and this one with `-c` wrote the same bytes
of `META` and of `TEXT` for the three lists that `make example` and
`make eval` had made (AIL at `a5b4559` twice, 1242 files and 3266
chunks, and aildb at `467b91b`, 78 files and 554 chunks), compared with
`cmp`.

### How a file is cut

- The lines of a file are taken in order and each belongs to one chunk at
  most; chunks do not overlap.
- A blank line, one with nothing but spaces, tabs and a carriage return,
  never starts or ends a chunk. Blank lines between two lines of a chunk
  belong to it, the others to none, so a file of blank lines has no chunk.
- A chunk ends before a line that starts a unit:
  - in AIL, a line that starts with `fn `, or the first of a run of lines
    that start with `#` when the line after the run starts with `fn `, so
    that the comment above a function is in the chunk of the function;
  - in Markdown, a heading, one to six `#` and a space at the start of a
    line, unless the line is inside a fence, between two lines that start
    with three backquotes;
  - in every other language nothing: such a file is cut by the limits
    alone.
- A chunk also ends before a line that would make it longer than 40 lines,
  counted from its first line, or longer than 1500 bytes.

What comes before the first function of a source, or the first heading of
a document, is a chunk as well, and statements after the last function
belong to the chunk of that function until a limit ends it.

The limits are for the embedding model: 1500 bytes are well inside the
text that the model reads at once, and a chunk that is one function or one
section says where to open the file. They are constants at the top of
`example/chunk.aiw`.

`tests/example_chunk.aiw` shows each rule on small files, with `-c` and
without. On the AIL repository at `a5b4559`, `build/chunk` printed on
2026-11-21, and `build/chunk -c` on 2026-11-23:

```
1242 files, 3266 chunks
```

The result is the same on every machine, since nothing but the files
decides it. The lines of metadata of that run were the same as those of
a second statement of the rules above, written in Python for the
comparison and not kept.

## Embeddings

The model is nomic-embed-text, an open model of 768 dimensions, and
[Ollama](https://ollama.com) runs it on the machine of whoever runs the
example: no account, and no network once the model is there.

```
ollama serve
ollama pull nomic-embed-text
```

`build/embed`, from `example/embed.aiw`, asks it for the vectors. It is an
AIL program, as everything else of the example: the HTTP client, the JSON
and the numbers are the libraries of AIL (`ail build embed` makes it, and
`make example` does):

```
build/embed document TEXT VECTORS
build/embed query QUERIES VECTORS
build/embed model
```

`TEXT` is the file of that name of `build/chunk`; `QUERIES` has a query
on each line, up to the first tab, and an empty line is passed over.
`embed model` prints the version of Ollama and the digest of the model. `VECTORS` gets one vector for each
line, in order, 768 binary32, little-endian: the file `aildb build -v`
reads, and for one query the bytes `aildb search -q` reads. The file is
written whole or not at all.

- The model is trained with a word in front of each text that says what
  it is for. A chunk is sent as `search_document: ` and its text, a query
  as `search_query: ` and its text. A query embedded without the word, or
  with the other one, is compared with vectors it was not made for.
- A byte sequence that is not UTF-8 is sent as U+FFFD, one for each run of
  bytes that starts a character and is not the whole of one.
- A number of the model is read as the nearest double and rounded to the
  nearest binary32, which is what a program in another language stores.
- The texts go to `/api/embed` of Ollama sixteen at a time, at the address
  of the environment variable `OLLAMA_HOST` or `http://127.0.0.1:11434`:
  an IPv4 address or `localhost`, since the client knows no names.
- Ollama reads a text up to the context it runs the model with and drops
  the rest. A chunk of at most 1500 bytes was taken to be inside it; a
  line that is longer is a chunk that may be embedded by its start only.
  The request says so (`truncate`), and no count of dropped tokens comes
  back for a single text of a batch, so the example does not report one.
- The vectors are stored as Ollama gives them; `build` normalizes.

The status is 0 with the number of vectors on standard output, 2 for
wrong usage and 1, with a line on standard error, when Ollama does not
answer, a file cannot be read or written or an answer is not 768 finite
numbers for each text.

## Running it

With Ollama running and the model pulled:

```
make example
```

It works in `build/example/` and does this, each step a command that it
prints:

1. `git clone` fetches the repository that `example/corpus.pin` names
   into `repo/`, `git archive` puts its files at the revision of that
   file into `src/`, and `git ls-tree` lists them.
2. `build/chunk` writes `meta.tsv` and `text.jsonl`.
3. `build/embed` writes `vectors.bin` for the chunks and
   `queries.bin` for the queries of `example/queries.tsv`.
4. `aildb build` makes `ail.idx`, with `nomic-embed-text` as the model
   identifier and the revision of AIL as the source revision, and `aildb
   check` validates it.
5. `cp` copies it to `copy/moved.idx`, another name in another directory.
6. `build/example-check`, from `example/check.aiw`, runs `aildb search
   -k 5` for each query on the snapshot and on the copy.

A line of `example/queries.tsv` is a query, a path and a line number of
that path, with tabs between: the line of AIL at which the answer to the
query is, chosen by reading the file. A query is good when one of its five
results is the record of that path whose lines have that line, and the
search on the copy wrote the same bytes, scores included. `make example`
fails unless every query is good.

The same steps for another repository, without the queries, are `make
index REPO=<its directory>` ([mcp.md](mcp.md#in-claude-code-and-in-codex)).

To ask something else, embed it and search:

```
printf 'how do I start a child process\n' > q.txt
build/embed query q.txt q.bin
build/aildb search build/example/ail.idx -k 5 -q q.bin
```

## What it showed

`make example` printed this on 2026-11-21, for AIL at `a5b4559`, with
Ollama 0.40.17 running nomic-embed-text (F16, digest `0a109f422b47`, a
context of 2048 tokens) on an NVIDIA RTX 3050 Laptop GPU, on a Core
i7-12700H with Linux 7.0:

```
ok   place 1  lib/std/io.aiw:58  print an unsigned number in decimal
ok   place 2  lib/std/proc.aiw:208  wait for a child process to end and kill it after a time limit
ok   place 3  lib/std/proc.aiw:274  run a thread on one CPU only
ok   place 1  lib/std/heap.aiw:19  add a value to the heap
ok   place 1  lib/std/queue.aiw:57  take the oldest value out of the queue
ok   place 3  README.md:17  what do I need to install to build the compiler
6 of 6 queries have the expected lines in the first 5 results, 3 as the first; the copy answered 6 with the same bytes
```

The snapshot has 3266 records and 10147840 bytes. The run took 32
seconds, the model already loaded.

**The queries were ten.** All ten were written, with their paths and
lines, before the model had embedded anything. The first run had the
expected lines among the five results for the six above; for the other
four the expected record came later, and they were taken out of
`example/queries.tsv` so that the check is one that passes. They are
listed here because six of six would otherwise say more than it does:

| Query | Expected | Place of the expected record | First result |
|---|---|---:|---|
| read a whole file into a buffer | `lib/std/file.aiw:72` | 12 | `AGENTS.md:142` |
| list the names in a directory | `lib/std/file.aiw:140` | 8 | `tests/lib_file_names.aiw:1` |
| look up a key in the hash map | `lib/std/map.aiw:142` | 17 | `lib/std/map.aiw:1` |
| under which license is the project published | `README.md:112` | 12 | `.agents/knowledge/architecture/source-extension.md:1` |

The first results of these are near the subject (the test of the function
that lists a directory, the head of the hash map's file), and the last is
not: the chunk of the licence is three lines. How well a query finds its
lines is a property of the model, of the texts and of how they are cut,
and the example does not measure it; ten queries are no such measure
([evaluation.md](evaluation.md) has the places of all ten, and of ten more
on another repository). What
the example shows is the path from a repository to lines that can be
opened, and that a copy of the file answers the same.

**The ranking is the engine's part**, and it was compared on that run: for
each of the ten queries, the five results of `aildb search` were the five
records with the highest cosine that numpy computed in binary64 from
`vectors.bin` and `queries.bin`, in the same order, and each printed score
was the one of numpy to its six decimals. Acceptance check 2 is the test
of this that `make test` runs.

**Not the same on every machine.** Asking twice for the vectors of the
queries gave the same bytes on this machine. Another processor, another
version of Ollama or the model without the GPU may give vectors that
differ in their last bits, so a score may differ late in its decimals and
two results that are close may change places. The six queries have their
record among five results with room, not by a rule that depends on the
last digit; the places in the output above are those of this run.

**17 of the 3266 chunks are longer than 1500 bytes**, single lines of the
documents, the longest 16983 bytes. The model read these up to its
context.
