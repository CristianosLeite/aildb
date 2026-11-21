# TODO

The steps to version 1, in the order in which one unblocks the next.
`REQUIREMENTS.md` says what version 1 is; the decisions behind these steps
are in `.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 0. Decisions before the first code

- [ ] `REQUIREMENTS.md`: the link of acceptance check 4 names the JS
  documentation of LanceDB while the Python binding is used.
- [ ] Git: the remote, the published name and the licence. The repository
  was initialized on 2026-11-21, with a `.gitignore`.

## 1. binary32 in AIL (work in the AIL repository)

Steps 2 to 5 do not wait for this one; `build` and `search` do. It is done
by the agent on a branch of the checkout that is not pushed; the user
reviews and publishes it, and `ail.pin` then moves to that revision.

- [ ] Move `ail.pin` to the revision that has the three statements, once
  the user has reviewed and published the branch `binary32` of the
  checkout (`a5b4559` there on 2026-11-21); until then only a build with
  `make AIL=<that checkout>` can compile them.
- [ ] Float literals (user's proposal): not needed for version 1.

## 9. The example, and acceptance check 1

- [ ] The chunker in AIL: files of the AIL repository at the pinned
  revision to the TSV and the text of each chunk.
- [ ] The embedding step outside the engine: choose the tool that runs the
  local model of 768 dimensions (nomic-embed-text is the candidate).
- [ ] `make example`: chunk, embed, build, query; a test with queries whose
  expected lines are known, and the same results from a copy of the file.

## 10. Measurement, and acceptance check 4

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
- [ ] `AGENTS.md`: the section "State" rewritten; the knowledge base
  brought up to date.
