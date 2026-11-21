# aildb requirements

## Goal

Build a local, file-based vector search engine in AIL. The first application is semantic search over a source repository. Given a query embedding, return ranked source locations that an agent can open directly. Aim for the convenience of SQLite and use LanceDB as a reference for vector search.

Version 1 stores a rebuildable index. The source files remain authoritative. An index is one portable file and queries run locally without a server. Each rebuild publishes a complete snapshot. Transactional updates to original data are outside this version.

## First usable release

- Ship an x86-64 Linux CLI. Implement the file reader, scoring loop, and top-k selection in AIL. Pin the compiler revision used by the project and document how to build it. Write the tests, the measuring harness, and the chunker of the example in AIL as well. Only the embedding model and LanceDB stay outside it. [AIL repository](https://github.com/CristianosLeite/ail)
- Provide `build`, `search`, and `check` commands. Build an index from precomputed embeddings and source metadata. Search accepts a precomputed query vector and a positive result limit, with optional path-prefix and language filters. Check validates a snapshot and reports its record count, dimension, and model identifier. Build reads the vectors as contiguous little-endian binary32 in one file and the metadata as tab-separated text with one record per line. Search reads the query as raw binary32 from a file or standard input. Document both formats.
- Include an end-to-end example that chunks the AIL repository at the pinned revision, generates document and query embeddings with the same open model running locally, builds the file, and queries it. Keep embedding generation outside the engine. Return results as JSON Lines containing rank, similarity score in decimal and as the bits of its binary64, repository-relative path, and one-based start and end lines. Record the source revision when available so callers can identify stale locations.

## Search and file format

- Store fixed-dimension, contiguous little-endian IEEE 754 binary32 vectors. Store a format version, vector count, dimension, embedding model identifier, and source metadata. Document how normalization, offsets, and integrity checks are encoded.
- Rank with exhaustive cosine similarity over eligible records. Build accepts any finite, nonzero vector, normalizes it in binary64, and stores it rounded to binary32. Score with a dot product with documented precision and scoring tolerance. Apply filters before scoring. Break ties by record ordinal. Reject wrong dimensions, mismatched model identifiers when supplied, non-finite values, and zero vectors.
- Use a serial scan with reusable buffers and bounded top-k workspace. Avoid allocating memory per candidate. Read the vectors through a read-only memory mapping, and measure that choice again in acceptance check 4. Score through the binary32 statements of the pinned AIL revision, which widen each element to binary64 and add the products in record order, and document that conversion.
- Validate lengths, offsets, counts, and arithmetic before accessing the file. Reject unknown versions and structurally invalid files with a nonzero exit and a diagnostic. Protect the header and metadata with one CRC-32, which every command verifies, and the vectors with another, which the check command verifies.

## Snapshot publication

- Build into a temporary file in the destination directory. Flush the completed file and validate it before publishing with an atomic rename. Flush the parent directory before reporting a durable commit. Report write and sync failures.
- Support one builder and concurrent read-only queries. Publish by replacing the path and leave each published file immutable. A reader that has opened a snapshot may finish against it while new readers open the replacement. Reject an overlapping build for the same destination.
- An interrupted build must never expose a partial snapshot at the destination. Test interruptions before and after rename and verify that the destination is absent for an interrupted first build before publication, or contains a complete old or new snapshot. Process interruption tests establish process-level behavior. Stop points that these tests need must not exist in the shipped executable. Document filesystem and storage assumptions separately for power-loss durability.

## Acceptance

1. Build a snapshot for a real repository, query it end to end, and verify that results identify the expected source lines. Copy the file to another path and verify the same query results.
2. Compare exact top-k and scores against an independent cosine implementation, written in AIL apart from the engine, on the same stored vectors within the documented tolerance. Cover empty collections, filters with no matches, deterministic ties, and k larger than the eligible count.
3. Exercise malformed input, truncated and corrupted files, a failed rebuild, and readers overlapping a successful rebuild. Corruption checks must fail cleanly. A failed rebuild before publication must preserve the previous file.
4. Measure top-10 at 10,000 and 100,000 vectors of 768 dimensions. Report median and p95 end-to-end latency for cold and warm file-cache conditions, search time apart from startup, peak resident memory, and file size. Compare exact search with the Python binding of LanceDB on the same inputs and report the hardware, revisions, commands, cache procedure, and rounds. Use the results to decide whether approximate indexing or parallel scans are warranted. [LanceDB exact search](https://lancedb.github.io/lancedb/js/classes/VectorQuery/)

SQL, approximate indexes, incremental writes, and network service are outside version 1. If the project later needs mutable authoritative data, evaluate SQLite for transactional storage before introducing a custom journal or a second authoritative file format.

## Design review notes

- **Scoring and acceptance.** Define the score as the binary64 dot product of the normalized query and the normalized vectors rounded to binary32 for storage. In acceptance check 2, have the independent implementation verify that score and the resulting top-k. If the reference recomputes cosine by dividing by the stored vector’s norm, quantify that difference separately from floating-point accumulation error. Use a tie fixture that produces equal scores and verifies record order.
- **Integrity checks.** State that `search` validates the file structure and the header and metadata checksum, while `check` also verifies the vector payload checksum. In acceptance check 3, alter a vector byte without changing the file length and require `check` to reject the snapshot. Test truncation separately.
- **Publication and durability.** Specify what `build` reports if the rename succeeds but syncing the parent directory fails. The replacement can already be visible, while its durability remains unconfirmed. Add this case to acceptance check 3 alongside the pre-rename failure that must preserve the previous snapshot. [Linux `fsync` documentation](https://man7.org/linux/man-pages/man2/fsync.2.html)
- **Benchmark comparability.** Give both engines the same stored vector values, query and result limit. Define the timing boundaries for process startup, snapshot or table opening, search and result materialization. Document how cold-cache conditions are verified for each engine’s files and how mapped pages contribute to reported peak resident memory.
