# Retrieval evaluation

How well a query in words finds the lines that answer it is a property of
the embedding model, of the texts and of how they are cut into chunks,
not of the engine: `aildb search` returns the records with the highest
cosine, exactly, and acceptance check 2 tests that. This page measures
the other part, with fixed queries on fixed sources, so that a change of
the chunks or of the model can be compared with what was there before.
[The example](example.md) stays what it is, a check that the path from a
repository to lines that can be opened works and that a copy of a
snapshot answers the same.

## The queries

A corpus is a repository at a revision, `example/eval/<corpus>.pin`, and
a set of queries, `example/eval/<corpus>.tsv`: a line is a query, a path
and a line number of that path, with tabs between, the line at which the
answer is at that revision, chosen by reading the file.

- `ail`: AIL at `a5b4559`, the corpus of the example, with the ten queries
  that were written for the example before its first run. Six of them are
  the queries of `example/queries.tsv`; the other four were taken out of
  the example because their record came later than fifth
  ([what it showed](example.md#what-it-showed)), and are here with the
  paths and lines they had.
- `aildb`: aildb at its tag `v0.1.0` (`467b91b`), with ten queries, seven
  that a function answers and three that a section of a document answers.
  They were committed (`d48f4a7`) before any of them was given to the
  model, and none was changed after the run below.

Twenty queries on two repositories of the same author, in the same two
languages, are a small measure. They say whether a change makes these
queries better or worse, not how the model does on other sources.

## The measures

For each query, `aildb search` is asked for every record of the snapshot,
best first, and the **place** of the query is the rank of the first result
that is a record of the expected path whose lines have the expected line.
From the places of a set:

- **in the first k**, for k of 1, 5 and 10: how many queries have a place
  of at most k, and that number divided by the number of queries (the hit
  rate at k);
- **mean reciprocal rank**: the mean of 1/place, a query whose lines are in
  no record counted as 0.

`build/example-eval`, from `example/eval.aiw`, computes them;
`tests/example_eval.aiw` runs it on a snapshot whose places are known.

## Running it

With Ollama running and the model pulled, as for the example:

```
make eval
```

It works in `build/eval/`, a directory for each corpus, with the steps of
`make example`: the files of the revision, `build/chunk`,
`build/embed` for the chunks and for the queries, `aildb build`, and
then `build/example-eval`. `CORPORA="ail"` names the corpora to run.
`build/eval/report.txt` has what was printed, with the day, the revision
of aildb, the version of Ollama and the digest of the model (`embed
model` asks Ollama for them) and the limits of a chunk.

## Results

`make AIL=../ail-packages/build/ail eval` printed this on 2026-11-22, for
aildb at `d48f4a7` with the changes of the commit that added this page,
built by AIL at `9b94a9b`, on a Core i7-12700H with an NVIDIA RTX 3050
Laptop GPU and Linux 7.0. The model and the chunks:

```
Ollama 0.40.17, nomic-embed-text:latest: digest 0a109f422b47e3a30ba2b10eca18548e944e8a23073ee3f3e947efcf3c45e59f, F16, a context of 2048 tokens
chunks: at most 40 lines and 1500 bytes, no overlap
```

```
ail: https://github.com/CristianosLeite/ail.git at a5b4559c2cffbef49538a668579a3820d5e16da5
1242 files, 3266 chunks
{"records":3266,"dimension":768,"model":"nomic-embed-text","source_revision":"a5b4559c2cffbef49538a668579a3820d5e16da5"}
place 1  lib/std/io.aiw:58  print an unsigned number in decimal
place 2  lib/std/proc.aiw:208  wait for a child process to end and kill it after a time limit
place 3  lib/std/proc.aiw:274  run a thread on one CPU only
place 1  lib/std/heap.aiw:19  add a value to the heap
place 1  lib/std/queue.aiw:57  take the oldest value out of the queue
place 3  README.md:17  what do I need to install to build the compiler
place 12  lib/std/file.aiw:72  read a whole file into a buffer
place 8  lib/std/file.aiw:140  list the names in a directory
place 17  lib/std/map.aiw:142  look up a key in the hash map
place 12  README.md:112  under which license is the project published
10 queries
in the first 1: 3 of 10 (0.300)
in the first 5: 6 of 10 (0.600)
in the first 10: 7 of 10 (0.700)
no place: 0
mean reciprocal rank: 0.4517
```

```
aildb: https://github.com/CristianosLeite/aildb.git at 467b91bcb6e9070d67b400c00ddbd67366a79ff4
78 files, 554 chunks
{"records":554,"dimension":768,"model":"nomic-embed-text","source_revision":"467b91bcb6e9070d67b400c00ddbd67366a79ff4"}
place 1  src/lib/crc.aiw:48  compute the CRC-32 of a run of bytes
place 3  src/lib/norm.aiw:18  divide a vector by its norm
place 27  src/lib/topk.aiw:88  keep a score if it is among the best seen so far
place 1  src/lib/text.aiw:91  check that bytes are well-formed UTF-8
place 21  src/lib/text.aiw:160  does a path with .. leave the repository
place 1  src/lib/fmt.aiw:101  print a double with six digits after the point
place 1  src/lib/snap.aiw:268  verify the checksum of the vectors of a snapshot
place 1  docs/usage.md:21  what does exit status 5 mean
place 1  docs/durability.md:43  what is left when a build is killed before the rename
place 1  docs/format.md:177  how is the score of a record computed
10 queries
in the first 1: 7 of 10 (0.700)
in the first 5: 8 of 10 (0.800)
in the first 10: 8 of 10 (0.800)
no place: 0
mean reciprocal rank: 0.7418
```

The run took 43 seconds, the model already loaded.

The ten places of `ail` are those of the first run of the example on
2026-11-21, the four that were taken out included (12, 8, 17 and 12).
Of the twenty queries, ten have their lines as the first result and
fourteen among the first five. Two of `aildb` come late, at the places
27 and 21; why was not looked into, and the queries stay as they were
written. As the example says, the
places are those of this machine: another processor, another version of
Ollama or the model without the GPU may give vectors that differ in their
last bits, and two results that are close may change places.

## What was not measured

Other sizes of a chunk, chunks that overlap, the path as part of the
embedded text, and other models: the queries are there to compare them,
and no such comparison was run (`docs/TODO.md`).
