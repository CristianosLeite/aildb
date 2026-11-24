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

- `hiredis`: [hiredis](https://github.com/redis/hiredis), the C client of
  Redis, at its tag `v1.2.0` (`60e5075`), with ten queries, seven that a
  function of C answers and three that a section of its `README.md`
  answers. It is the work of other authors and in a language the chunker
  has no units for: a file of C is cut by the limits of a chunk alone,
  so a chunk may begin in the middle of a function. Its files are cut
  as an index of a directory cuts them, every text file, which the word
  `text` after the revision in its `.pin` says; the other two corpora
  keep the chunker of their first results (`build/chunk -c`). The
  queries were written from the names and the places of the functions
  and sections, and committed before any of them was given to a model;
  none is changed for the place it gets.

Thirty queries on three repositories are a small measure, and twenty of
them are on two repositories of one author, in the same two languages.
They say whether a change makes these queries better or worse, not how
the model does on other sources.

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
`make example`: the files of the revision, `build/chunk -c`,
`build/embed` for the chunks and for the queries, `aildb build`, and
then `build/example-eval`. `CORPORA="ail"` names the corpora to run.
`build/eval/report.txt` has what was printed, with the day, the revision
of aildb, the version of Ollama and the digest of the model (`embed
model` asks Ollama for them) and the limits of a chunk.

## Variants

What a query finds depends on how the files are cut and on the model, and
both can be changed for a run. `build/chunk` and `build/embed` take the
changes as options ([example.md](example.md)), and `tools/eval.sh` takes
them from the environment:

| Variable | Changes |
|---|---|
| `EVAL_LINES`, `EVAL_BYTES` | the most lines and the most bytes of a chunk |
| `EVAL_OVERLAP` | the lines that a chunk which the limits ended has in common with the next |
| `EVAL_PATH=1` | the path of a file before the text of each of its chunks, as the model is given it |
| `EVAL_MODEL`, `EVAL_DIM` | the model that Ollama is asked for, and the elements of its vectors |
| `EVAL_DOCPREFIX`, `EVAL_QUERYPREFIX` | what stands before a chunk and before a query; both are set, and either may be empty |
| `EVAL_OUT` | the directory of the run, in the place of `build/eval` |

```
make eval-variants
```

runs `tools/eval-variants.sh`: the evaluation as it is and five variants
of it, each in `build/eval/<variant>/`, and then
`build/eval/variants.txt`, a line for each variant and corpus with the
number of chunks, the queries found among the first 1, 5 and 10 results
and the mean reciprocal rank.

| Variant | Is |
|---|---|
| `base` | 40 lines and 1500 bytes, no overlap, nomic-embed-text |
| `small` | 20 lines and 750 bytes |
| `large` | 80 lines and 3000 bytes |
| `overlap` | 10 lines in common |
| `path` | the path before the text |
| `mxbai` | the model mxbai-embed-large, 1024 dimensions, with nothing before a chunk and `Represent this sentence for searching relevant passages: ` before a query |

Each variant changes one thing against `base`. The queries are the same
in all of them and are not changed for any.

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

## Results of the variants

`make AIL=../ailang/build/ail eval-variants` printed this table on
2026-11-24, 18:06 to 18:11 UTC, for aildb at `5785d94`, built by AIL at
`d9e069e` (0.1.1), on a Core i7-12700H with an NVIDIA RTX 3050 Laptop GPU
and Linux 7.0, with Ollama 0.40.17, nomic-embed-text at the digest
`0a109f422b47` and mxbai-embed-large at `468836162de7`, both F16, with
contexts of 2048 and of 512 tokens. `first1`, `first5` and `first10` are
queries of ten:

```
variant  corpus    chunks first1 first5 first10     mrr
base     ail         3266      3      6      7  0.4517
base     aildb        554      7      8      8  0.7418
base     hiredis      529      3      5      6  0.4075
small    ail         4701      3      6      6  0.4409
small    aildb        846      6      8      8  0.6897
small    hiredis      982      2      3      4  0.2788
large    ail         2655      3      6      9  0.4743
large    aildb        432      7      8      8  0.7456
large    hiredis      313      2      5      6  0.3348
overlap  ail         4708      3      6      7  0.4486
overlap  aildb        624      7      8      8  0.7411
overlap  hiredis      753      2      4      6  0.3179
path     ail         3266      4      7     10  0.5617
path     aildb        554      8      8      8  0.8111
path     hiredis      529      2      4      6  0.3136
mxbai    ail         3266      5      8      9  0.6466
mxbai    aildb        554      7      9      9  0.7694
mxbai    hiredis      529      2      5      5  0.3167
```

`base` gives `ail` and `aildb` the figures of 2026-11-22 above, and is the
first run of `hiredis`, whose places were:

```
place 21  sds.c:381  append a number of bytes to the end of a dynamic string
place 1  sds.c:812  split a string into pieces at a separator
place 10  dict.c:300  grow the hash table when it has as many elements as slots
place 63  net.c:171  turn on TCP keepalive for a connection
place 149  net.c:607  connect to a server over a unix domain socket
place 3  read.c:162  parse a string of digits into a 64-bit integer
place 1  hiredis.c:316  build the protocol bytes of a command from a format string and arguments
place 14  README.md:308  send several commands at once and read their replies afterwards
place 1  README.md:792  replace the functions that allocate memory
place 2  README.md:597  limit how large the buffer of the reply reader may stay
```

What the table says, and how far it can be trusted: a corpus has ten
queries, so one query that moves across a line of the table is a tenth,
and a difference of one is no finding.

- **Smaller chunks are not better anywhere**, and on `hiredis`, where a
  file is cut by the limits alone, they are the worst of the six: 4 of 10
  among the first ten against 6.
- **Larger chunks** change little on the two corpora with units, where a
  function or a section ends a chunk before the limits do, and lower the
  mean reciprocal rank of `hiredis`.
- **Ten lines in common** change nothing on `ail` and `aildb`, whose
  chunks are seldom ended by the limits, and do not help `hiredis`, where
  they are.
- **The path before the text** is the largest gain on `ail` (all ten
  among the first ten, against seven) and on `aildb`, and a loss on
  `hiredis`. In the first two a path says much (`lib/std/heap.aiw`,
  `docs/durability.md`); in `hiredis` nearly every chunk is of one of a
  few large files, so the path says the same of hundreds of chunks.
- **mxbai-embed-large** is better than nomic-embed-text on `ail`, about
  the same on `aildb`, and lower on `hiredis`. It reads 512 tokens, and a
  chunk of 1500 bytes of C may be more, which Ollama cuts.
- **No variant is better on all three corpora.** The three queries of
  `hiredis` that are farthest down in `base` are answered by functions
  that do not begin their chunk: `sds.c:381` is in the chunk of the lines
  343 to 382, `net.c:171` in 147 to 186 and `net.c:607` in 585 to 624
  (`build/eval/base/hiredis/meta.tsv`). The second of them is beyond the
  place 30 in every variant, the places of the other two are in the
  reports. What this points to for such files is not a number of lines
  but units, chunks that begin where a function does, which the chunker
  has for AIL and Markdown alone; that was not built or measured here.

Nothing was changed in the index of a directory or in the example from
these figures: which of them is worth a change of the defaults is a
decision, and it is the user's.

## What was not measured

Units for other languages than AIL and Markdown, which the variants point
to. Two things changed at once, such as the path with larger chunks.
More than one other model, more than one other size in each direction,
and more than ten queries a corpus: the differences of one query in the
table above are within what other queries would give.
