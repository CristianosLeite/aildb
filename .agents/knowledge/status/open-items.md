# Open items

The decisions still to be taken. The work, step by step, is in `docs/TODO.md`
(since 2026-11-21); an item here that was work and not a decision points there.

- [x] 2026-11-21 — binary32 in AIL: decided (user, 2026-11-21), new compiler statements; the conversion with integers is the oracle of the tests ([page](../architecture/feasibility.md))
- [x] 2026-11-21 — Add the statements `fdot4`, `f4to8` and `f8to4` to the AIL repository and pin the revision: work, now step 1 of `docs/TODO.md`
- [x] 2026-11-21 — Float literals in the AIL compiler (user's proposal, 2026-11-21): work for the AIL repository, now in step 1 of `docs/TODO.md`
- [x] 2026-11-21 — Tolerances, the semantics of filters, the empty index and the exit statuses: decided as proposed (user, 2026-11-21), with the statuses 0, 2, 3, 4, 5 and 6 ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The limits of the result count, the dimension and the record count: in `docs/format.md`, chosen by the agent ([page](../architecture/format.md))
- [x] 2026-11-21 — How the repository gets AIL at a pinned revision: decided (user, 2026-11-21), `ail.pin`, `tools/ail.sh` and the link `lib` as in ail-bench ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The Makefile, the test runner and the layout of the sources: work, now step 2 of `docs/TODO.md`
- [x] 2026-11-21 — The file format in detail: written as `docs/format.md` ([page](../architecture/format.md))
- [ ] 2026-11-21 — The user is to review what the agent chose in `docs/format.md` (layout, limits) and `docs/usage.md` (option letters, the strict metadata, the object of `check`, six decimals) ([format](../architecture/format.md), [interface](../architecture/interface.md))
- [x] 2026-11-21 — The interchange format: decided (user, 2026-11-21), raw binary32 and TSV in, JSON Lines out with the score in decimal and as bits ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The exact columns, options and JSON field order of the interchange format: written as `docs/usage.md` ([page](../architecture/interface.md))
- [x] 2026-11-21 — Buffered reads or a read-only mapping: decided (user, 2026-11-21), a mapping; acceptance check 4 measures it again with the engine ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — How an overlapping build is rejected: decided (user, 2026-11-21), `flock` on `<destination>.lock`. Stop points for the interruption tests: a second test executable is what was meant (user, 2026-11-21) ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The end-to-end example: the AIL repository and a local model of 768 dimensions are decided; the model is nomic-embed-text (user, 2026-11-21); the chunks are cut as [the example page](../architecture/example.md) says, chosen by the agent and for the user to review; Ollama runs the model and `example/embed.py` asks it (agent, 2026-11-21, for the user to review)
- [x] 2026-11-21 — The independent cosine implementation of acceptance check 2: decided (user, 2026-11-21), an AIL program apart from the engine with its own loop ([page](../architecture/feasibility.md))
- [x] 2026-11-21 — The LanceDB comparison of check 4: the Python binding is decided ([page](../architecture/requirements-decisions.md)); the harness is work, now step 10 of `docs/TODO.md`
- [x] 2026-11-21 — `REQUIREMENTS.md`: the amendment of eleven passages was accepted and applied (user, 2026-11-21); it says what the pinned AIL revision is to have, which holds once the binary32 statements are in AIL
- [x] 2026-11-21 — `REQUIREMENTS.md`: the link of acceptance check 4 named the JS documentation of LanceDB; closed without a change, since the file left the repository on 2026-11-21 (user)
- [x] 2026-11-21 — Git: initialized on 2026-11-21 (user), branch `main`; the licence is the Apache License 2.0 and the copyright holder Cristiano Leite (user, 2026-11-21; [page](../architecture/requirements-decisions.md)); the remote is https://github.com/CristianosLeite/aildb, public, under the name `aildb`, created and pushed to on 2026-11-21 (user)
- [ ] 2026-11-21 — A release of version 1: a tag, a version number, and whether executables are published (with `LICENSE` and `NOTICE`); the number waits for the mechanism of versions below
- [x] 2026-11-22 — Whether later work goes to `main` directly or through pull requests: through pull requests, from a branch checked out for the work (user, 2026-11-22; [page](../architecture/requirements-decisions.md))
- [ ] 2026-11-22 — One mechanism of versions for AIL and everything derived from it (ail-bench, ail-extensions, aildb), as `Cargo.toml` is for Rust (user, 2026-11-22): what the file is called and holds, how a derived repository names the version of AIL it needs beside or in place of `ail.pin`, and which tool reads it; to be designed with the user, in the AIL repository first ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The binary32 statements: the branch `binary32` of the AIL repository is on its remote (`a5b4559`) and `ail.pin` names that commit since 2026-11-21 ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — A fresh clone builds and tests: with `ail.pin` at `a5b4559` a clone fetched AIL, built the compiler from its seed and passed `make test` (2026-11-21)
- [x] 2026-11-21 — The pin after the merge: the branch `binary32` of AIL was merged into its `main` (`e8acf57`) with the commit `a5b4559` kept, so `ail.pin` names a commit of `main` and does not move
- [ ] 2026-11-21 — The VS Code grammar of the repository ail-extensions does not know `f4to8`, `f8to4` and `fdot4`
- [ ] 2026-11-21 — The user is to review what the fixes after the review of `76104ec` chose: the name of the temporary file and that a killed build leaves it, no destination ending in `.lock`, a path that may hold `.` and `..` as long as it stays inside, `check` reading every element, `SIGPIPE` ignored ([publication](../architecture/publication.md), [format](../architecture/format.md), [interface](../architecture/interface.md))
- [x] 2026-11-21 — `REQUIREMENTS.md` is out of the repository (user, 2026-11-21); its last form is at the commit `ddc2b4d`, the pages that cite it mean that text, and the acceptance checks 1 and 4, still open, are quoted in `docs/TODO.md`
- [ ] 2026-11-21 — The example, for the user to review: how chunks are cut, Ollama as the tool, the criterion of the check (the expected lines among five results), and the four of ten queries that were taken out because their record came later ([page](../architecture/example.md))
- [ ] 2026-11-21 — The measurements, for the user to review: the decisions taken from the figures (the mapping stays, no approximate index and no parallel scan in version 1, to be looked at again near a million vectors), and whether LanceDB should also be measured in a process that stays ([page](../testing/measurement.md))
