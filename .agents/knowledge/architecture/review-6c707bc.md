---
title: The fixes after the review of 6c707bc
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), src/lib/trust.aiw, src/index.aiw, docs/provider.md, tests/lib_trust.aiw, tests/cli_index_trust.aiw, tests/cli_index_refresh.aiw, tests/cli_index_links.aiw, src/lib/cache.aiw, docs/index.md, tests/cli_search_text.aiw, adapters/llama.aiw, the pull request 34 of AIL (880195c)]
status: current
---
# The fixes after the review of 6c707bc

**Summary.** On 2026-11-24 the user gave the agent a second review, of the fixes of
the first ([page](review-5eeba0b.md)) at `6c707bc` and of the pull requests 33 and 34
of AIL, again a file `REVIEW.md` that is no part of the repository. It had three
findings marked P1 and three marked P2. Each fix is one commit of the branch
`review-fixes`; what each chose was chosen by the agent and is for the user to review.

## The program that an allowed command runs (P1)

- **Finding.** The key of `~/.config/aildb/trusted` was of the arguments as written. A
  name without a slash is looked for in `PATH` by every run and a relative path from
  the directory of every run, so the same key could start another program; and a
  program of the checkout can change at its path with a branch.
- **Decision (agent, 2026-11-24).** `aildb index` finds the program once, as
  `procstart` of AIL would at that moment (`trustprog`), and the configuration gets
  its path from the root. The key, `aildb-trust 2`, has three things more: that the
  program is such a path (one that is not has no key), the file the path leads to as
  the kernel names it with every link resolved, and the SHA-256 of its bytes if that
  file is below the indexed directory.
- **The links of the path stay in the configuration.** A program that looks at the
  name it was started by (one of several names of one file) must see the name the user
  gave. What a link leads to is in the key instead, so a link that a checkout turns
  elsewhere is refused; the cost is that an update of a system which names a program
  by a link to a file with a version in its name asks for the options again.
- **Rejected.** The bytes of every program in the key: every update of aildb or of a
  provider would ask for the options again, against something the user's system
  already decides. The program run through its open descriptor (`execveat`), which
  closes the time between the look and the start: `procheld` of AIL takes arguments,
  not a descriptor, and whoever can write the file in that time is the user or the
  owner of the checkout acting while the search runs.
- **Not covered, and said in `docs/provider.md`.** A file the program reads, a script
  given to an interpreter among them (`-- python3 embed.py`): the key is of `python3`
  and of the argument as text. For the user to decide: whether arguments that name
  files below the indexed directory are to be in the key by their bytes too.

## Another program under the same identity (P2)

- **Finding.** The identity has the arguments after the program and not the program,
  and the name of a provider without `-n` was the last part of the path of its
  program. Two implementations of one last name at two paths were one identity: the
  second run embedded nothing and the vectors of the first answered for it.
- **Decision (agent, 2026-11-24).** The name of a provider that is given none is the
  path of its program from the root. The name is in the identity, so another path is
  another provider; the text of the identity (`aildb-provider 2`) and the file of a
  configuration do not change. Keeping the vectors across a move is what the user
  asks for with `-n NAME`: the review's "reuse across executable changes opt-in".
- **What it costs.** A provider without a name that is moved, or named once by a
  path with `./` in it and once without, asks for every text again. A name is at
  most 255 bytes, so a longer path needs `-n`.
- **Rejected.** The bytes of the program in the identity: an update of `aildb-llama`
  that changes no vector would ask for everything again. A line of the protocol in
  which a provider states an identity of its own: the review names it as another
  way; it is a change of the protocol, version 1, and of every provider written for
  it, for what `-n` already lets the user say. For the user to decide if wanted.
- **Not covered.** A program replaced under the same path, as a model file replaced
  under the same path was not: the identity is what the configuration says.

## Links in the directory of the index (P1)

- **Finding.** `src/lib/below.aiw` kept the reading of the indexed files from
  following a link, and the files of `.aildb` were still written by their names.
  A checkout with a link at `.aildb`, `.aildb/config.new` or `.aildb/manifest.new`
  had the first `aildb index` of the user write through it. Reproduced before the fix
  by `tests/cli_index_links.aiw`: the file outside held the configuration.
- **Decision (agent, 2026-11-24).** Three things together. `.aildb` is opened from
  the indexed directory with `O_NOFOLLOW` and kept open, and `ixin` makes every path
  of the index start at `/proc/self/fd/N`, so the lock, the snapshot of `publish`,
  the manifest and the cache libraries need no change to be below the directory that
  was looked at. Every name in it, and in `cache`, is looked at once before anything
  is read or written: a regular file, or the directory `cache`, or the command ends
  with status 4 naming it. And the files written to take the place of another are
  made with `O_EXCL` after an unlink, the others opened with `O_NOFOLLOW`.
- **Why the look at the names and not only the flags.** The reads (`config`,
  `manifest`, the snapshot, a file of kept vectors) are in four libraries that take a
  path; one look says of all of them that no link is there, and a user is told the
  name. The flags on the writes are for what is put there afterwards.
- **`about` of `src/main.aiw` calls `ixshow`**, which writes a path that starts at the
  descriptor as `DIRECTORY/.aildb/...`: the lines of the errors did not change.
- **Rejected.** Every file opened with `openat` from the descriptor: the reader of a
  snapshot, the manifest, the cache and `publish` all take paths, and `publish` is
  shared with `aildb build`. A refusal only of `.aildb` being a link: the review's
  second half, the staging files, is the case that wrote outside.
- **What it costs.** A system without `/proc` has no index of a directory (the rule
  of the allowed commands needed it already). Something a user put into `.aildb` that
  is no regular file ends the command until it is removed.

## A configuration that cannot be written after its snapshot (P2)

- **Finding.** The first review's fix wrote `.aildb/config` after the snapshot was
  published. A write that failed there left the new snapshot under the old
  configuration; `aildb check` named the new model, and the next search by text made
  the snapshot of the old one again.
- **Decision (agent, 2026-11-24).** The review's two halves, both. Everything that
  can fail for the configuration is done before the snapshot has its name
  (`ixstage`): the line of the allowed command, and the configuration written whole
  to `config.tmp` and renamed to `config.new`. After publication one rename is left
  (`ixcommit`). `config.new` is the journal: a run that takes the lock and finds it
  (`ixrecover`, called by `ixlockwait`) renames it to `config`, unless the manifest is
  of the snapshot that is there and names another identity, which says that the
  snapshot is still the old one; then it is removed.
- **When nothing says which configuration the snapshot is of** (no manifest of it:
  the run ended between the snapshot and the manifest, or the manifest was removed),
  `config.new` is taken. It is what the user asked for last, and after a publication
  it is the right one; in the other case the run that follows makes its snapshot.
- **A search that needs no lock** reads `config` as before; with `config.new` left
  behind its manifest names another identity, so it takes the lock, ends the change
  and reads the configuration again, which the first review's fix already did.
  A directory whose first index ended between the two has no `config`: the search
  takes the lock when it sees `config.new` and no `config`.
- **Rejected.** A directory for each generation with one link that names the active
  one, "an active generation published atomically": the snapshot is `.aildb/index`
  to `aildb-mcp -s`, to `aildb search INDEX` and to the documents, and a link there
  is what the fix above forbids. The identity in the header of a snapshot: a version
  2 of the format for what the managed index alone needs (decided with step 17).
- **The review's own case**, a directory at `config.new`, is now refused before
  anything by the look at the names of `.aildb`; the test of the write failure makes
  `.aildb` not writable instead, which a run as root would not notice.

## A child that is not held (P2, in AIL)

- **Finding.** `procheld` did not look at what `prctl(PR_SET_PDEATHSIG)` returned; under
  a filter of system calls that denies it the program ran with nothing to end it.
  `adapters/llama.aiw` had its own fork with the same gap, and looked only whether its
  parent was the process 1.
- **Decision (agent, 2026-11-24).** In AIL, the child ends with status 127 when
  `prctl` fails, as for every other failure before the exec: the second commit of its
  pull request 34 (`880195c`), with a third case of `tests/lib_proc_held.aiw` that
  denies the request with a seccomp filter (the case printed "the program was started"
  with the old code). Here, `aildb-llama` starts its program with `procheld` and has no
  fork of its own; `/usr/bin/env`, which was there to look in `PATH`, is gone, since
  `procheld` looks there.
- **What a refusal looks like.** A provider under such a filter is a command that
  ends with 127: status 7 of `aildb`, "the provider could not be started". Nothing
  says that the filter is the reason.
- **Not tested here.** That the program of `aildb-llama` ends with the adapter: by
  hand, as before.

## The version of AIL (P1)

Open as it was: the sources need the pull requests 33 and 34 of AIL, 34 now with two
commits, and `Ailfile` names 0.1.1. The version is the user's to give
(`docs/TODO.md`, `status/open-items.md`).
