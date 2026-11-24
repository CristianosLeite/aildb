---
title: The fixes after the review of 5eeba0b
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), mcp/src/run.aiw, mcp/tests/run.aiw, mcp/tests/directory.aiw, src/index.aiw, docs/index.md, tests/cli_search_text.aiw, tests/lib/provfake.aiw, src/lib/config.aiw, src/lib/below.aiw, src/lib/run.aiw, src/lib/trust.aiw, docs/provider.md, tests/cli_index_trust.aiw, the pull request 34 of AIL]
status: current
---
# The fixes after the review of 5eeba0b

**Summary.** On 2026-11-24 the user gave the agent a review of step 17 at `5eeba0b`
(and of the pull request 33 of AIL), a file `REVIEW.md` that is no part of the
repository, as the review of `76104ec` was not. It had four findings marked P1 and
four marked P2. Each fix is one commit of the branch `review-fixes`; what each chose
was chosen by the agent and is for the user to review.

## The arguments of the command in `aildb-mcp` (P1)

- **Finding.** `arg` of `mcp/src/run.aiw` copied each argument into 8192 bytes
  without a look at the room. With `-d` the limits of each value (a command of 1000
  bytes, a directory of 2000, a query of 4000, a prefix of 2000, a language of 255)
  add up to 9286.
- **Decision (agent, 2026-11-24).** The room stays 8192 bytes and is checked: `arg`
  adds nothing that has no room, in the bytes or in the 12 places of addresses, and
  notes it; `run` then starts nothing and gives -3000, which the tool turns into a
  failure of the call. The argument 0 starts a command, so a command after one that
  had no room is run.
- **Rejected.** A buffer that grows: the addresses of the arguments would move, and
  the limits of each value already bound what a call can ask for. Lower limits for
  each value so that they always fit: a long query alone is a use that has a reason.

## A change of the provider that fails (P1)

- **Finding.** `aildb index` with options wrote `.aildb/config` first and asked the
  provider afterwards. A provider that failed left the old snapshot under the new
  configuration, and every search by text failed with status 7.
- **Decision (agent, 2026-11-24).** The configuration of the options stays in memory
  for the run and is written by `ixcommit`, to `config.new` and renamed, right after the
  snapshot has its name and before the manifest is written, or when the state did not
  change and no snapshot is written. A run that fails or is killed before that leaves
  `config`, `index` and `manifest` as they were. A first index that fails leaves no
  configuration, so the directory still counts as never indexed.
- **The window that is left.** Killed between the rename of the snapshot and the
  rename of the configuration, a directory has the new snapshot and the old
  configuration. The manifest is still the old one and is not of the snapshot, so the
  next run, a search too, makes a snapshot of the old configuration again; the vectors
  of the old identity are still kept then, since the sweep comes last.
- **Rejected.** One rename for both, a directory of a generation that holds snapshot
  and configuration: it changes where the snapshot is, which `aildb-mcp -s` and other
  readers are given as a path.
- **Tests.** They made a configuration without a snapshot by a run with the fault
  `exit3` and took the fault out of `config` with `sed`. That gives no configuration
  now: they index and remove the snapshot, and faults that come and go are words of a
  file `provider.fault` that `build/provider-fake` reads beside its arguments.

## A search that waited for the lock (P2)

- **Finding.** `textsearch` read the configuration, found the index stale, waited for
  the lock, and refreshed with what it had read. Behind a run that changed the provider
  it published a snapshot of the old model while `config` named the new one. Reproduced
  in the test before the fix: the log of the provider had `documents 8 m2` and
  `query 1 m2` after the run of `m3`.
- **Decision (agent, 2026-11-24).** With the lock, the configuration is read again and
  `ixfresh` is asked again; the refresh runs only if the index is still stale. So a
  search that waited for a run of the same files does no run of its own any more,
  which is also less work.
- **The path without the lock** needs nothing: `ixmanifest` opens the snapshot only
  if the manifest has the identity of the configuration in memory and the size and the
  sums of the snapshot, so the three are of one another or the search goes to the lock.
- **Test.** `build/provider-fake` has the word `slow`: the first request makes a file
  `provider.started` and waits a second. The test starts the run that changes the
  model, waits for that file and searches; a search that came too late for the lock
  would print the same, so the test cannot fail by timing, only not show the fault.

## Arguments of the provider that change the vectors (P2)

- **Finding.** The identity had the name of the provider, the model, the revision,
  the dimension and the settings, and nothing of the command, "so that a program moved
  to another path keeps the index". But `aildb-llama` is given the model file (`-m`)
  and the options of llama.cpp (after `--`) as arguments, so a change of them kept the
  vectors and the snapshot of the arguments before.
- **Decision (agent, 2026-11-24).** The arguments of the command after its program
  are in the identity, in their order, each with its length; the text of the identity
  starts `aildb-provider 2`. The program, the first argument, stays out. The review
  offered this or an identity that the provider states itself; this one needs no
  change of the protocol and no provider that knows which of its options matter.
- **What it costs.** An argument that does not change the vectors, `-x` of
  `aildb-llama` or a model file that moved, asks for every text once more. There is no
  way to say "the same vectors" yet; the review names one as a later addition, and it
  is the user's to ask for.
- **Still declared, not verified.** A model file replaced under its path has the
  same identity; the revision is the line for it, as before.
- **Checked.** The eleven identities of `tests/lib_config.aiw` are those `hashlib` of
  Python gives for the text of `docs/provider.md` (2026-11-24).

## A symbolic link before the last part of a path (P2)

- **Finding.** `AT_SYMLINK_NOFOLLOW` of `treestat` holds for the last part of a path
  only. `git ls-files --cached` names a file by the path it had, so after `sub` became
  a link to a directory outside, `sub/b.py` was a regular file to `treestat` and was
  read from outside. The read was by name too, after the look, so a file replaced in
  between was read as whatever it had become.
- **Decision (agent, 2026-11-24).** `src/lib/below.aiw`, `belowopen`: the directory is
  opened as it is named, and each part of the path from the one before it with
  `openat` and `O_NOFOLLOW` (`O_PATH` and `O_DIRECTORY` on the way). `treestat` asks
  `fstat` of that descriptor; the sum of a file in `src/index.aiw` and
  `chunkreadmax` of the chunker read a descriptor opened the same way, with
  `O_NONBLOCK` and a check that it is a regular file. A file that fails this is not
  taken, like one that is gone.
- **Rejected.** `openat2` with `RESOLVE_NO_SYMLINKS` and `RESOLVE_BENEATH`: one call
  instead of one a part, but Linux 5.6 or later and a filter of system calls that lets
  it through, which the container of `make dist-check` need not have. A part `..` is
  refused instead of resolved, because going up from a descriptor can leave the
  directory when a directory is moved meanwhile.
- **Not changed.** The walk of a directory that is no work tree lists a directory by
  its name; what it lists is then looked at part by part, so names from a directory
  that was swapped for a link are refused one by one. `chunkcorpus`, the `-c` of
  `build/chunk` for the corpora of the example, reads by name as it did: its files are
  an archive of a revision that the scripts unpack.

## A provider left running after a timeout (P2)

- **Finding.** `aildb-mcp` waits for `aildb` with `procwait`, which kills that process
  when the time is over and nothing below it. The provider that `aildb` had started
  went on, a model loaded, until it was done or for ever.
- **Decision (agent, 2026-11-24).** The provider, and git, are started so that the
  kernel kills them when `aildb` ends (`PR_SET_PDEATHSIG`). That has to be done in the
  child between `fork` and `exec`, which `procstart` of AIL leaves no room for, and it is
  of use to any program, so it is `procheld` in `lib/std/proc.aiw` of AIL (its pull
  request 34), after the user's word that such things belong there. `aildb-llama`
  already held `llama-embedding` this way with code of its own, so the chain from the
  server to the model ends.
- **Rejected.** A process group for the call that the server kills: the command would
  have to leave the group of its terminal when a person runs it, or be told by an
  option that it runs under the server.
- **Not done.** `aildb-mcp` does not hold `aildb` itself: its tool runs on a task, and
  the kernel ties the child to the thread that started it, so a thread of the pool that
  ended would take a search with it. A server that is killed leaves the command to
  finish its call, within the time of the provider.
- **A consequence.** This branch needs two things of AIL that are in no version: the
  pull requests 33 (SHA-256) and 34. It is tested with a command built from both.

## A checkout that names the command to run (P1)

- **Finding.** The command of the provider is in `DIRECTORY/.aildb/config`. The
  `.gitignore` that `aildb index` writes keeps git from adding the directory, but a
  repository can have the file tracked all the same, and then the first search by text
  in a checkout, which a client of `aildb-mcp -d` can cause, runs a command that the
  repository chose, with the rights and the environment of the user.
- **Decision (agent, 2026-11-24).** The configuration stays where the user put it
  (2026-11-24: everything of an index in `.aildb/`), and a command is run only with a
  record of the user's own: `aildb index` with options, which is the user naming the
  command, adds a line to `aildb/trusted` under `XDG_CONFIG_HOME` or `~/.config`, the
  SHA-256 of the directory and every argument. A configuration that was read from the
  file is checked against it in `ixconfig`, before anything of it is used, and again
  when a search reads it a second time with the lock. Not allowed is status 2, the
  status of a directory that was never indexed, with a line that names the command.
- **Why the directory is in the key.** A command with a relative path, `sh
  ./provider.sh`, allowed for one directory would else be allowed in any checkout that
  has a file of that name. The directory is the name the kernel gives a descriptor of
  it in `/proc/self/fd`, so links in the name given do not matter; where there is no
  `/proc`, nothing is allowed.
- **Why the whole command and not the identity.** The model, the settings, the time
  and the number of texts are data for the command the user allowed; only the
  arguments choose what is run.
- **Rejected.** The command in a file of the user in place of the lines `arg` of
  `.aildb/config`: the same record, and a change of the layout the user chose. A
  question on the terminal: the command runs under a server and in scripts. An option
  that allows what the file has without naming it: the user would allow what they did
  not read; the line of the refusal shows the command, and the options are typed.
- **What it costs.** A directory that is moved or copied, and a clone on another
  machine, need the options once more. The record is written when the configuration is
  (`ixcommit`), and a run with options ends with status 4 before it asks the provider
  if there is nowhere to write it.
- **Tests** set `XDG_CONFIG_HOME` to a directory of the test (`tests/lib/dir.aiw`,
  `mcp/tests/directory.aiw`), so nothing is written in the home of whoever runs them.

## The AIL that the manifest asks for (P1)

- **Finding.** `Ailfile` says `ail 0.1.1` and the sources use `lib/std/sha.aiw`, which
  no version of AIL has; `make test` on GitHub installs that version and cannot pass.
- **Not fixed here, and why.** It is fixed by a version of AIL, which is the user's to
  give: the pull requests 33 (SHA-256) and, since this review, 34 (`procheld`) of AIL
  merged and released, then the lines `ail` of `Ailfile` and `mcp/Ailfile` raised and
  `docs/install.md` with them. Until then the branch is tested with a command built
  from the two branches of AIL ([open items](../status/open-items.md)).
