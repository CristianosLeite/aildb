# Knowledge index

The decisions about the language AIL, its compiler and its libraries are in the knowledge base of the AIL repository (https://github.com/CristianosLeite/ail, `.agents/knowledge/`), and what was learned about measuring time in that of ail-bench (https://github.com/CristianosLeite/ail-bench). The pages here are about aildb.

`REQUIREMENTS.md`, which many pages name as a source, was the user's statement of version 1. It left the repository on 2026-11-21 (user); read it with `git show ddc2b4d:REQUIREMENTS.md`.

## architecture
- [Starting point](architecture/starting-point.md) — what `REQUIREMENTS.md` already decides for version 1, what AIL at `7dea612` offers and lacks for it (no binary32), and what is left to decide

- [Feasibility of version 1 in AIL](architecture/feasibility.md) — nothing blocks it; binary32 through three new compiler statements, `build` normalizes, tests in AIL; prototype measurements of the scan (41 ms warm, 187 ms cold at 100,000 vectors), mapping against `pread64`, checksums
- [Requirement decisions for version 1](architecture/requirements-decisions.md) — a read-only mapping, CRC-32, raw binary32 and TSV in, JSON Lines out, stop points only in a test executable, AIL pinned as in ail-bench, the example and the LanceDB binding; what is proposed and not yet decided
- [The snapshot format, version 1](architecture/format.md) — why the header writes every offset, one canonical form, records of 24 bytes with shared strings, the chain of the two CRC-32, UTF-8 checked by the reader, the limits; chosen by the agent, for the user to review
- [The command line and the interchange formats](architecture/interface.md) — one-letter options, strict metadata, the JSON object of `check` and `build`, six decimals for `score`; chosen by the agent, for the user to review
- [How build publishes a snapshot](architecture/publication.md) — lock, temporary file, sync, validation, rename, directory sync; status 6; stop points and failing syncs as a file of hooks that the shipped executable has empty
- [The example](architecture/example.md) — nomic-embed-text; chunks of whole lines without overlap, a function with its comment or a Markdown section, 40 lines and 1500 bytes at most; the list of files comes from git, the text goes out as JSON strings

## testing
- [How the tests run](testing/runner.md) — `make test`: AIL programs with expected output and status, compiled and run from the top of the repository, files in `AILDB_TMP`, the indentation check
- [The independent implementation of acceptance check 2](testing/oracle.md) — what the oracle shares with the engine (the compiler only), the comparison of bytes, where the ties come from, the two differences reported apart

## status
- [Open items](status/open-items.md) — pending decisions; the work, step by step, is in `docs/TODO.md`
