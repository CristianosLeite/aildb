---
title: The runtime of AIL, and Windows
last-verified: 2026-11-27
sources: [conversation 2026-11-26, conversation 2026-11-27, docs/runtime.md and docs/language.md of AIL at v0.2.1 (074ca4d), Ailfile, docs/TODO.md step 19, runs of 2026-11-27 on Windows 11 Pro build 26300 with the branch more-services of AIL (21f9b19, 1a6f5f4), review-f8c9c2a.md]
status: current
---
# The runtime of AIL, and Windows

**Summary.** aildb asks for AIL 0.2.1 and calls its runtime (`rt`) for everything the
runtime has; 74 statements `sys` are left for what it has not. Windows is not supported
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
- **Windows 11 lets a mapped file be replaced** (2026-11-27, build
  26300, NTFS): a rename onto a file that another process has mapped
  answers 0, the memory stays the old file, and the name leads to the
  new one; to remove a mapped file is allowed, to cut it is not (-5).
  It is the test `rt_map_replace` of AIL (its pull request 41). On
  the share that the file system of WSL is to Windows the same rename
  fails, so a snapshot there is no case to rely on. Wine and an older
  Windows were not asked.
- **A program of Windows runs from WSL 2**, so the tests for Windows
  need no Wine on the machine with Windows: a script named `wine`
  that starts its first argument, and the tree on NTFS
  (`.agents/knowledge/testing/windows-itself.md` of AIL). WSL gives
  such a program the bare name of its file as its first argument.
- **`rt trylock` takes a path**, where `flock` took a descriptor that
  `build` and `index` had opened: the lock of a directory on Windows
  is the file `.ail-lock` in it, which stays. On Linux it follows a
  link at the end of the path, which `ixlock` does not
  (`review-f8c9c2a.md`), and it is -22 for what is neither a
  directory nor a plain file, on Windows too since `c286a5b` of AIL.
  So `ixlock` keeps `flock` until the runtime locks an open
  descriptor (`review-721ed45.md`).
- **`rt map` promises a write after it of Linux alone**, and
  `rt time` may be an error (the review of `f8c9c2a`): a reader
  needs neither a later write nor more than the old file kept, and
  `index` is to look at the time it gets.
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
- **aildb is 0.2.0 when it has an executable for Windows** (user, 2026-11-27), and not
  before: the branch `ail-0.2.1` is merged with the version as it was, 0.1.2. The same
  day the user had the pull request 40 of AIL merged and AIL made 0.2.2, the first
  version with its six services for a file; `Ailfile` here asks for 0.2.2 with the
  first source that calls one of them (agent), since 0.2.1 builds everything until
  then. **AIL 0.2.3** (user, 2026-11-28, with the word to merge the pull request 41 of
  AIL and the pull request 30 here) is the first with the six services more, `time`,
  `random`, `platform`, `trylock`, `map` and `unmap`; its tag `v0.2.3` names the merge
  `b9d172c`, and the notes of its release say that `lock` refuses a named pipe and a
  device, which 0.2.2 took. `Ailfile` asks for it in the same way (agent).
- **A reader maps the snapshot on Windows too** (agent, 2026-11-27,
  from what Windows 11 did, above), with `rt map`. The reader that
  reads the file into memory stays a way out for a platform that
  refuses the rename, and is not written until one is found.
- **Six services more are written, the pull request 41 of AIL**
  (agent, 2026-11-27, at the user's word to go on with step 19):
  `time`, `random`, `platform` (1 Linux, 2 Windows), `trylock`, `map`
  and `unmap`. The names are the agent's. Which version of AIL has
  them is the user's to say.
- **Proposed, not decided** (agent): one file
  `src/lib/os.aiw` for what differs by platform, decided when the program runs; the
  paths of a snapshot with `/` on every platform, so the format does not change;
  `%APPDATA%\aildb\trusted`; a reader that reads the snapshot into memory if Windows
  does not let a mapped file be replaced. `docs/TODO.md`, step 19, has the items.
