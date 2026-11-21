# The example

The example indexes a real repository, the one of AIL at the revision of
`ail.pin`, and queries the index end to end. This page describes its
steps as they are written; `docs/TODO.md` says which are still to come.

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
