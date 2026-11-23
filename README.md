# aildb

A local, file-based vector search engine written in [AIL](https://github.com/CristianosLeite/ail), a programming language designed to cost few tokens when an AI writes it.

The first application is semantic search over a source repository: given the embedding of a query, aildb returns ranked source locations (path, start and end line) that an agent can open directly. An index is one portable file, rebuilt from the sources, which stay authoritative. Queries run locally, without a server. The aim is the convenience of SQLite, with LanceDB as the reference for vector search.

## Status

Version 1 is written: the three commands, the snapshot format, the way a snapshot is published, and the four acceptance checks it was to meet, each shown by a test, by the example or by the measurements. Version 0.1.1 is the tag `v0.1.1`, the first with the MCP server and made for AIL 0.1.1, after 0.1.0, the tag `v0.1.0`; work reaches `main` through pull requests; [docs/TODO.md](docs/TODO.md) has what is left, and the choices that still wait for a review are in [.agents/knowledge/status/open-items.md](.agents/knowledge/status/open-items.md).

## Version 1 in short

- A command line program for x86-64 Linux with three commands: `build` makes an index from precomputed embeddings and source metadata, `search` ranks the records against a query vector, with optional filters by path prefix and language, and `check` validates an index.
- Exhaustive cosine similarity over fixed-dimension vectors, stored as contiguous little-endian binary32; ties are broken by record order.
- A rebuild publishes a complete snapshot with an atomic rename: one builder, any number of readers, and never a partial file at the destination.
- Embeddings are generated outside the engine.

SQL, approximate indexes, incremental writes and a network service are outside version 1.

## Building

aildb is a package of AIL and is built by its command, `ail` ([AIL](https://github.com/CristianosLeite/ail): `make install PREFIX=$HOME/.local` there puts the command, the compiler and the library in place). It needs x86-64 Linux and nothing else.

```
ail build       # build/aildb
ail test        # the tests: 26 programs
```

`make` and `make test` do the same, and `make test` also checks the indentation and runs the packages of `example/consumer` and of `mcp`, the MCP server; AIL is to be 0.1.1 or later; `make AIL=../ail/build/ail` uses the command of a checkout of AIL that is not installed. `build/aildb` is one static executable that can be copied anywhere.

## The executable

A release has the executable for x86-64 Linux as an archive, `aildb-<version>-x86_64-linux.tar.gz`, and the SHA-256 of the archive in a file beside it. It needs no AIL and nothing installed:

```
sha256sum -c aildb-0.1.1-x86_64-linux.tar.gz.sha256
tar -xzf aildb-0.1.1-x86_64-linux.tar.gz
aildb-0.1.1-x86_64-linux/aildb check an.idx
```

The directory has `aildb`, `LICENSE`, `NOTICE`, which goes with the executable to whoever gets it, and `BUILD`, which names the revision of aildb and the revision of AIL that made it. `make dist` makes the archive from the tag of the version in `Ailfile` (`REV=` names another revision) and gives the same bytes each time; `make dist-check` unpacks it in a Docker container that has no AIL and runs the three commands there.

## Using it

An index is made from two files that another program wrote: the vectors as raw binary32, one after the other, and a line of metadata for each, with tabs between the path, the first line, the last line and the language. Three vectors of two dimensions and a query, made here with Python for the sake of something to run:

```
python3 -c "
import struct
open('vectors.bin','wb').write(struct.pack('<6f', 1,0, 0,1, 1,1))
open('query.bin','wb').write(struct.pack('<2f', 2,1))"
printf 'src/a.aiw\t1\t20\tail\nsrc/a.aiw\t21\t48\tail\ndocs/b.md\t1\t9\tmarkdown\n' > metadata.tsv
```

`build` makes the index, a snapshot, and says what is in it:

```
$ build/aildb build -o index.aildb -v vectors.bin -m metadata.tsv -d 2 -i my-model -r 4f2a91c
{"records":3,"dimension":2,"model":"my-model","source_revision":"4f2a91c"}
```

`search` prints a line about the snapshot and the best records for a query, as JSON Lines; `-p` keeps the records whose path starts with a prefix, and `-l` those of a language:

```
$ build/aildb search index.aildb -k 2 -q query.bin
{"source_revision":"4f2a91c","model":"my-model"}
{"rank":1,"score":0.948683,"score_bits":"3fee5b9d0ab4f74e","path":"docs/b.md","start_line":1,"end_line":9}
{"rank":2,"score":0.894427,"score_bits":"3fec9f25c5bfedd9","path":"src/a.aiw","start_line":1,"end_line":20}
$ build/aildb search index.aildb -k 2 -q query.bin -p src/
{"source_revision":"4f2a91c","model":"my-model"}
{"rank":1,"score":0.894427,"score_bits":"3fec9f25c5bfedd9","path":"src/a.aiw","start_line":1,"end_line":20}
{"rank":2,"score":0.447214,"score_bits":"3fdc9f25c5bfedd9","path":"src/a.aiw","start_line":21,"end_line":48}
```

`check` validates a snapshot, the checksum of its vectors included, which `search` does not read:

```
$ build/aildb check index.aildb
{"records":3,"dimension":2,"model":"my-model","source_revision":"4f2a91c"}
```

The exit status is 0 for success, 2 for wrong usage, 3 for an invalid snapshot or input, 4 for an I/O failure, 5 when another build is running for the same index and 6 when a snapshot was published without its durability confirmed. A build leaves the file `index.aildb.lock` beside the index, which is its lock and stays. [docs/usage.md](docs/usage.md) has every option, input and line of output.

## In a program

A program written in AIL searches a snapshot itself, with the library the command is made of: aildb is a dependency in its manifest, and one line brings the search.

```
ail add --path ../aildb
```

```
use "aildb:src/lib/search.aiw"
```

[docs/library.md](docs/library.md) has the functions, and `example/consumer` is a program that uses them, tested against the command.

## The example

`make example` indexes the AIL repository itself, at the revision of `example/corpus.pin`: an AIL program cuts its sources into chunks, a function or a section each, the embedding model nomic-embed-text makes the vectors, run on the same machine by [Ollama](https://ollama.com), and `search` is asked questions in words whose lines in the sources are known. It needs Ollama running with the model pulled, and Python 3. [docs/example.md](docs/example.md) describes the steps and what a run showed, including the queries that did not find their lines. `make eval` measures that part on fixed queries, the place at which each finds its lines on two repositories, and [docs/evaluation.md](docs/evaluation.md) has the measures.

## How fast

Measured on one machine (a Core i7-12700H, the file on an NVMe drive), for the ten best of vectors of 768 dimensions, a process a query, as the median of the rounds:

| Records | File | In the file cache | Read from the drive |
|---:|---:|---:|---:|
| 10,000 | 31 MB | 4 ms | 18 ms |
| 100,000 | 310 MB | 38 ms | 182 ms |

[docs/performance.md](docs/performance.md) has the method, every figure, the same searches in LanceDB, and why version 1 has no approximate index and scans on one thread.

## For a coding agent

`aildb-mcp`, in `mcp/`, is a server of the Model Context Protocol: Claude Code or Codex asks it in words, it gets the vector of the query from the embedding model and the locations from `aildb search`, and answers with paths, lines and the revision to open them at. [docs/mcp.md](docs/mcp.md) says how it is started and added to an agent.

## Documents

- [docs/usage.md](docs/usage.md): the three commands, their inputs, their output and their exit statuses
- [docs/format.md](docs/format.md): the format of the snapshot file, its checks and the precision of a score
- [docs/durability.md](docs/durability.md): what a build leaves when it is interrupted, and what is assumed of the filesystem and the storage when power is lost
- [docs/example.md](docs/example.md): the example, `make example`, which indexes the AIL repository with a local embedding model and queries it
- [docs/performance.md](docs/performance.md): the time and the memory of a query at 10,000 and 100,000 vectors, how they are measured, the comparison with LanceDB and what was decided from it
- [AGENTS.md](AGENTS.md): guidance for AI coding agents, with the rules of the repository and what AIL offers the project
- [.agents/knowledge/INDEX.md](.agents/knowledge/INDEX.md): the knowledge base, decisions and their reasons

## License

Copyright 2026 Cristiano Leite. [Apache License 2.0](LICENSE). An executable of aildb has code of the AIL library compiled into it, which is under the MIT License: [NOTICE](NOTICE) has that licence and goes with every copy of an executable, beside `LICENSE`.
