# aildb

A local, file-based vector search engine written in [AIL](https://github.com/CristianosLeite/ail). Given the embedding of a query, it returns ranked source locations (path, first and last line) that an agent can open. An index is one portable file, and a query runs locally, without a server.

Embeddings are made outside the engine. The search is exhaustive cosine similarity; SQL, approximate indexes, incremental writes and a network service are outside version 1.

## Install

It needs x86-64 Linux and nothing else. Take the archive of a [release](https://github.com/CristianosLeite/aildb/releases):

```
sha256sum -c aildb-0.1.1-x86_64-linux.tar.gz.sha256
tar -xzf aildb-0.1.1-x86_64-linux.tar.gz
aildb-0.1.1-x86_64-linux/aildb check an.idx
```

Or build it from the sources, with [AIL](https://github.com/CristianosLeite/ail) 0.1.1 or later installed:

```
ail build       # build/aildb, one static executable
ail test        # the tests
```

`make` and `make test` do the same, and `make AIL=../ail/build/ail` uses the command of a checkout of AIL that is not installed.

## Use

An index is made from two files that another program wrote: the vectors as raw little-endian binary32, one after the other, and a line of metadata for each, with tabs between the path, the first line, the last line and the language. Three vectors of two dimensions and a query, made here with Python for the sake of something to run:

```
python3 -c "
import struct
open('vectors.bin','wb').write(struct.pack('<6f', 1,0, 0,1, 1,1))
open('query.bin','wb').write(struct.pack('<2f', 2,1))"
printf 'src/a.aiw\t1\t20\tail\nsrc/a.aiw\t21\t48\tail\ndocs/b.md\t1\t9\tmarkdown\n' > metadata.tsv
```

`build` makes the index:

```
$ build/aildb build -o index.aildb -v vectors.bin -m metadata.tsv -d 2 -i my-model -r 4f2a91c
{"records":3,"dimension":2,"model":"my-model","source_revision":"4f2a91c"}
```

`search` prints the best records for a query, as JSON Lines; `-p` keeps the paths that start with a prefix, and `-l` the records of a language:

```
$ build/aildb search index.aildb -k 2 -q query.bin
{"source_revision":"4f2a91c","model":"my-model"}
{"rank":1,"score":0.948683,"score_bits":"3fee5b9d0ab4f74e","path":"docs/b.md","start_line":1,"end_line":9}
{"rank":2,"score":0.894427,"score_bits":"3fec9f25c5bfedd9","path":"src/a.aiw","start_line":1,"end_line":20}
```

`check` validates an index:

```
$ build/aildb check index.aildb
{"records":3,"dimension":2,"model":"my-model","source_revision":"4f2a91c"}
```

[docs/usage.md](docs/usage.md) has every option, input, line of output and exit status.

## More

- [docs/usage.md](docs/usage.md): the three commands in full
- [docs/mcp.md](docs/mcp.md): `aildb-mcp`, the MCP server that lets Claude Code or Codex search an index in words
- [docs/library.md](docs/library.md): aildb as a dependency of a program written in AIL
- [docs/example.md](docs/example.md): `make example`, which indexes the AIL repository with a local embedding model and queries it
- [docs/evaluation.md](docs/evaluation.md): `make eval`, how well queries find their lines
- [docs/performance.md](docs/performance.md): the time and the memory of a query, and the comparison with LanceDB
- [docs/format.md](docs/format.md): the format of the index file and the precision of a score
- [docs/durability.md](docs/durability.md): what a build leaves when it is interrupted or power is lost
- [docs/TODO.md](docs/TODO.md): what is left to do
- [AGENTS.md](AGENTS.md): guidance for AI coding agents, and the rules of the repository

## License

Copyright 2026 Cristiano Leite. [Apache License 2.0](LICENSE). An executable of aildb has code of the AIL library in it, under the MIT License: [NOTICE](NOTICE) goes with every copy.
