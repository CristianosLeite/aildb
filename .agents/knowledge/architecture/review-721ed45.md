---
title: The fix after the review of 721ed45
last-verified: 2026-11-28
sources: [conversation 2026-11-28, REVIEW.md (never part of the repository), docs/TODO.md (step 19), docs/BACKLOG.md (step 19), src/index.aiw (ixlock, ixbegin), the pull request 41 of AIL (9400a97, then c286a5b), rt/windows-x86_64/rt.aiw and docs/runtime.md of AIL at that branch]
status: current
---
# The fix after the review of 721ed45

**Summary.** On 2026-11-28 the user gave the agent a second review of the pull
request 30 (`721ed45`) and of the pull request 41 of AIL (`9400a97`), a file
`REVIEW.md` that is no part of the repository. It found the four findings of the
review before it answered ([review-f8c9c2a.md](review-f8c9c2a.md)), one thing more
in AIL, fixed in one commit, and it suggested how three items of step 19 are to be
done. The suggestions are in `docs/TODO.md` as the way those items are done; that
they were taken is the agent's, for the user to review.

## The finding in AIL
- **Windows gave the lock of a device (P2).** Since `b89bcc9` the table of the
  services gives -22 for a lock of what is neither a directory nor a plain file.
  `rt_locking` of Windows opened the path and asked `LockFileEx` whatever it had
  opened, and `lock` and `trylock` of `NUL` returned a descriptor. It asks
  `GetFileType` before the lock now, and anything but a file on a disk is -22, the
  handle closed and the descriptor free again (`c286a5b`). The test
  `rt_lock_device` asks `rt platform` which device to name, so one test runs on
  both platforms (agent). Rejected: a test of Windows alone, for which the tests
  of AIL have no place, every test being run on Linux.

## What the review said of the fixes before
- That `lock` of AIL 0.2.2 refuses a named pipe and a device now is a change of a
  released service, taken on purpose; **the notes of the version that has the pull
  request 41 are to say it** (review). The version and its notes are the user's.

## What step 19 does, from the suggestions
- **The lock of an index stays on a descriptor** (review; taken by the agent).
  `ixlock` keeps `flock` on Linux until the runtime of AIL can lock, without
  waiting, a descriptor that was opened below a directory with no link followed.
  That service is now named among those left in AIL. It lets `ixlock` ask again
  for the same file while it waits. On Windows the open of the file of the lock
  refuses a reparse point and lets no process remove the file while the lock is
  held. Rejected: `rt trylock` of the path `.aildb/lock`, which follows a link at
  its end on Linux and looks the path up again at each try. This answers the
  question the page before left open.
- **`ixbegin` looks at the time.** When `rt time` takes the place of
  `sys clock_gettime` there, an error is no time of a run: the run ends with 4 and
  a line, and the published snapshot and its manifest stay. It is in the item of
  step 19 that moves the time, with a test.
- **A reader on Windows chooses by the file system.** It maps where a replacement
  with a reader open was shown (NTFS at build 26300) and reads into memory on the
  share of WSL and on what was not asked; both validate the same. Whether a
  published snapshot outlasts a loss of power is another item, not this one.

## What was checked
On Windows 11 Pro, build 26300, on NTFS, 2026-11-28, with the compilers of the
branch built in WSL 2: `rt_lock_device` ended with 24 with the runtime as it was,
both locks of `NUL` given, and with 31 with the change; `rt_lock`, `rt_trylock` and
`rt_become` pass there. On Ubuntu in WSL 2 `rt_lock_device` passes before and after.
The runs of the whole suites are in the pull request 41 of AIL.
