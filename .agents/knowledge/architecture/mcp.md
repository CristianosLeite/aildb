---
title: The MCP server
last-verified: 2026-11-23
sources: [conversation 2026-11-22, conversation 2026-11-23, tools/index.sh, tests/tools_index.aiw, docs/TODO.md, docs/mcp.md, mcp/src/main.aiw, mcp/tests/search.aiw, mcp/tests/lib/fake.aiw, the AIL repository (lib/std/json.aiw, lib/std/num.aiw, lib/net/http.aiw, lib/net/httpd.aiw), ail-extensions (mcp/src/mcp.aiw)]
status: current
---
# The MCP server

**Summary.** `aildb-mcp` is item 16 of `docs/TODO.md`, which a review the user added on
2026-11-22 asked for: a local, read-only server of the Model Context Protocol with a tool
`search`. It is written in AIL and spans three repositories: four libraries in AIL, the
server SDK in ail-extensions, and the program here, in `mcp/`. None of the three is
pushed or merged.

## Decisions
- **No Python; an SDK in AIL with the Rust one as the reference** (user, 2026-11-22). The
  TODO said to consider the official Python SDK; asked whether the adapter should be
  Python with the standard library alone or with that SDK, the user answered "let us
  write the SDK in AIL, use the one of Rust as the reference".
- **Where each part is** (user, 2026-11-22): "the JSON parser, decimal to double, HTTP
  client and HTTP server are native integrations of AIL. The MCP SDK is a module of
  ail-extensions". So: `lib/std/num.aiw`, `lib/std/json.aiw`, `lib/net/http.aiw` and
  `lib/net/httpd.aiw` on the branch `net-json` of AIL (its knowledge page
  `architecture/text-and-network.md`); `mcp/` on the branch `mcp` of ail-extensions.
- **The program is a nested package, `mcp/`** (agent), as `example/consumer` is: it
  needs the SDK and a newer AIL, which the engine does not, and the TODO asks for a
  process apart.
- **The command is its interface to the engine** (the TODO; agent for the how): a call
  starts `aildb search` with the vector on stdin, so a rebuilt snapshot is searched by
  the next call and nothing is reloaded. The three descriptors of the child are files
  in memory (`memfd_create`): a pipe would have to be read while the child runs, and a
  vector above the room of a pipe would block the write. No file is made on a disk.
  The worker that keeps a mapping open is left to the measurements.
- **`aildb check` once at the start** (agent), for the model: a snapshot of another
  model is status 3 before any client is answered. It reads the whole file once.
- **The server keeps no dimension** (user's item of 2026-11-22, after a local test of
  the user's: a snapshot of two dimensions replaced by one of three, and a query of
  three refused until a restart). The first form read the dimension at the start and
  compared every vector with it, which contradicted "each call opens the snapshot that
  is there". The length is now compared by `aildb search` alone, with the snapshot of
  that call, and its line is the failure of the call.
- **The hits are the lines of the command, not written anew** (agent): `score` and
  `score_bits` are the bytes `aildb search` printed, so nothing rounds a second time
  and the comparison with the command is of bytes. This is also why the JSON library
  needs no writer of doubles.
- **The vector is the bytes `example/embed.py` wrote** (the script is AIL since, `example/embed.aiw`; checked 2026-11-22): the
  decimals of the model read by `numdouble`, correctly rounded, and `f8to4`; the 3072
  bytes of a query were the same.
- **The endpoint is asked as Ollama is** (agent): `/api/embed` with `model`, `truncate`
  and `input`; the query prefix is an option, none by default, since it is a property
  of the model and of how the corpus was embedded.
- **`k` is 1 to 50, 10 by default** (agent): bounded, as the TODO asks; a result is
  read by a model.
- **A failure of the tool is a result with `isError`** (the specification), wrong
  arguments included; only an unknown tool and arguments that are no object are errors
  of the protocol, which the SDK writes.
- **The tests of what cannot be made** (2026-11-22): the commit that closes the files
  in memory of a failed start said that such a failure was not made to happen in a
  test. It can be: `mcp/tests/lib/nofile.aiw` runs a command with a limit of open
  descriptors (`RLIMIT_NOFILE`), and with six of them the server starts and a call can
  make two of its three files. The three calls of the test fail the same way; against
  the source before the fix the second failed for want of a descriptor for the
  connection to the model (error 24), the two files of the first still open.
- **`run` is a file of its own, with a test** (the review of the pull request 11, Copilot,
  2026-11-22). The fix that empties the buffers of a command's output before a run had
  no test, and its commit said why: under a limit of descriptors the first search does
  not run either. That is so for a test of the whole server, and the review named the
  way round it, a test of `run` alone. `mcp/src/run.aiw` has `arg`, `memfile`, `run` and
  `said`, and `mcp/tests/run.aiw` runs a command that prints and says a line, then
  lowers the limit of its own process: with two descriptors to be had the result is
  -2000, both buffers are empty, and two files can be made afterwards, so the two of
  the failed run were closed; against `run` as it was before the fix the buffers still
  held the 8 and 22 bytes of the first command.

## Unchecked
- Codex as the client was validated by the user, who reported on 2026-11-22 that it
  passed in full; the agent saw only a session of `codex exec` that listed the tool and
  was stopped at the approval of the call, and did not see the user's session.
  Claude Code was the client on 2026-11-22, at the user's word: `claude mcp add` in the
  local configuration of this project, "Connected", and a session that called `search`
  and opened the first hit at the revision (`docs/mcp.md`). The server is still in that
  configuration, with the index of `build/eval/`, which `make eval` makes anew and
  `make clean` removes.
- Another embedding service than Ollama, and an endpoint by name or with TLS, which the
  HTTP client of AIL has not.
- The cost of `aildb check` at the start on a large snapshot.

## Open, for the user
- The SDK has an address since 2026-11-22, when ail-extensions became a package with the
  SDK in it (the user: it still carried `ail.pin` and had no `Ailfile`); the first form, a
  package in its directory `mcp/`, had none. The user had the package merged and tagged
  `v0.1.0` the same day, and `mcp/Ailfile` names it by its address and that version, the
  revision `4493f9d` in `mcp/Ailfile.lock`.
- **The index of a repository is `make index`, a script** (agent, 2026-11-23, for the user
  to review). The user reported that the installation asks for an index that is not there
  after a clone: `docs/mcp.md` had `/path/to/repo.idx` and one sentence that pointed to the
  example, whose steps are bound to `example/corpus.pin`. `tools/index.sh REPO OUT
  [REVISION]` does those steps for any repository of git, and `make index` builds the three
  programs first; with no `REPO` it indexes aildb itself, so a clone has a file to name.
  Rejected: an index committed to the repository (a snapshot is rebuilt from sources, and
  it would be of a revision that is no longer `HEAD` after the next commit); a server that
  starts without a snapshot and fails each call (the start that fails is tested and
  documented, and the agent shows it); a command `aildb index` in the engine (the engine
  makes no embedding and does not cut files). The chunker still takes only `.aiw` and
  `.md`, which the document says; the script is a shell script as `tools/eval.sh` is, with
  a test that makes a repository with git under fixed dates and settings, so git is now
  needed by `make test` (the checkout on GitHub has it).
- **The files of a revision are written from their blobs** (the review of the pull request
  16, Copilot, 2026-11-23; agent for the how). The first form took them with `git archive`
  and listed them with `git ls-tree --name-only`, as `make example` and `tools/eval.sh` do
  for the repositories they pin. For a repository that is not known this was wrong in
  three ways: a committed symbolic link `x.md` was followed by the chunker, so a file
  outside the revision went to the embedding service; a path that is not ASCII was listed
  quoted and so passed over without a word; and `export-ignore` took files out of the
  archive that the list still named, while `export-subst` changed their text. Now
  `ls-tree` is read with modes and `core.quotePath=false`, only the modes 100644 and
  100755 are taken, and each `.aiw` and `.md` is written with `git cat-file blob`. The
  script so names the two suffixes that the chunker knows; the list has every regular
  file, so a suffix the chunker learns and the script does not have fails with "cannot
  read" and is not passed over unseen. Rejected: a checkout through a temporary index,
  which applies filters and line ends and writes links. What git still quotes (a double
  quote, a backslash, a control byte) is passed over with a line on standard error, since
  a shell cannot read names that end in NUL; the chunker would refuse the control bytes
  anyway. The example and the evaluation keep `git archive`: their repositories and
  revisions are pinned and were looked at. `make index` gives its three values to the
  shell between double quotes and finds the name of the directory there, for paths with
  spaces (the same review).
- (Settled on 2026-11-22: AIL has the version 0.1.1 for the libraries, at the user's word, and `Ailfile` and `mcp/Ailfile` ask for it; `make test` runs the test of `mcp/`.)
