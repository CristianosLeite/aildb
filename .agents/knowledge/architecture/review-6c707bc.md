---
title: The fixes after the review of 6c707bc
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), src/lib/trust.aiw, src/index.aiw, docs/provider.md, tests/lib_trust.aiw, tests/cli_index_trust.aiw]
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
