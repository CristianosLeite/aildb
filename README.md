# aildb

A local, file-based vector search engine written in [AIL](https://github.com/CristianosLeite/ail), a programming language designed to cost few tokens when an AI writes it.

The first application is semantic search over a source repository: given the embedding of a query, aildb returns ranked source locations (path, start and end line) that an agent can open directly. An index is one portable file, rebuilt from the sources, which stay authoritative. Queries run locally, without a server. The aim is the convenience of SQLite, with LanceDB as the reference for vector search.

## Status

Being written. The three commands work and are tested on small snapshots; the comparison with an independent implementation, the interruption tests, the end-to-end example and the measurements are still to come: [REQUIREMENTS.md](REQUIREMENTS.md) states what version 1 must do, [docs/TODO.md](docs/TODO.md) has the steps that are left, and the questions still open are listed in [.agents/knowledge/status/open-items.md](.agents/knowledge/status/open-items.md).

## Version 1 in short

- A command line program for x86-64 Linux with three commands: `build` makes an index from precomputed embeddings and source metadata, `search` ranks the records against a query vector, with optional filters by path prefix and language, and `check` validates an index.
- Exhaustive cosine similarity over fixed-dimension vectors, stored as contiguous little-endian binary32; ties are broken by record order.
- A rebuild publishes a complete snapshot with an atomic rename: one builder, any number of readers, and never a partial file at the destination.
- Embeddings are generated outside the engine.

SQL, approximate indexes, incremental writes and a network service are outside version 1.

## Documents

- [REQUIREMENTS.md](REQUIREMENTS.md): the goal, the first usable release, the file format, snapshot publication and the acceptance checks
- [docs/usage.md](docs/usage.md): the three commands, their inputs, their output and their exit statuses
- [docs/format.md](docs/format.md): the format of the snapshot file, its checks and the precision of a score
- [docs/durability.md](docs/durability.md): what a build leaves when it is interrupted, and what is assumed of the filesystem and the storage when power is lost
- [AGENTS.md](AGENTS.md): guidance for AI coding agents, with the rules of the repository and what AIL offers the project
- [.agents/knowledge/INDEX.md](.agents/knowledge/INDEX.md): the knowledge base, decisions and their reasons
