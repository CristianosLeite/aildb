---
title: The embedding provider
last-verified: 2026-11-24
sources: [conversation 2026-11-24, docs/TODO.md (step 17), docs/provider.md, src/lib/config.aiw, src/lib/provider.aiw, src/lib/sha.aiw, tests/lib_config.aiw, tests/lib_provider.aiw, tests/lib_sha.aiw]
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

## Not checked
- That two configurations of one identity give the same vectors: it is what the user
  declares.
