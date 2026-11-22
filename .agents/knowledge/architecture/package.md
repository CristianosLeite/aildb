---
title: aildb as a package
last-verified: 2026-11-22
sources: [conversation 2026-11-22, ail.pkg, Makefile, src/lib/search.aiw, example/consumer, docs/packages.md and docs/cli.md of AIL at its branch test-home]
status: current
---
# aildb as a package

**Summary.** aildb is a package of AIL: `ail.pkg` has its name, its version, the AIL it
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
- **`ail.pkg` replaces `ail.pin`** (agent, 2026-11-22, in the plan the user approved).
  aildb asks for a version of AIL, `ail 0.1.0`, and is built by the AIL that is installed
  or named with `make AIL=`. What is lost: the exact revision of AIL that a clone was
  built and tested against. A version of AIL is a tag once the user gives one; until
  then 0.1.0 is whatever its branch has.
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
  left open where it lives. It names aildb by its directory: by its address and a version
  it needs a tag `v0.1.0`, which is the user's release.
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

- A copy of the files git tracks, in an empty directory, passes `make test` the same.
  On a tmpfs it does not: `tests/bench_tools.aiw` expects mapped pages of a file to count
  as `RssFile`, and the kernel counts those of a tmpfs as shared memory. The test is about
  the measurements, which are not made on a tmpfs; it was so before the package.

## Not checked
- A build with an installed AIL (`make install` there) in place of the checkout: the
  tests of AIL do that with a new package, not with aildb.
- aildb fetched as a dependency from its repository, which needs a tag.
