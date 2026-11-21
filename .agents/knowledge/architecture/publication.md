---
title: How build publishes a snapshot
last-verified: 2026-11-21
sources: [src/main.aiw, src/hook.aiw, tests/lib/hook.aiw, tests/cli_build_publish.aiw, REQUIREMENTS.md, the review of 76104ec (2026-11-21, not in the repository), architecture/requirements-decisions.md]
status: current
---
# How build publishes a snapshot

**Summary.** `build` takes a lock, writes a temporary file that it created exclusively
beside the destination, syncs it, validates it with
the reader, renames it over the destination and syncs the directory, and reports a durable
snapshot only then. The places where a test must stop the program or make a sync fail are
functions of a file of hooks, of which the shipped executable has the version that does
nothing.

## Decisions
- **The order: lock, write, `fsync`, validate, `rename`, `fsync` of the directory, report**
  (`REQUIREMENTS.md`; written 2026-11-21). The lock is taken before any input is read, so a
  second build ends at once with status 5 and has touched nothing. The file is validated
  after its sync and through the reader that `check` uses, with the checksum of the
  vectors, so what gets the name is what a reader accepts.
- **The lock is a non-blocking exclusive `flock` on `<destination>.lock`** (user,
  2026-11-21), held by an open descriptor until the process ends and never removed.
  Reason for not removing it: a build that unlinks the file can do so while another has it
  open and locked, after which a third locks a new file of the same name. A killed build
  holds no lock, since the kernel drops it with the descriptor.
- **The temporary file is `<destination>.<16 hex digits>.tmp`, created with `O_EXCL`**
  (review of `76104ec`, 2026-11-21; the form is the agent's). The digits are 8 bytes of
  `getrandom`; a name that exists is tried again with others, 16 times. A failing build
  removes the file only if it created it (the var `made`), and the lines of errors name
  the destination, since the name differs in every build. This replaces a fixed name
  `<destination>.tmp` opened with `O_TRUNC`, which the review showed to destroy a
  snapshot: a build for `base` that failed cut and removed a valid snapshot `base.tmp`.
  The cost, accepted: a build that is killed leaves its file, and no later build removes
  it. Rejected: removing stale files of that form under the lock, which would again
  remove a file the build did not create; and `O_TMPFILE` with `linkat`, which needs
  `/proc` and a filesystem that has it.
- **A destination cannot end in `.lock`** (same review; status 3). A build to
  `INDEX.lock` would rename a snapshot over the file on which a build to `INDEX` holds
  its lock, and a third build would lock the new file. With the suffix refused no rename
  of aildb can replace a lock file.
- **Every failure before the rename removes the temporary file and leaves the destination
  as it was**, status 4 (or 3 for an input at fault). **A directory that cannot be synced
  after the rename is status 6**: the new snapshot is at the destination and complete, the
  line on stderr says that it may not survive a loss of power, and nothing is printed on
  stdout, where the report of a durable snapshot would stand. This is the case the design
  review notes of `REQUIREMENTS.md` ask to be specified.
- **Stop points and failing syncs are a file, not a flag** (user, 2026-11-21: stop points
  must not exist in the shipped executable; a second executable is what was meant; the
  form is the agent's). `src/main.aiw` calls `hookstop n` at three places and `hooksync fd
  n` for its two syncs. `src/hook.aiw`, compiled into `build/aildb`, has a `hookstop` with
  no line and a `hooksync` that is the `fsync`. `tests/lib/hook.aiw`, compiled into
  `build/aildb-stops`, reads the file `aildb.hook` of the current directory: `stop N`
  makes the program create `aildb.stopped` and wait to be killed at that point, `fail N`
  makes that sync return `EIO` without syncing. AIL has no conditional compilation; two
  top files that `use` the same `src/main.aiw` after different hooks give the same
  commands with nothing of the tests in the shipped one. Rejected: an environment
  variable read by the shipped executable (the stop point would exist in it), and a
  constant with `if` around the stop points (the code would still be in the file).
- **A failing write is tested on the shipped executable** with `RLIMIT_FSIZE` at 64 KiB
  and `SIGXFSZ` ignored, both of which a child inherits: the write returns `EFBIG`. No
  hook is needed for it.

- **What a killed build leaves is tested two ways** (2026-11-21, `tests/kill_build.aiw`).
  `build/aildb-stops` is stopped and killed at each stop point, as a first build and over
  an old snapshot: the destination is absent or old before the rename and new after it.
  `build/aildb` is killed at 48 moments from the start of a build to one and a half times
  its measured length, each build replacing the snapshot of the one before with one of
  another record count: what is at the destination must pass `check` and have the count
  of the old or of the new snapshot. The moments depend on the machine, so the expected
  output has only that some builds were killed, some finished and none left anything
  else; six runs in a row gave the same output.

## Unchecked
- That `fsync` and the rename do what they promise at a loss of power: no test can show
  it, and `docs/durability.md` is to state the assumptions.
- A sync that fails for a reason of the device. The tests make the hook return `EIO`; the
  code after it is the same.
- `flock` on network filesystems.
