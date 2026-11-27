---
title: The runtime of AIL, and Windows
last-verified: 2026-11-26
sources: [conversation 2026-11-26, docs/runtime.md and docs/language.md of AIL at v0.2.1 (074ca4d), Ailfile, docs/TODO.md step 19]
status: current
---
# The runtime of AIL, and Windows

**Summary.** aildb asks for AIL 0.2.1 and calls its runtime (`rt`) for everything the
runtime has; 76 statements `sys` are left for what it has not. Windows is not supported
yet: a source with `sys` is not compiled for it, and the services aildb needs there are
not in AIL 0.2.1. They are to be written in AIL, and aildb built for Windows by the
command `ail`.

## What was learned
- **AIL 0.2.1 takes a package written for 0.1.2 as it is.** No function of the libraries
  used here was renamed or removed, and `make test` passed before any source changed.
  `fileopen` still opens a file to be closed in a program the process starts, so what a
  provider and git inherit is what it was.
- **On Windows `sys` is no statement**, also on a line that never runs
  (`docs/runtime.md` of AIL, "Windows on x86-64"). A file with one cannot be part of a
  build for Windows, so the split is by file, not by a branch.
- **The runtime of 0.2.1 has no** mapping of a file, flush, size or times of a file,
  position or write at a position, cut of a file, lock that does not wait, time of day,
  random bytes, file in memory, pipe, end of another process, open below a directory
  without following links, or path of a descriptor. `rt open` of Windows ignores the
  flags it does not know (`O_NOFOLLOW`, `O_PATH`), `rt real` resolves no link there, a
  path is at most 259 bytes, and `rt names` gives names in the code page of the process.
- **Nothing tells a program its platform**, and the command `ail` has no target: an
  executable of Windows comes from `build/ailc-windows-x86_64` of a checkout, which the
  archive of a release has not, and is tested under Wine.
- `rt rename` takes each path with its length and `rt cwd` gives a length without the
  NUL byte, where the system calls took a NUL and counted it: `publish` of
  `src/main.aiw`, `trustabs` of `src/lib/trust.aiw` and `tests/lib/cmd.aiw` changed for
  it.

## Decisions
- **aildb on AIL 0.2.1, and on Windows** (user, 2026-11-26).
- **What is missing is written in AIL, as services of its runtime** (user, 2026-11-26),
  and aildb then asks for the version that has them. Rejected: to stay within 0.2.1,
  with a snapshot read into memory, no flush, a lock that waits and no comparison of
  times on Windows, which would be a lesser aildb there.
- **The command `ail` gets a target** (user, 2026-11-26). Rejected: a `make windows`
  here that calls the compiler of a checkout with the list of `Ailfile` repeated.
- **Every command on Windows in one delivery** (user, 2026-11-26): `build`, `search`,
  `check`, `index`, `search --text`, the two providers and `aildb-mcp`. Rejected: the
  commands of a snapshot first and the index of a directory later, and Windows with the
  commands of a snapshot alone.
- **First what needs no new service** (agent, in the plan the user approved): the
  branch `ail-0.2.1`, Linux only, which leaves `sys` where the runtime has nothing.
  The tests that are about Linux alone (a named pipe, a limit of a process, a signal)
  keep `sys` and are to be listed as not for Windows.
- **Proposed, not decided** (agent): the names of the services; one file
  `src/lib/os.aiw` for what differs by platform, decided when the program runs; the
  paths of a snapshot with `/` on every platform, so the format does not change;
  `%APPDATA%\aildb\trusted`; a reader that reads the snapshot into memory if Windows
  does not let a mapped file be replaced. `docs/TODO.md`, step 19, has the items.
