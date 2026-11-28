---
title: The fixes after the review of cd0ee0f
last-verified: 2026-11-27
sources: [conversation 2026-11-27, REVIEW.md (never part of the repository), docs/TODO.md (step 19), docs/BACKLOG.md (step 19), tests/lib/hook.aiw, tests/cli_build_publish.aiw, src/index.aiw, mcp/tests/directory.aiw, the pull request 40 of AIL (ab402b5 and 2a65981), docs/runtime.md of AIL at that branch]
status: current
---
# The fixes after the review of cd0ee0f

**Summary.** On 2026-11-27 the user gave the agent a review of the pull request 29
(the branch `ail-0.2.1` at `cd0ee0f`) and of the pull request 40 of AIL (`ab402b5`),
a file `REVIEW.md` that is no part of the repository, with the word that the work goes
on under Windows from now on. It had three findings here and one in AIL, each fixed in
one commit, and two notes for the Windows port, which are in `docs/TODO.md` now. What
the fixes chose was chosen by the agent and is for the user to review.

## The findings here
- **The step had the number of another (P1).** `main` got step 18, the provider that
  keeps a model loaded, with the pull request 28, and this branch had given 18 to the
  runtime and Windows. `main` was merged into the branch with both entries kept in the
  three files that met (`3d6c765`), and the step of the branch is 19 (`e398eb5`).
  Rejected: a rebase of the branch, since the branch is published and a merge is what
  the branch `float-literals-in-ail` did before.
- **`sys open` in the build hooks (P3).** `tests/lib/hook.aiw` opens its two files
  with `rt open` (`4c66034`); 74 statements `sys` are left. The paths stay `data`
  with their lengths written out: a string in the statement was in
  `build/aildb-stops` six times, and `tests/cli_build_publish.aiw` expects each path
  once there. Rejected: 6 in the expected output, which is a number of the compiler's
  choices and not of the hooks.
- **Two buffers nothing used (P3).** `ts` of `ixlock` and of `mcp/tests/directory.aiw`
  are gone (`5fa2c30`).

## The finding in AIL
- **`fstat` of a pipe was a plain file on Windows (P2).** `rt_stat4` of
  `rt/windows-x86_64/rt.aiw` asks `GetFileType` first and gives the kind 4, with 0 for
  the size and the two times, for a console (2) and for a pipe or a socket (3); the
  commit is `2a65981` of the branch `file-services`. aildb needs the answer before it
  maps a snapshot or reads a chunk (`snapopen`). **0 for the times** is the agent's:
  Linux has times for a pipe and Windows has none to give. `tests/win/pipe.aiw` asks
  `fstat` of its input and its output, and `tests/rt_seek_pipe.aiw` of a pipe on
  Linux.

## The notes for Windows
- **What makes a published snapshot durable there is not decided.** `rt sync` of a
  directory is 0 on Windows with nothing flushed, and `rt rename` asks for no write
  through. `publish` takes the sync after the rename as its confirmation (status 6
  without it), so the two services cannot simply take the place of `hooksync` and of
  the rename. It is an item of step 19, before the snapshot goes on the runtime.
- **Six of the services are written**, in the pull request 40 of AIL, and in no
  version: `seek`, `pwrite`, `truncate`, `sync` of a file, `stat`, `fstat`. `belowopen`
  and `treestat` keep the walk by descriptors, since `rt stat` of a joined path looks
  at no link on the way. A map, a lock that does not wait, the time of day and an open
  below a directory are still to be written.

## How things are run on the user's machine with Windows
- **The command `ail` runs on Linux only**, so `make test` is run in Ubuntu on WSL 2,
  on a copy of the tree made with `git -c core.autocrlf=false archive`: the checkout
  of Windows has CR and LF at the end of its lines (`core.autocrlf` is true there),
  with which every expected output differs. The distribution has no `make`; the
  commands of the target `test` are typed, with the `ail` of the release archive.
- **A program of Windows is compiled in WSL** by `build/ailc-windows-x86_64` of a
  clone of AIL there and run from that shell, which gives it pipes of Windows: there
  is no Wine, and none is needed on Windows itself.
- **The checkout `../ail` cannot hold both `docs/RUNTIME.md` and `docs/runtime.md`**,
  which Windows takes for one name, so git shows one of them as changed there. The
  clone in WSL has both.

## What was checked
The commands of `make test` pass in WSL with the command of the archive of AIL 0.2.1,
checked against its `.sha256`: 49 tests, the consumer and the three of `mcp`, and both
`ail fmt --check`. `tests/cli_build_publish.aiw` failed with the string in the
statement and passes with the data. The program of `tests/win/pipe.aiw`, run on
Windows 11 with a pipe at each end, ended with 31 before the change of AIL and with
127 after it; `rt_seek`, `rt_stat`, `rt_pwrite`, `rt_fstat_dir`, `rt_pwrite_threads`
and `rt_kind` gave their outputs and statuses there after it.
