---
title: The fixes after the review of f8c9c2a
last-verified: 2026-11-27
sources: [conversation 2026-11-27, REVIEW.md (never part of the repository), docs/TODO.md (step 19), docs/BACKLOG.md (step 19), src/index.aiw (ixlock), the pull request 41 of AIL (0723385, then b89bcc9, 209c686 and 9400a97), docs/runtime.md of AIL at that branch, the remarks of MapViewOfFile in the documents of Windows as the review cites them]
status: current
---
# The fixes after the review of f8c9c2a

**Summary.** On 2026-11-27 the user gave the agent a review of the pull request 30
(the branch `runtime-services` at `f8c9c2a`, documents only) and of the pull request
41 of AIL (`0723385`, six services of the runtime), a file `REVIEW.md` that is no part
of the repository. It had three findings in AIL and one here, each fixed in one
commit, and two notes for the time aildb calls the services. What the fixes chose was
chosen by the agent and is for the user to review.

## The findings in AIL
- **`trylock` of Linux could wait (P2).** `rt_locking` opened the path to read it
  before it asked for the lock, and the open of a named pipe waits for a writer. The
  open does not wait now (`O_NONBLOCK`), and what it gives is asked its kind: anything
  but a directory and a plain file is the error -22 (`b89bcc9`). **For `lock` too**
  (agent): the two share the function, and `lock` is in AIL 0.2.2, so a service of a
  released version now refuses what it took before, a lock of a named pipe or of a
  device, which the documents never offered. Rejected: the change for `trylock` alone,
  which leaves a `lock` that waits for something that is no process with the lock.
- **`map` promised of Windows what Windows does not (P2).** The table said that what
  is written to a file after it was mapped is read in the memory. Windows leaves open
  that a view (`MapViewOfFile`) and `WriteFile` agree; it was so on NTFS at build
  26300. The documents promise it of Linux alone and the check is the test
  `rt_map_written`, which `tests/win.skip` names (`9400a97`). Rejected: to make it
  hold on Windows, by a flush or by a mapping that is kept, which is slower and still
  rests on what Windows does not promise.
- **`time` of Linux hid an error (P3).** It read its two numbers whatever
  `clock_gettime` had returned, so a kernel that refused the call gave 0, the start
  of 1970. It returns the error (`209c686`); Windows has none to give.

## The finding here
- **A mapped snapshot replaced, by file system too (P3).** The item of `docs/TODO.md`
  asked Wine and an older Windows. It now names what is known, NTFS at build 26300,
  where the rename is allowed, and the share of WSL, where it fails, and what was not
  asked, the other file systems among it; the documents of a version for Windows are
  to say where a snapshot is mapped and where it is read into memory.

## What aildb is to do when it calls them
- **A reader needs no write to be seen.** A snapshot is written under another name
  and not written again once it has its own; a reader needs the old file to stay as
  it was until it gives the memory back, which `rt_map_replace` shows.
- **The lock of an index keeps no link followed.** `ixlock` of `src/index.aiw` opens
  `.aildb/lock` with `O_NOFOLLOW` and locks that descriptor. `rt trylock` opens a
  path and follows a link at its end on Linux. So the lock stays on a descriptor
  opened so, or the service gets the same, before `flock` is replaced there; it is
  written in the item of step 19 about links. Not decided which.
- **A time that is an error ends the run.** `index` records in its manifest the time
  a run started; with `rt time` it is to look for a negative number before it writes
  one.
- What makes a published snapshot durable on Windows is still its own item of step
  19; this review did not change it.

## What was checked
On Ubuntu in WSL 2, 2026-11-27, with the compilers of the branch: `rt_lock_fifo`
ended with 124 after five seconds with the runtime as it was and passes with the
change; `rt_time_refused` ended with 3 before and with 7 after; `rt_map`,
`rt_map_written` and `rt_map_replace` pass. On Windows 11 Pro, build 26300, on NTFS:
`rt_map`, `rt_map_replace` and `rt_time`. The runs of the whole suites are in the
pull request 41 of AIL.
