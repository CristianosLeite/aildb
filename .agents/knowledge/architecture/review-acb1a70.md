---
title: The fix after the review of acb1a70
last-verified: 2026-11-24
sources: [conversation 2026-11-24, REVIEW.md (never part of the repository), docs/BACKLOG.md (step 17), src/index.aiw, src/lib/trust.aiw, docs/provider.md, tests/cli_index_trust.aiw, tests/lib_trust.aiw]
status: current
---
# The fix after the review of acb1a70

**Summary.** On 2026-11-24 the user gave the agent a fifth review, of the fixes of
the fourth ([page](review-b515e72.md)) at `acb1a70`, again a file `REVIEW.md` that
is no part of the repository. It found the three fixes to hold and had one finding,
marked P1, and a note on a line of an expected output that ended in a blank. The fix
is one commit of the branch `review-fixes`, `85ffb66`; what it chose was chosen by
the agent and is for the user to review.

## The file of the allowed commands is never in the directory it speaks for (P1)

- **Finding.** `trustbase` takes any `XDG_CONFIG_HOME` from the root, or
  `$HOME/.config`, and `ixtrusted` added `aildb/trusted` without looking where that
  is. A line of the file is a sum of things the directory knows, so a file in the
  indexed directory is the directory allowing itself. The placement was reproduced
  by the reviewer; the consequence followed from the lookup.
- **Decision (agent, 2026-11-24).** `trustwithin` of `src/lib/trust.aiw` says where
  a path leads against a directory: the path is opened with its links followed, and
  if it is not there, the part before its last slash, and so on; the name the
  kernel has for the part that is there is compared with the one of the directory.
  `ixtrusted` asks it for `…/aildb` and for `…/aildb/trusted` before anything is
  read or made, and a place in the directory ends the command with status 2.
- **Why the last part that is there.** What is not there yet is made below it, with
  no link in between, so it is where the file would be. The file is asked for too
  because it may be a link of its own.
- **A link to nothing.** `trustadd` opens the file with `O_CREAT` and would follow
  such a link to make its target, in a place that cannot be looked at. `trustwithin`
  answers 2 for it, "cannot be said", and nothing is allowed then, as without
  `HOME`: status 4 with options, status 2 without.
- **What it refuses besides.** `aildb index ~` with the file in `~/.config`: the
  home directory then holds its own file. The line says to set `XDG_CONFIG_HOME`
  to a directory outside. Rejected: leaving `.config` out of what is compared, since
  a file of the directory is what the rule is against, wherever it lies in it.
- **Left open.** Between the look and the use the path can be changed by whoever
  can write there, as for every file of this rule. A file outside the directory
  that somebody else can write is not looked for: its permissions are the user's.

## The line that ended in a blank

`tests/cli_index_trust.aiw` cut a line of stderr at 120 bytes, at a blank. It is cut
at 60 now, and the new cases take the blanks at the end of a cut line away.

## What was checked

`make test` with an AIL of its pull requests 33 and 34 passed: 49 tests, the
consumer and the three of `mcp`, and `git diff --check` is silent. The new cases of
`tests/cli_index_trust.aiw` were run against the command before the fix: the setup
ended with status 0 and wrote the file into the directory.
