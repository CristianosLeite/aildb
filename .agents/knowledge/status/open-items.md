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
- [ ] 2026-11-21 — The end-to-end example: the AIL repository and a local model of 768 dimensions are decided; still open are the tool that runs the model and how chunks are cut (the chunker is AIL) ([page](../architecture/requirements-decisions.md))
- [x] 2026-11-21 — The independent cosine implementation of acceptance check 2: decided (user, 2026-11-21), an AIL program apart from the engine with its own loop ([page](../architecture/feasibility.md))
- [x] 2026-11-21 — The LanceDB comparison of check 4: the Python binding is decided ([page](../architecture/requirements-decisions.md)); the harness is work, now step 10 of `docs/TODO.md`
- [x] 2026-11-21 — `REQUIREMENTS.md`: the amendment of eleven passages was accepted and applied (user, 2026-11-21); it says what the pinned AIL revision is to have, which holds once the binary32 statements are in AIL
- [ ] 2026-11-21 — `REQUIREMENTS.md`: the link of acceptance check 4 still names the JS documentation of LanceDB, while the text names the Python binding
- [ ] 2026-11-21 — Git: initialized on 2026-11-21 (user), branch `main`, with a `.gitignore` for `build/` and the links `ail` and `lib`; still open are the remote, the published name and the licence
- [ ] 2026-11-21 — The binary32 statements are on the unpushed branch `binary32` of the AIL checkout (`a5b4559`); the user reviews and publishes it, then `ail.pin` moves. The VS Code grammar of the repository ail-extensions does not know the three names yet ([page](../architecture/feasibility.md))
