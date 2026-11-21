# Durability

What `aildb build` promises about a snapshot when a process is interrupted,
and what it assumes of the filesystem and the storage when power is lost.
The two are kept apart: the first is shown by tests, the second cannot be
shown by a test that runs on a working machine and is a list of
assumptions.

## What build does

1. It takes an exclusive lock (`flock`, non-blocking) on `INDEX.lock`, a
   file beside the destination that it makes if needed and never removes.
2. It creates a temporary file in the same directory, `INDEX.`, sixteen
   random hexadecimal digits and `.tmp`, with `O_EXCL`, so that it is a
   new file and no file that was there, and writes the whole snapshot to
   it.
3. It flushes that file (`fsync`) and closes it.
4. It opens the file again and validates it as `check` does, the checksum
   of the vectors included.
5. It renames the temporary file to `INDEX` (`rename`), which replaces a
   snapshot that is there.
6. It flushes the directory (`fsync` on the directory).
7. It prints its line on standard output and ends with status 0.

A failure in steps 1 to 5 ends the build with a line on standard error and
status 4 or 5 (3 if an input was at fault); the temporary file, if this
build created one, is removed, no other file is, and `INDEX` is what it
was. A failure in step 6 ends it with status 6: `INDEX` is the new
snapshot, and nothing was printed on standard output. A failure in step 7,
the output closed or full, ends it with status 4 and a line on standard
error that says the snapshot was published and synced: `INDEX` is the new
snapshot, as durable as after a status 0.

A published snapshot is never written again. A reader maps the file it
opened and keeps that file when the name is given to another one.

No name that `build` uses beside a destination can be taken from it by
another build. A destination cannot end in `.lock`, so no snapshot is
renamed over a lock that is held, which would let a third build lock the
new file. A temporary file is never one that was there, so a snapshot that
has the name of one, old or new, is not touched.

## When a process is interrupted

This is what `tests/kill_build.aiw` establishes. It stops a build at three
points, with the temporary file begun, before the rename and after it, and
kills it there, as a first build and over an old snapshot; and it kills the
shipped executable at 48 moments spread over the time of a build:

- Killed before the rename: `INDEX` is absent if it was absent, and else the
  old snapshot, complete. The temporary file of the killed build may be
  left, with any contents. Nothing reads it and no build removes it: it
  is for whoever killed the build to remove, when no build is running for
  that destination.
- Killed after the rename: `INDEX` is the new snapshot, complete.
- There is no moment at which `INDEX` names a file that is partly written,
  since the name is only ever given to a file that was complete, flushed and
  validated.
- The lock of a killed build is gone with its process. `INDEX.lock` stays
  and means nothing by being there.

A process being killed is not a loss of power: the kernel still has every
byte that was written, flushed or not. These tests say nothing about the
next section.

## When power is lost

None of the following was tested by cutting power. A snapshot survives a
loss of power, in the state the list above gives, if all of it holds:

- **`fsync` means what it says.** When `fsync` of a file returns 0, its data
  and its size are on the device and stay there without power. This needs a
  device that honours the request to flush its cache. A drive or controller
  that acknowledges a flush it has not done (some consumer drives, a USB
  stick, a virtual disk configured to ignore flushes) breaks every promise
  here, and nothing in aildb can detect it.
- **`rename` within a directory is atomic.** After a crash the name `INDEX`
  refers either to the old file or to the new one, never to neither and
  never to a mixture. POSIX asks this of a running system; for a crash it is
  a property of the filesystem. The journaling filesystems of Linux (ext4,
  XFS, btrfs) have it for a file whose data was flushed before the rename,
  which is the reason for step 3.
- **`fsync` of a directory makes the rename durable.** Until step 6 has
  returned, a crash may bring the old name back: `INDEX` is then the old
  snapshot, or absent after a first build, which is a valid outcome but not
  the one that was reported. This is why the line on standard output comes
  after step 6, and why a failure of step 6 has a status of its own: the
  caller knows that the new snapshot is in place and that it may not last.
  Running `build` again is the remedy.
- **A failed `fsync` is final.** On Linux an error of `fsync` is reported
  once and the pages that could not be written may be dropped, so a second
  `fsync` that returns 0 proves nothing. `build` never retries one: it
  removes the temporary file and fails. [Linux `fsync`
  documentation](https://man7.org/linux/man-pages/man2/fsync.2.html)
- **The filesystem is local.** `flock` is not reliable on every network
  filesystem, where two builds might both believe they hold the lock; the
  atomicity of `rename` and the meaning of `fsync` over a network depend on
  the server. Build on a local filesystem; a finished snapshot may be copied
  anywhere, since it is one file with no path in it.
- **The temporary file and the destination are in one filesystem.** They
  are in one directory by construction, so `rename` never has to copy.

What a loss of power may leave behind even if all of it holds: a temporary
file with any contents, and `INDEX.lock`. Both are harmless. The lock file
stays; the temporary file is not cleaned up by a later build and can be
removed by hand.

## What a reader assumes

- **A snapshot does not change where it lies.** `search` and `check` map the
  file. If another program truncates or rewrites that file, a reader may be
  killed by `SIGBUS` or score bytes that are no longer the vectors it
  validated. `build` never does this; only a program that writes to `INDEX`
  directly would.
- **An I/O error on a mapped page is `SIGBUS`**, not a return value: the
  reader ends without a diagnostic of its own. This is the cost of reading
  through a mapping, accepted with that decision.
- **Damage that happens after the snapshot was written is found by the
  checksums, within their limits.** Every command verifies the CRC-32 of the
  header and metadata; only `check` verifies that of the vectors
  ([format.md](format.md#integrity-checks)). A caller who must know that the
  vectors are intact runs `check`.

## What this was run on

The tests ran on ext4 on an NVMe drive, on Linux 7.0. That shows the
sequence of calls and what a killed process leaves; it shows nothing about
the assumptions of a loss of power, which hold or fail with the filesystem
and the device of whoever builds.
