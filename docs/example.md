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
build/chunk ROOT META TEXT < LIST
```

`LIST` is paths relative to the directory `ROOT`, one a line, as `git
ls-tree -r --name-only` prints them. A path that ends in `.aiw` is taken
as a source of AIL and one that ends in `.md` as Markdown; every other
path is passed over. `META` gets a line for each chunk, in the form
`build` takes as metadata: the path as the list has it, the first line,
the last line and the language, `ail` or `markdown`. `TEXT` gets a line
for each chunk in the same order, the bytes of its lines as a string of
JSON, for the program that makes the embeddings. A line feed is between
the lines of a chunk and none is at its end. The bytes are those of the
file: a carriage return stays, and a file that is not UTF-8 gives a
string that is not.

The status is 0, with the number of files and chunks on standard output;
2 for wrong usage; 3 for a path that `build` would not take (a byte
below 0x20, or a path that is absolute or leads out of `ROOT`); 4 for a
file that cannot be read or written. Nothing is written after a failure.

How a file is cut:

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
    with three backquotes.
- A chunk also ends before a line that would make it longer than 40 lines,
  counted from its first line, or longer than 1500 bytes. A single line
  above 1500 bytes is a chunk of its own.

What comes before the first function of a source, or the first heading of
a document, is a chunk as well, and statements after the last function
belong to the chunk of that function until a limit ends it.

The limits are for the embedding model: 1500 bytes are well inside the
text that the model reads at once, and a chunk that is one function or one
section says where to open the file. They are constants at the top of
`example/chunk.aiw`.

`tests/example_chunk.aiw` shows each rule on small files. On the AIL
repository at `a5b4559`, `build/chunk` printed on 2026-11-21:

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

`example/embed.py` asks it for the vectors. It needs Python 3 and nothing
that is not in its standard library:

```
python3 example/embed.py document TEXT VECTORS
python3 example/embed.py query QUERIES VECTORS
```

`TEXT` is the file of that name of `build/chunk`; `QUERIES` has a query
on each line, up to the first tab. `VECTORS` gets one vector for each
line, in order, 768 binary32, little-endian: the file `aildb build -v`
reads, and for one query the bytes `aildb search -q` reads. The file is
written whole or not at all.

- The model is trained with a word in front of each text that says what
  it is for. A chunk is sent as `search_document: ` and its text, a query
  as `search_query: ` and its text. A query embedded without the word, or
  with the other one, is compared with vectors it was not made for.
- A byte sequence that is not UTF-8 is sent as U+FFFD.
- The texts go to `/api/embed` of Ollama sixteen at a time, at the address
  of the environment variable `OLLAMA_HOST` or `http://127.0.0.1:11434`.
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
3. `example/embed.py` writes `vectors.bin` for the chunks and
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

To ask something else, embed it and search:

```
printf 'how do I start a child process\n' > q.txt
python3 example/embed.py query q.txt q.bin
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
and the example does not measure it; ten queries are no such measure. What
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
