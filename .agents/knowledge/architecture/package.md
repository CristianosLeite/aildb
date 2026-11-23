---
title: aildb as a package
last-verified: 2026-11-22
sources: [conversation 2026-11-22, Ailfile, Makefile, src/lib/search.aiw, example/consumer, docs/packages.md and docs/cli.md of AIL at 9b94a9b]
status: current
---
# aildb as a package

**Summary.** aildb is a package of AIL: `Ailfile` has its name, its version, the AIL it
needs and its executables, the command `ail` builds and tests it, and a program imports
its search with `use "aildb:src/lib/search.aiw"`. The file `ail.pin`, the script that
cloned AIL and the two test scripts are gone.

## Decisions
- **One mechanism of versions for AIL and what is built on it** (user, 2026-11-22): a
  manifest of lines of a key and its values, a semantic version of AIL apart from the
  seed, the version and the dependencies in the manifest, a command as simple as cargo and
  npm, and as the proof a project that imports aildb. The mechanism is in the AIL
  repository (its `.agents/knowledge/architecture/packages.md` has its decisions); this
  page is what it changed here.
- **`Ailfile` replaces `ail.pin`** (agent, 2026-11-22, in the plan the user approved).
  aildb asks for a version of AIL, `ail 0.1.0`, and is built by the AIL that is installed
  or named with `make AIL=`. What is lost: the exact revision of AIL that a clone was
  built and tested against. A version of AIL is a tag: `v0.1.0` is its `9b94a9b`
  (2026-11-22), and `v0.1.0` of aildb is `467b91b`, built and tested with it.
- **The manifest is called `Ailfile`** and a lock `Ailfile.lock` (user, 2026-11-22;
  pull request 26 of AIL). It was `ail.pkg` until the same day: `.pkg` is the installer
  package of macOS and of other systems, and a tool that goes by the extension takes
  the manifest for one. AIL's knowledge base has what was rejected.
- **The Makefile stays, as three lines over the command** (agent): `make` and `make test`
  are habit, and `example` and `bench` are steps the command has no word for. The
  executables that only tests, the example and the measurements need are `testbin`
  lines, which `ail test` builds.
- **The search is a library** (user, 2026-11-22, of two choices): `src/lib/search.aiw`,
  taken out of `src/main.aiw`, which calls it. Rejected: leaving a program to write the
  loop over `snap`, `norm` and `topk` itself, which proves the mechanism and gives no
  interface. The files of `src/lib/` name what they need with `use`, so one line imports
  the search. `build` is not offered as a call: it is the command, with its lock and its
  syncs.
- **The program that imports aildb is `example/consumer`, in this repository** (agent,
  for the user to review): a package of its own, made with `ail new` and
  `ail add --path ../..`, whose test compares its results with those of the command and
  which `make test` runs. In the repository it is tested with every change; the plan had
  left open where it lives. It named aildb by its directory until the tag `v0.1.0` was
  there; since 2026-11-22 by its address and the version 0.1.0, with `Ailfile.lock` (user:
  "update the consumer"). What that costs: the test of the consumer runs the library of
  the tag against the command of the checkout, so a change of `src/lib/` is not seen by
  it (`tests/lib_search.aiw` and the tests of the command see it), and the first
  `make test` of a new checkout clones the tag from the network. Rejected: keeping the
  directory, which never shows the way a user of the package takes.
- **The corpus of the example has its own pin**, `example/corpus.pin`, the address and
  the revision `a5b4559` that `ail.pin` had: the queries expect the lines of that
  revision, whatever AIL builds aildb.
- **A test finds AIL in `AIL_HOME`**, which `ail test` sets: `tests/notice_ail.aiw` reads
  the licence of the AIL whose library is compiled in, where it read `ail/LICENSE`.

## Checked on 2026-11-22, with the command of the AIL branch `test-home`, and again with that of `packages-review`
- `build/aildb` is the same bytes as the compiler gives for `src/aildb.aiw` without
  packages, the way `make` built it before (`cmp`).
- `make test`: 26 programs, the indentation, and the test of `example/consumer`, whose
  scores have the bits the command prints.
- `make example` against the running Ollama: 3266 records, 6 of 6 queries with the
  expected lines in the first 5 results.

- With the command of `main` of AIL at `9b94a9b`, after its pull requests 17 to 27 were
  merged: `make test` passes, 26 programs, the indentation and the test of
  `example/consumer`. `make example` was not run again.
- aildb fetched as a dependency from its repository (2026-11-22, `ail` of AIL at
  `9b94a9b`): in `example/consumer`, `ail remove aildb` and `ail add` with the address and
  0.1.0 wrote the lock with `467b91b`; with `deps/` and `build/` removed, `ail test`
  cloned the tag and passed, and so did `make test`.
- A copy of the files git tracks, in an empty directory, passes `make test` the same.
  On a tmpfs it did not while the measurements were here (they are in aildb-bench since
  2026-11-22): `tests/bench_tools.aiw` expects mapped pages of a file to count
  as `RssFile`, and the kernel counts those of a tmpfs as shared memory. The test is about
  the measurements, which are not made on a tmpfs; it was so before the package.

## Not checked
- A build with an installed AIL (`make install` there) in place of the checkout: the
  tests of AIL do that with a new package, not with aildb.

## 0.1.1 (user, 2026-11-22)
- AIL got the version 0.1.1 for the libraries the MCP server needs, and the user asked for
  every package of the family to be 0.1.1, the line `ail` and the version of each. Here:
  `Ailfile`, `mcp/Ailfile` and `example/consumer/Ailfile` are 0.1.1 and ask for AIL 0.1.1;
  the server names ail-extensions 0.1.1 (`3d02922`). The tag `v0.1.1` is on the merge of
  the pull request 11.
- `example/consumer` still names aildb 0.1.0 at that tag: a package cannot name a version
  of the repository it is in before that version is tagged, as it was with 0.1.0, where
  the consumer named the directory first and the address afterwards. A change after the
  tag names 0.1.1.
