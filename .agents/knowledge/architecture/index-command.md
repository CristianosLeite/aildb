---
title: The index of a directory
last-verified: 2026-11-24
sources: [conversation 2026-11-24, docs/TODO.md (step 17), docs/index.md, docs/usage.md, src/index.aiw, src/main.aiw, src/lib/tree.aiw, src/lib/run.aiw, tests/cli_index.aiw, tests/cli_index_plain.aiw, tests/lib_tree.aiw, tests/lib/dir.aiw]
status: current
---
# The index of a directory

**Summary.** `aildb index [DIRECTORY]` is the third item of step 17: the index of a
directory as it is on disk, made when the command is run and kept in `DIRECTORY/.aildb/`
(user, 2026-11-24). The step proposes the command and leaves its parts as suggestions;
what is below was chosen by the agent on 2026-11-24 and waits for the user's review,
but for the place of the index.

## Decisions
- **The provider is named by options once, and read from `.aildb/config` after that**:
  `-i`, `-d`, `-n`, `-r`, `-s NAME=VALUE`, `-t`, `-b`, and the command after `--`.
  Options given again are the whole new configuration, which is the way to another
  model. Rejected: long options for each (`--model`, `--provider-command`): the parser
  of the commands takes a letter and a value, and a command after `--` needs no quoting.
  Rejected: a subcommand that only configures; the first index would then be two
  commands.
- **A directory that was never indexed, without options, is wrong usage (2)** with a
  line that names the options, not the usage of all commands.
- **In a work tree, git lists the files**: `git ls-files -z --cached --others
  --exclude-standard`, run in the directory, so the rules of ignoring are git's own and
  a directory inside a work tree gives the files below it. Rejected: reading
  `.gitignore` here, a second reading of rules that git has many of (nested files,
  negation, `info/exclude`, the user's file).
- **Outside a work tree every file is taken, hidden ones too** (for the user to
  review): there is no rule to ask anybody for. Not decided: a way to leave paths out
  of an index, which the open item of the chunker also asks for.
- **`.aildb` and `.git` are passed over at any depth, by their names**, whoever lists.
- **A symbolic link is neither followed nor taken**, as `tools/index.sh` leaves out
  what is no regular file of git: a link can lead out of the tree, and to a directory
  that has the link in it. The file a link leads to is taken at its own path.
- **`.aildb/.gitignore` with `*`**: found in planning: without it the directory makes
  every work tree dirty to `git status`, and the revision could never be recorded. It
  is written when it is not there and never rewritten.
- **A revision only for a clean tree with the line ends of git**: `git status
  --porcelain -- .` empty and `git ls-files --eol -- .` with the same word for the
  index and the disk on every line, then `HEAD`. A clean tree alone was rejected: with
  `eol=crlf` it is clean and its bytes are not those of the commit
  (`tests/lib_tree.aiw` makes that tree). Not seen, and said in `docs/index.md`: other
  filters of git (`ident`, LFS).
- **The command is `src/index.aiw`, a part of `src/main.aiw`** (which uses it): it
  prints and exits as that file does and calls its `lock`, `publish`, `summary`. So
  the publication of a managed index is that of `build`, with its stop points and its
  syncs, and nothing of it was written again. `aildb-bench`, which compiles
  `aildb:src/main.aiw`, gets the chunker and so the package ail-extensions with it;
  its `Ailfile` is to name that package when it names a version of aildb with `index`.
- **Status 7 for a provider that failed** (for the user to review): none of 3 (the
  input is not invalid) and 4 (no file failed) says it, and a program that starts
  `aildb` is to tell a model that is not there from a disk that is full.
- **The configuration is written before the provider is asked**, under the lock: after
  options whose provider fails, `config` is the new one and `index` the old. The next
  run tries again. Rejected: writing it after the publication, which would lose the
  options of a first index whose provider is not installed yet.
- **`src/lib/run.aiw`** is the running of a program with files in memory, which the
  provider had and git needed too; `src/lib/provider.aiw` uses it now.
- **`files` and `embedded` after the members of the line of `build`** in what is
  printed.
- **A file that cannot be cut is passed over with a line and does not fail the run**,
  as in `build/chunk` without `-c`; also one that was listed and cannot be read then.
- **`aildb search [DIRECTORY] --text QUERY`** (the fifth item of the step; agent,
  2026-11-24): `--text` anywhere among the arguments makes the first one a directory.
  The step proposes this form; the search of a snapshot is `search INDEX`, and a
  directory and a file cannot be told apart by their names, so the option says which.
  `-q` and `-i` are wrong usage with it. The parser of the other options is not used:
  it takes a letter and a value, and `--text` is neither.
- **Up to date is decided without the lock and without reading a file**, by the sizes
  and times of the manifest; a search of an index that is up to date writes nothing
  and asks the provider once. The revision is not asked of git then (three more
  commands of git a search): a snapshot keeps the revision it has while its files do
  not change, which is still true of it, and `index` asks every time.
- **A search waits for a run that holds the lock** (`-w`, or the time of a request of
  the provider), looking every 50 ms, and is status 5 after that. Rejected: searching
  the snapshot that is there while another run refreshes, which answers at once and
  from files that the user has just changed; and failing at once, which makes two
  searches of one directory at one time fail for no reason.
- **The vector of a query is not kept**: one request a search.
- **`build/provider-fake` has `spread`**: its first vectors, the number and the sum of
  the bytes with 0.1 after them, all point nearly one way, so the rounding to binary32
  decides which of two records is first. Found when the test of the edit had the wrong
  file first; the engine was right, by Python. With `spread` the elements are far
  apart, and the text that is the query is first.

## Checked
- `tests/cli_index.aiw`, `tests/cli_index_plain.aiw`, `tests/lib_tree.aiw`
  (`docs/index.md`); two runs against the model on 2026-11-24, one with each adapter,
  on a clone of this repository.

## Not checked
- A work tree with submodules, with a merge that is not done, and a directory with
  more files than a test makes.
- `GIT_DIR` and `GIT_WORK_TREE` in the environment, which git obeys.
