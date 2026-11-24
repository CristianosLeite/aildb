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
