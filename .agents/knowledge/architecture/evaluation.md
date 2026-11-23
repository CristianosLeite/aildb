---
title: The retrieval evaluation
last-verified: 2026-11-22
sources: [conversation 2026-11-22, docs/evaluation.md, docs/TODO.md, example/eval.aiw, tools/eval.sh, example/eval/, tests/example_eval.aiw, architecture/example.md]
status: current
---
# The retrieval evaluation

**Summary.** `make eval` measures how well queries in words find their lines, which the
example does not: twenty fixed queries on two corpora, the place of each among all
records, the hit rate at 1, 5 and 10 and the mean reciprocal rank. It was item 15 of
`docs/TODO.md`, which a review the user added on 2026-11-22 asked for. No comparison of
chunk sizes or models was run.

## Decisions
- **The corpora are AIL at `a5b4559` and aildb at `v0.1.0`** (user, 2026-11-22, of three
  choices; ail-bench as a third was not taken). The chunker cuts `.aiw` and `.md` only, so
  a repository in another language has almost nothing to index.
- **The ten queries of `ail` are those written for the example before its first run**
  (the item of the TODO), the four that were taken out of the example included; their
  text, paths and lines were never committed and come from the table of
  `docs/example.md`.
- **The ten queries of `aildb` were committed before they were embedded** (agent,
  2026-11-22; commit `d48f4a7`), and none was changed after the run, also not the two
  that came at the places 27 and 21. A query that is reworded until its record comes
  first measures the rewording.
- **The place is looked for among all records** (agent): `search -k 4294967295`, the
  largest limit, which costs nothing more than the records there are. The check of the
  example asks for five and cannot say at which place a miss is.
- **A query without a place counts as 0 in the mean reciprocal rank** (agent), and is
  counted apart; none of the twenty is one, since each expected line is in a chunk.
- **The dimension is what the vectors have for each query** (agent), not a constant as
  in `example/check.aiw`, so that another model needs no change of the program.
- **`make eval` does not fail for a bad place** (agent): it measures. The example is
  the check, with its six queries, and is unchanged.
- **`embed model`** (agent; `embed.py model` until the script was rewritten in AIL) prints the version of Ollama and the digest of the model
  for the report, which the item asked to be recorded.

## What the run showed (2026-11-22, `docs/evaluation.md`)
- `ail`: 3, 6 and 7 of 10 in the first 1, 5 and 10; mean reciprocal rank 0.4517. The
  ten places are those of the run of the example on 2026-11-21.
- `aildb`: 7, 8 and 8 of 10; 0.7418.

## Unchecked
- Chunk sizes, overlap, the path in the embedded text and other models: an item of
  `docs/TODO.md`. The plan of the conversation had `make eval` take the model and the
  limits of a chunk as variables; that was left to the item, with the comparison.
- Queries by someone who did not write the sources, and a repository of another author.
