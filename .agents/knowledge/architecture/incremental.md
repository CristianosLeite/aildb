---
title: The incremental refresh of an index
last-verified: 2026-11-24
sources: [conversation 2026-11-24, docs/TODO.md (step 17), docs/index.md, docs/durability.md, src/index.aiw, src/lib/cache.aiw, src/lib/manifest.aiw, tests/cli_index_refresh.aiw, tests/kill_index.aiw, tests/lib_cache.aiw, tests/lib_manifest.aiw]
status: current
---
# The incremental refresh of an index

**Summary.** The fourth item of step 17: `aildb index` reads only the files that
changed and asks the provider only for texts it has no vector of. Two files beside the
snapshot make that possible, `.aildb/manifest` and `.aildb/cache/<identity>`; both may
be lost. The step names them as things to consider; their layouts and rules were chosen
by the agent on 2026-11-24 and wait for the user's review.

## Decisions
- **The key of a vector is SHA-256 of the identity, `documents` and the text of the
  chunk as the chunker writes it** (the string of JSON of its line). No path and no
  line number: a move, a copy and an unchanged section of an edited file are hits.
  The JSON line and not the decoded bytes, since `fmtjson` writes one text in one way;
  if that ever changes the keys change and the texts are asked for once more.
- **One file of vectors for an identity, named by it**, so another model or setting
  cannot be given a vector of this one; the files of other identities are removed when
  a run has published. Rejected: one file with the identity in every key alone, which
  would keep the vectors of every model ever tried.
- **The file is added to after each request and written anew only at the end of a
  run** that left vectors unused. Rejected: writing the whole file after each request,
  which is the square of the number of chunks in bytes written; and never taking a
  vector out, which grows without bound.
- **A CRC-32 for each record, and no flush**: the file is not flushed to the device,
  so after a loss of power it may have blocks of anything; a record is believed only
  with its sum, and the first that fails ends the file. A vector of zeros from such a
  block would otherwise make every later publication fail.
- **The vectors are kept as the provider gave them**, not divided by their norm:
  `publish` normalizes, and the kept ones are what a provider would give again.
- **The manifest has the chunks of every file with their keys**, so a file that did
  not change is not read and not cut: a PDF file of 30 MiB is not read again because
  another file was edited. Rejected: a manifest of sizes and times alone with every
  file cut again in a run that publishes, which is simpler and reads every file.
- **A file is taken as unchanged by its size and two times only if its last change is
  older than the start of the run that wrote the manifest**; else it is read and its
  SHA-256 compared. A file changed while it was being indexed has times that say
  nothing of the bytes that were read (the problem git calls racy).
- **A file of more bytes than are ever read is not read for its sum**, and has `-` in
  its place.
- **The manifest is believed only for the snapshot it names**, by the size and the two
  CRC-32 of the header of that file, and only for the identity of the configuration.
  It is written after the snapshot is published. So a run killed between the two, a
  snapshot put there by `build` or by hand, and a manifest of another model all look
  the same to the next run, a manifest of something else, and it looks at every file
  again, with the kept vectors. Rejected: the manifest first and the snapshot after
  it, which has a moment at which the manifest describes a snapshot that is not there.
- **The state**, one SHA-256 over the paths and chunk lines of all files, the identity
  and the revision, says whether the snapshot is to be written at all. Equal states
  write no snapshot: a run over an unchanged tree changes no file of `.aildb`.
- **`index` asks git for the revision in every run**, so a commit of files that were
  indexed while they were not committed gives a snapshot with the revision.
- **The temporary files of killed runs are removed by the next run**, under the lock.
  `build` leaves such a file, since it does not own the directory of its destination;
  `.aildb` is owned.
- **Stop points 4 and 5** for the tests, before the publication and between it and the
  manifest; `hookstop` of `src/hook.aiw` does nothing with any number, and
  `tests/lib/hook.aiw` stops at the one a test names.
- **A manifest or kept vectors that cannot be written are a line on stderr, not a
  failure**: the snapshot is published, and the next run does the work again.

## Not checked
- A loss of power: the two files are not flushed, and what is said of them after one
  is reasoned, not tested.
- A directory with more chunks than a test makes; all chunks, keys and vectors of a
  run are in memory.
