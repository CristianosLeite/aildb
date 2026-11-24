---
title: The fixes after the review of cb9285a
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), src/index.aiw, src/main.aiw, src/lib/trust.aiw, src/lib/config.aiw, adapters/llama.aiw, docs/index.md, docs/provider.md, tests/cli_index_cache.aiw, tests/cli_search_text.aiw, tests/cli_index_trust.aiw, tests/cli_index_refresh.aiw, tests/adapter_llama.aiw]
status: current
---
# The fixes after the review of cb9285a

**Summary.** On 2026-11-24 the user gave the agent a third review, of the fixes of the
second ([page](review-6c707bc.md)) at `cb9285a` and of the pull requests 33 and 34 of
AIL, again a file `REVIEW.md` that is no part of the repository, with a message that
recommended AIL 0.1.2 for the two pull requests and an explicit list of the files a
command depends on. It had one finding marked P1 and three marked P2 besides the
version of AIL. Each fix is one commit of the branch `review-fixes`; what each chose
was chosen by the agent and is for the user to review.

## The directory of the kept vectors (P2)

- **Finding.** `.aildb` was held open, but `cache` was opened to be looked at and
  closed again, and the paths of the kept vectors went through its name. A process
  that replaced `cache` during a run led the writes and the removals of the end of
  the run elsewhere; `O_NOFOLLOW` on the file is of its last part only.
- **Decision (agent, 2026-11-24).** `ixcachedir` opens `cache` from the descriptor of
  `.aildb` with `O_NOFOLLOW` and keeps the descriptor until the program ends; the path
  of the kept vectors, of the file that takes its place and of each file `ixsweep`
  removes starts at it in `/proc/self/fd`. `src/lib/cache.aiw` did not change: it
  takes a path.
- **The test is a provider.** No second process has to be timed: the provider is run
  between the look and the writes, so a script that moves `cache` away and puts a
  link there is the change at the moment that matters. On the code before the fix the
  test showed the file of vectors in the directory outside and the file that was
  there removed.

## A run that was killed after its snapshot had its name (P2)

- **Finding.** `config.new` was promoted by the next run, but the manifest was of the
  older snapshot, so that run took it for none and published the same snapshot again;
  the document said nothing was published. Reproduced by the review with a kill at
  stop 5, by the inode of the snapshot.
- **Decision (agent, 2026-11-24).** The review's first choice: a manifest tied to the
  new snapshot is staged and recovered with the configuration. The size and the two
  sums of a snapshot are known when it is whole in its temporary file, so `publish` of
  `src/main.aiw` calls `ixbefore` there, between the reading back and the rename, and
  a run of `index` writes `manifest.new`. After the rename `manifest.new` and then
  `config.new` get their names.
- **Recovery is by evidence only.** `manifest.new` of the snapshot that is there: the
  snapshot was published, it gets its name. `config.new` is taken if the manifest is
  of the snapshot and names the identity of `config.new`, and removed otherwise. The
  rule of the second review, that `config.new` is taken when no manifest says which
  configuration the snapshot is of, is gone: a first index that is killed before its
  snapshot has its name leaves a directory with no configuration, and the options are
  given again.
- **A manifest that cannot be staged ends the run** with status 4 and the snapshot
  that was there, like a configuration that cannot be written; before, a manifest
  that could not be written was a warning. A rename of `manifest.new` that fails
  after the snapshot has its name is still a warning.
- **`publish` knows of the index.** The call of `ixbefore` in `src/main.aiw` does
  nothing for `build` (`ixrun` is 0). Rejected: `publish` cut in two for the caller
  to do the rename, which moves the stop points of acceptance check 3.
- **Left as it is.** A search that finds the index fresh takes no lock, so what a
  killed run left (`config.new`, `manifest.new`, the temporary file) stays until a
  run takes the lock; the test shows both moments.

## What a command runs and reads besides its program (P1)

- **Finding.** The key bound the program of the command; `aildb-llama` still looked
  for `llama-embedding` in the `PATH` of each search, and a relative `-x` came from
  the directory of each search. With the review came the user's word on the open
  question of the second one, a script given to an interpreter: the files that affect
  execution are to be listed explicitly, found when the command is allowed, and bound
  to their bytes if they are of the checkout; which arguments are files is not to be
  guessed.
- **Decision (agent, 2026-11-24, on that word).** `aildb index -f FILE` (a file, from
  the current directory) and `-x PROGRAM` (a program, found as the shell would) name
  what the command depends on. Each becomes a line `file` of the configuration, a path
  from the root, and the key (`aildb-trust 3`) has for each what it has for the
  program. An argument of the command that is byte for byte what the option was given
  is replaced by the path: that is not a guess, the user wrote the same word twice,
  and it is what makes the script or the program the same file for every search.
- **`aildb-llama` looks for nothing.** It takes `-x` as a path from the root and
  refuses anything else with status 2, so the gap cannot be left open by leaving the
  option out; the cost is a longer first command (`-x llama-embedding` twice) and that
  the adapter cannot be run by hand with a bare name. Rejected: an operation of the
  protocol by which a provider tells aildb its files at setup, which every provider
  would have to answer and which runs the command before it is allowed.
- **A file of the directory is read for every search**, in blocks of 65536 bytes, as
  the program of the directory is: a model file of gigabytes that is named with `-f`
  and lies in the indexed directory costs that time each search; outside the directory
  only its path is looked at. Said in `docs/provider.md`.
- **Not covered.** What a named file reads in turn; the model file of `aildb-llama`
  when it is given by a relative path and not named with `-f` (it is then looked for
  from the directory of each search, and a search from elsewhere fails with status 7).
  The adapter does not refuse a relative `-m`; for the user to decide.

## Vectors of a program that changed at its path (P2)

- **Finding.** A program of the checkout that changed is refused until the options
  are given again; given again, the identity was the one it had, because the name was
  the path and the bytes were looked at for the permission only. Reproduced by the
  review: `embedded:0`, `published:false`, a text as its own query at 0.809026.
- **Decision (agent, 2026-11-24).** Both of what the review offered. A provider
  without `-n` gets a line `fingerprint` in its configuration, the SHA-256 of the
  digests of its program and of the files named with `-f` and `-x`, and the identity
  (`aildb-provider 3`) has that line. `-n NAME` is the explicit compatibility
  identifier: with it there is no fingerprint, and the user's word stands.
- **Taken when the options are given, not for every search.** The identity must be
  known to a search without reading every file of the command, and the case of the
  review is closed by it: a file of the directory cannot change without the options
  being given again, which is when the fingerprint is taken. Not closed: a program
  outside the directory that is replaced at its path (an update of the system) stays
  allowed and keeps its identity until the options are given again. Rejected: the
  bytes of every file read for every search, which for an interpreter is megabytes
  each time, and would end an index on every update of the system.
- **The paths of the files are no part of the fingerprint**, the bytes are; the path
  of the program is in the name, and the arguments, with the paths that `-f` and `-x`
  put there, are in the identity as they were.
- **Every index made before this is embedded again**: the text of the identity
  changed. No version has it.

## The version of AIL (the user's word, 2026-11-24)

- **AIL 0.1.2** is to be the version with the pull requests 33 and 34, the second
  commit of 34 (`880195c`) among them; the manifests of aildb and the installation
  guide are raised after the archive of that version is checked. On 2026-11-24 the
  two pull requests are open and no such version exists, so nothing was raised: a
  version is the user's to give, and the test on GitHub fails for the branch until
  then.

## What was checked

`make test` with a command of AIL built from the two pull requests merged: 47 tests,
the consumer, the three of `mcp/`. Three of the four fixes have a test that was run on
the code before the fix and failed there (the directory of kept vectors, the inode of
the snapshot after recovery) or that shows the reproduced case turned (every text
asked for after a program changed); the fourth has the search with another `PATH`.
`make dist REV=HEAD` and `make dist-check` in `debian:stable-slim` passed on
`b262fef`. By hand on the same day, with `llama-embedding` of llama.cpp `b12676` and
the model file of nomic-embed-text that Ollama keeps: a directory of two files indexed
with `-x llama-embedding -- aildb-llama -m FILE -x llama-embedding`, and then searched
from another directory with a `PATH` that has no directory in it, which answered.
