---
title: The fixes after the review of b515e72
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), src/index.aiw, src/lib/trust.aiw, src/lib/provider.aiw, adapters/llama.aiw, docs/index.md, docs/provider.md, tests/cli_search_pending.aiw, tests/cli_index_reapprove.aiw, tests/cli_index_trust.aiw, tests/adapter_llama.aiw, tests/lib_trust.aiw, tests/lib_provider.aiw]
status: current
---
# The fixes after the review of b515e72

**Summary.** On 2026-11-24 the user gave the agent a fourth review, of the fixes of
the third ([page](review-cb9285a.md)) at `b515e72`, again a file `REVIEW.md` that is
no part of the repository. It had one finding marked P1 and two marked P2, and said
that the fixes of the directory of kept vectors and of the recovery without a second
publication held. Each fix is one commit of the branch `review-fixes`; what each
chose was chosen by the agent and is for the user to review. Where this page and
the page of the third review differ, this one is the later.

## A search ends what a killed run left before it reads the configuration (P2)

- **Finding.** `textsearch` called `ixconfig`, which reads `.aildb/config` and ends
  with status 2 if its command is not allowed, before it took the lock; `ixrecover`
  runs only with the lock. A change of the provider killed after its snapshot had
  its name left the old `config`, and with the old program gone the search never
  reached `config.new`. Reproduced by the reviewer.
- **Decision (agent, 2026-11-24).** `ixconfig`, for a process without the lock,
  first looks whether `config.new` or `manifest.new` is there (`ixpending`, two
  opens with `O_PATH`). If one is, it tries the lock once without waiting
  (`ixlock 0 1`), which runs `ixrecover`, and gives it back (`ixunlock`); then it
  reads `config`.
- **Why the lock is not waited for.** Both files are there during every run that
  changes a provider, which holds the lock for as long as its provider takes. A
  search that waited would stop answering from the snapshot that is there for all
  that time. A lock that is held means a run is at work and the files are its own;
  the search goes on as it did. What is left open: two searches that meet over the
  rest of a killed run, of which the second does not get the lock for the moment
  the first holds it and, if the old program is gone, ends with status 2 once.
- **Why the lock is given back.** A search that finds the index up to date takes no
  lock; one that had kept this lock would hold it while the provider answers the
  query and block a run for no reason.
- **What it changes besides.** `config.new` and `manifest.new` of a killed run are
  now removed by the next search too, not only by a run that takes the lock, which
  the page of the third review named as a limit. The temporary file of the
  snapshot still stays until `ixtidy`.

## The allowed line is of one configuration (P2)

- **Finding.** The key was of the command and of the bytes its files in the
  directory have now; the vectors are of the fingerprint that `config` kept.
  `ixstage` notes the line before the snapshot is published, so a run with options
  for a changed program, killed before it published, left a line under which the
  old `config` passed with the new bytes. Reproduced by the reviewer (0.809026).
- **Decision (agent, 2026-11-24).** The text of the key starts with the identity
  of the configuration, the digits of `confident`, and its first line is
  `aildb-trust 4`. The identity has the fingerprint, so the line of the run names
  the new one and the old configuration, with the old fingerprint, has another key.
- **The identity and not the fingerprint alone.** The review offered both. With the
  whole identity a line allows what the user gave, name, model, revision, dimension
  and settings too: these lines of `config` were free to edit by hand and no longer
  are; the time and the number of texts of a request still are. It was taken
  because the file lies in a directory that may be anybody's, and one rule, "the
  configuration is used as you gave it", is easier to state than a list.
- **Rejected: noting the line after publication.** The run asks the provider before
  it publishes, so the command has to be allowed before; and a line noted at the
  end would still be of the command alone.
- **What it costs.** Every line noted before allows nothing: the options are given
  once more for every index. Under `-n NAME` there is no fingerprint, so a killed
  run with the same name still allows the old configuration: the name is the
  user's word that the vectors are the same.

## aildb-llama runs a program only if aildb was told of it (P1)

- **Finding.** The adapter asked that its `-x` be a path from the root and nothing
  else. Given to the adapter alone, a program of the indexed directory was run with
  only its path, as an argument, in the allowed line. By inspection.
- **Decision (agent, 2026-11-24).** A request has a member `files`, the paths of the
  lines `file` of the configuration, and `aildb-llama` runs its program only if the
  same bytes are one of them; else status 1 and a line that names the fix. The
  review's two ways were one option for both, or a match with a declared file: the
  second was taken.
- **Why through the request.** aildb does not know which argument of a command is a
  program, and a rule for `aildb-llama` alone in `src/index.aiw` would be the
  engine knowing one provider. The request is what a provider gets from aildb, and
  the member is of use to any provider that starts something. The version of the
  protocol stays 1: a provider that reads no `files` is as it was.
- **Rejected: taking every argument that is a path of a file as declared.** A guess
  about arguments, which allows what the user did not name.
- **Not changed.** `-m` is not asked to be among the files: a model in the indexed
  directory that is not named with `-f` is still not looked at, and a relative
  `-m` is still taken from the directory of each search. It stays an open item.

## What was checked

`make test` with an AIL of its pull requests 33 and 34 passed at each commit (48
tests after the first, 49 after the others, the consumer and the three of `mcp`).
`tests/cli_search_pending.aiw` and `tests/cli_index_reapprove.aiw` were also run
against the sources before their fix and showed what the review reported: status 2
with `config.new` left, and an answer from the changed program. `make dist REV=HEAD`
and `make dist-check` passed on `b4b52aa` in `debian:stable-slim`. By hand, with
`llama-embedding` of llama.cpp `b12676` and the model file of nomic-embed-text: the
program given to the adapter alone ended `aildb index` with status 7, and the
command with both `-x` indexed two files and answered a search from another
directory with a `PATH` that names none.
