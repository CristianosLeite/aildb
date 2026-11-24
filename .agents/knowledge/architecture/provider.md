---
title: The embedding provider
last-verified: 2026-11-24
sources: [conversation 2026-11-24, docs/TODO.md (step 17), docs/provider.md, src/lib/config.aiw, src/lib/provider.aiw, src/lib/sha.aiw, adapters/llama.aiw, adapters/ollama.aiw, adapters/lib/ollama.aiw, tests/lib_config.aiw, tests/lib_provider.aiw, tests/lib_sha.aiw, tests/provider_command.aiw, tests/adapter_llama.aiw, tests/adapter_ollama.aiw, llama.cpp b12676]
status: current
---
# The embedding provider

**Summary.** Step 17 of `docs/TODO.md` (user, 2026-11-24) asks for an index that the
command `aildb` makes and refreshes itself, with an embedding provider chosen apart from
the LLM. A provider is a command that is sent a request of JSON and answers one; its
configuration is the file `.aildb/config` of the indexed directory, and the SHA-256 of
what in it changes the vectors is its identity. The user approved the plan of the step on
2026-11-24 and decided two things in it; the rest below was chosen by the agent and waits
for review.

## Decisions
- **Everything of an index in `DIRECTORY/.aildb/`** (user, 2026-11-24, asked): the
  snapshot, the configuration, the manifest and the kept vectors. Rejected by the user:
  `~/.cache/aildb/<hash of the path>`, which writes nothing in the directory but loses
  the index when the directory moves; and the configuration in the tree with the data in
  the cache.
- **The runner without a socket is llama.cpp behind an adapter in AIL** (user,
  2026-11-24, asked). Rejected by the user: the protocol documented with only the adapter
  of Ollama shipped, and a Python script of sentence-transformers.
- **A provider is a command and a protocol; aildb has no HTTP in it** (agent,
  2026-11-24). Ollama and llama.cpp are programs of their own that speak the protocol, so
  the engine gets no code of the network and of tasks, and any program that reads a line
  of JSON and writes one is a provider. Rejected: the client of Ollama inside `aildb`
  beside a command adapter, two ways to the same thing in the engine.
- **Two operations, `documents` and `query`** (step 17 asks for it): the provider gets
  the operation and the settings and does with them what its model wants; aildb puts no
  prefix before a text itself.
- **The answer names the place of each vector** (agent, 2026-11-24): `{"index":i,
  "vector":[...]}`. Step 17 asks that the order be validated, and an array of bare
  vectors has no order that could be checked. Rejected: raw binary32 as the answer, which
  is shorter but which a script of a few lines cannot write as easily as JSON.
- **The identity is SHA-256 of the provider name, the model, its revision, the dimension
  and the sorted settings** (agent, 2026-11-24), each string with its length before it so
  that no two configurations give the same text. Not in it: the command and its
  arguments, the time and the number of texts of a request, which change no vector. It is
  what the configuration says, not what the provider runs: aildb cannot see weights, and
  `docs/provider.md` says so.
- **SHA-256 written here, `src/lib/sha.aiw`** (agent, 2026-11-24): the library of AIL has
  no hash, and CRC-32 has 32 bits, with which two texts would share a kept vector without
  a sign. Checked against `hashlib` of Python (`tests/lib_sha.aiw`).
- **The format of a snapshot is not changed** (agent, 2026-11-24): its model identifier
  stays the model, and the identity is in the manifest and in the name of the file of
  kept vectors. Rejected: the identity in the header, a version 2 of the format for
  something only the managed index needs.
- **`provparse` checks with `normwide`** (step 17: "reuse the engine's vector
  validation"): an answer that passes is one that `publish` cannot refuse for its
  vectors.
- **One reason for the whole answer** (agent, 2026-11-24): a batch with one bad vector
  is refused whole, and no vector of it is kept.
- **One process a request, with files in memory** (agent, 2026-11-24): the request is
  the stdin of the command and the answer its stdout, both files of `memfd_create`, and
  `procwait` with the time of the configuration ends a run that takes too long, as
  `mcp/src/run.aiw` runs `aildb search`. Rejected: one process for a whole run of aildb
  that is written to and read from over pipes, which saves the loading of a model for
  each batch but needs a read with a limit of time that the library of AIL has only for
  tasks, and `llama-embedding` is a process a run in any case. What it costs is that a
  provider which loads a model loads it for each batch; `batch` is the number to raise.
- **32 texts a request and 120000 ms, when the configuration does not say** (agent,
  2026-11-24, for the user to review); 1024 texts and 3600000 ms at most.
- **A failed request keeps nothing and ends the run** (agent, 2026-11-24): `provdocs`
  gives all vectors or none. The first line of what the provider said, 400 bytes at
  most, goes after the reason; what a provider says when it succeeds is not shown.
- **`llama-embedding` is not in the release archives of llama.cpp** (found 2026-11-24,
  `b12676`: `llama-server`, `llama-cli` and others, and nothing that prints embeddings
  without a server). The user chose llama.cpp for the runner without a socket, wrapped
  by an adapter that starts `llama-embedding`; that program is made from the sources
  (`examples/embedding`, the target `llama-embedding`), which `docs/provider.md` says.
  The agent built it at `b12676` in `~/.local/opt/llama.cpp/` of the user's machine,
  with cmake from a Python environment there, and ran the adapter against it. Rejected:
  `llama-server` on a socket of UNIX started for each request, which is a socket that
  listens. For the user to decide: whether a runner that must be built is good enough,
  or another runner is to be shipped.
- **`aildb-llama` asks for vectors that are not divided by their norm** (agent,
  2026-11-24): the program prints seven decimals, so a number near 1 keeps more digits
  than one near 0.03, and aildb normalizes.
- **The program of `aildb-llama` dies with it** (agent, 2026-11-24): the adapter forks
  itself, asks the kernel to kill the child when the parent dies (`prctl`,
  `PR_SET_PDEATHSIG`), and starts the program through `/usr/bin/env`, which looks for it
  in `PATH`; `procstart` of AIL has no place for the request between its fork and its
  exec. Checked by hand: a program that sleeps was gone after `kill -9` of the adapter.
  Rejected: a process group of the provider that aildb kills, which takes the provider
  out of the group that Ctrl-C of a terminal ends.
- **The adapters pass the numbers on as text** (agent, 2026-11-24): they copy the bytes
  of each vector into the answer, and aildb reads and checks them once.
- **`adapters/lib/ollama.aiw` is shared with `build/embed`** (agent, 2026-11-24): the
  address and the request of HTTP; `example/embed.aiw` keeps its messages, and
  `tests/example_embed.out` did not change.

## Not checked
- That two configurations of one identity give the same vectors: it is what the user
  declares.
- `aildb-llama` with a model other than nomic-embed-text, and with a text longer than
  the program takes, beyond that the program then ends with the status 1.
- The Python provider of `docs/provider.md` was not run.
