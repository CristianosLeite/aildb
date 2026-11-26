---
title: llama.cpp on a graphics card
last-verified: 2026-11-26
sources: [conversation 2026-11-26, docs/provider.md, docs/install.md, adapters/llama.aiw, llama.cpp b12676, nvcc 13.3.73]
status: current
---
# llama.cpp on a graphics card

**Summary.** The user asked whether aildb has an option to be compiled with CUDA, and
then for that option to be documented (2026-11-26). aildb has none and needs none: the
card is a matter of how `llama-embedding` of llama.cpp is built (`-DGGML_CUDA=ON`), and
`aildb-llama` runs whichever program it is given. `docs/provider.md` has the section
"On a graphics card, with CUDA" and `docs/install.md` a note in its step 2.

## Decisions

- **No option in aildb or in `aildb-llama`** (agent, 2026-11-26, for the user to
  review). The adapter already passes what follows `--` to the program, and a program
  built with CUDA uses the card with no argument. Rejected: an option `-g` of the
  adapter that would add `-ngl`, which would name one runner's flag in the interface
  and change nothing that the program does not do by itself.
- **`--device none` is the documented way to the processor, not `-ngl 0`** (agent,
  2026-11-26). The program of `b12676` built with CUDA aborts with `CUDA error: invalid
  argument` (signal 6) on a request of 32 texts with `-ngl 0`, with and without
  `-fa off`; two texts passed. It warns that a layer is on the processor while Flash
  Attention is on `CUDA0`. This is a fault of llama.cpp, not looked into further.

## What was learned

- The default of `-ngl` is `auto`: all layers go on the card.
- The vectors of the card differ from those of the processor in their last digits; the
  scores of the checked search differed by 0.0002 at most and the order did not. With
  `--device none` the program built with CUDA gave the score bits of the one built
  without.
- The identity of a configuration has the path of the program and the arguments, so a
  change of either embeds everything again. That is right here: the vectors do differ.
- One process a request means the model is loaded on the card for every search. On the
  user's machine a search of the directory `docs` was slower with the card than without
  (the shell's `time`, one run each, no figure in the documents). The first index of the
  234 chunks was about eight times faster with it.
- The second build is in `~/.local/opt/llama.cpp/build-cuda/` on the user's machine,
  beside `build/`; cmake is the one of the venv there, and `nvcc` is
  `/usr/local/cuda/bin/nvcc` (13.3.73), which is not the `nvcc` first in `PATH`
  (`/usr/bin/nvcc`, 12.4). cmake linked it to `libcudart.so.12` and `libcublas.so.12`
  of `/usr/lib/x86_64-linux-gnu`, so the compiler and the libraries are of two versions;
  it ran as it is.

## Unchecked

- Any card but the RTX 3050 Laptop GPU, any backend but CUDA (Vulkan, others), and a
  model that does not fit in the memory of the card.
- `make test` has nothing of this: it runs `aildb-llama` with `build/llama-fake`.
