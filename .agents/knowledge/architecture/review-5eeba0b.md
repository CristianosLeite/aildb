---
title: The fixes after the review of 5eeba0b
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), mcp/src/run.aiw, mcp/tests/run.aiw, mcp/tests/directory.aiw, src/index.aiw, docs/index.md, tests/cli_search_text.aiw, tests/lib/provfake.aiw]
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
