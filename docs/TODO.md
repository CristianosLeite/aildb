# TODO

The steps to version 1, in the order in which one unblocks the next.
Version 1 was stated in a file `REQUIREMENTS.md`, which left the repository
on 2026-11-21 (its last form is at the commit `ddc2b4d`); the two
acceptance checks that are still open are quoted from it under their
steps. The decisions behind these steps are in
`.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 0. Decisions before the first code

- [ ] Git: the remote and the published name. The repository was
  initialized on 2026-11-21, with a `.gitignore`.

## 1. binary32 in AIL (work in the AIL repository)

The statements are written and `ail.pin` names the revision that has them
(`docs/BACKLOG.md`).

- [ ] Float literals (user's proposal): not needed for version 1.

## 9. The example, and acceptance check 1

Acceptance check 1: build a snapshot for a real repository, query it end
to end, and verify that results identify the expected source lines; copy
the file to another path and verify the same query results. The example
chunks the AIL repository at the pinned revision, generates document and
query embeddings with the same open model running locally, builds the
file and queries it; embedding generation stays outside the engine.

- [ ] The chunker in AIL: files of the AIL repository at the pinned
  revision to the TSV and the text of each chunk.
- [ ] The embedding step outside the engine: choose the tool that runs the
  local model of 768 dimensions (nomic-embed-text is the candidate).
- [ ] `make example`: chunk, embed, build, query; a test with queries whose
  expected lines are known, and the same results from a copy of the file.

## 10. Measurement, and acceptance check 4

Acceptance check 4: measure top-10 at 10,000 and 100,000 vectors of 768
dimensions. Report median and p95 end-to-end latency for cold and warm
file-cache conditions, search time apart from startup, peak resident
memory, and file size. Compare exact search with the Python binding of
LanceDB on the same inputs and report the hardware, revisions, commands,
cache procedure, and rounds. Use the results to decide whether approximate
indexing or parallel scans are warranted, and measure again the choice of
a read-only mapping. Give both engines the same stored vector values,
query and result limit; define the timing boundaries for process startup,
snapshot or table opening, search and result materialization; document
how cold-cache conditions are verified for each engine's files and how
mapped pages contribute to reported peak resident memory.

- [ ] The harness in AIL: rounds, cold cache by `fadvise64` verified with
  `mincore`, wall time, search time apart from startup, peak resident
  memory, file size.
- [ ] The same stored values, query and limit in LanceDB through its
  Python binding; the boundaries of each time written down, how the cold
  cache is verified for the files of each engine, and how mapped pages
  count in the peak resident memory.
- [ ] `docs/performance.md` with the figures at 10,000 and 100,000 vectors
  and the decision on approximate indexes and parallel scans.

## 11. Release

- [ ] `README.md`: how to build, the three commands, the example.
- [ ] `AGENTS.md` and the knowledge base brought up to date for the
  release (the section "State" was rewritten when step 8 was done).
- [ ] If a release ships executables: the MIT notice of AIL goes with
  them, since the code of its library is compiled into `build/aildb`.
