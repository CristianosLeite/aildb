# From nothing to a search in words

This page is the way from a machine that has nothing of aildb to a
directory that is searched in words, with the index following the files by
itself and a model that runs on the machine with no service. It needs
x86-64 Linux. The commands are those of [usage.md](usage.md); what each
part is and why is in [index.md](index.md) and [provider.md](provider.md).

## 1. aildb

Take the archive of a [release](https://github.com/CristianosLeite/aildb/releases)
that has `aildb-llama` in it, the first after 0.1.1:

```
sha256sum -c aildb-<version>-x86_64-linux.tar.gz.sha256
tar -xzf aildb-<version>-x86_64-linux.tar.gz
export PATH=$PWD/aildb-<version>-x86_64-linux:$PATH
```

It has four static executables that need nothing installed: `aildb`, the
providers `aildb-llama` and `aildb-ollama`, and `aildb-mcp`. They are put
where `PATH` finds them, or named by their whole paths below.

From the sources, with [AIL](https://github.com/CristianosLeite/ail)
0.1.1 or later installed: `ail build` in a clone makes `build/aildb`,
`build/aildb-llama` and `build/aildb-ollama`, and `ail build` in `mcp/`
makes `mcp/build/aildb-mcp`. The first build fetches the package
ail-extensions from the network.

## 2. A model, once

aildb computes no embedding; a provider does
([provider.md](provider.md)). The one that needs no service is
`aildb-llama`, which runs a model file with
[llama.cpp](https://github.com/ggml-org/llama.cpp). It takes two things,
both got once:

- **`llama-embedding`**, a program of llama.cpp. The release archives of
  llama.cpp do not have it, so it is built from its sources:

  ```
  git clone https://github.com/ggml-org/llama.cpp
  cmake -S llama.cpp -B llama.cpp/build -DCMAKE_BUILD_TYPE=Release
  cmake --build llama.cpp/build --target llama-embedding -j
  export PATH=$PWD/llama.cpp/build/bin:$PATH
  ```

- **A model file**, a GGUF of an embedding model, such as
  nomic-embed-text v1.5, of 768 dimensions. Whoever has Ollama has one
  already: the file under `~/.ollama/models/blobs/` that the manifest of
  the model names ([provider.md](provider.md#aildb-llama-a-model-file-run-by-llamacpp)).

Whoever runs Ollama anyway may use `aildb-ollama` in the place of
`aildb-llama -m FILE` below, and needs neither of the two.

## 3. Index a directory, once with its provider

```
aildb index ~/src/project -i nomic-embed-text -d 768 \
    -s 'document_prefix=search_document: ' -s 'query_prefix=search_query: ' \
    -- aildb-llama -m ~/models/nomic-embed-text-v1.5.f16.gguf
```

`-i` is the name of the model and `-d` the elements of its vectors; the
two settings are what nomic-embed-text wants before a document and before
a query, and another model has others or none; after `--` is the command
of the provider. This is said once: it is written to
`~/src/project/.aildb/config`. The command prints a line when it is done:

```
{"records":181,"dimension":768,"model":"nomic-embed-text","source_revision":"c144bb1fa5aae10891e6389d94b5587c6d5eda17","files":12,"embedded":181,"published":true}
```

The first index embeds every chunk, which with a model on the processor is
the long part; `-b` gives the texts of one run of the model, 32 without
it.

## 4. Search it in words

```
aildb search ~/src/project --text "what happens when a build is interrupted" -k 5
```

```
{"source_revision":"c144bb1fa5aae10891e6389d94b5587c6d5eda17","model":"nomic-embed-text"}
{"rank":1,"score":0.736972,"score_bits":"3fe79545cb3807ff","path":"durability.md","start_line":43,"end_line":64}
{"rank":2,"score":0.701401,"score_bits":"3fe671e146a8d847","path":"durability.md","start_line":1,"end_line":7}
```

The paths are relative to the directory. `-p` keeps the paths that start
with a prefix and `-l` the records of a language.

## 5. Nothing to do after an edit

There is no step. A search looks at the files first, and if one changed,
was added or was removed, committed or not, it makes the index what the
files are before it searches: the changed files are cut again and the
provider is asked for the texts that are new. So the search that follows
an edit finds the edit, and a search with nothing changed costs one run of
the model, for the query.

`aildb index ~/src/project`, with no option, does the same without a
search, and prints what it did.

## Where things are

Everything of the index is in `~/src/project/.aildb/`
([index.md](index.md#what-is-in-aildb)): the snapshot `index`, the
configuration `config`, the `manifest` and the kept vectors in `cache/`.
Git ignores the directory by a file in it. Nothing is written anywhere
else, nothing runs between two commands, and removing the directory
removes the index.

## Another model

The options given again are the new configuration:

```
aildb index ~/src/project -i other-model -d 1024 -- aildb-llama -m ~/models/other.gguf
```

The vectors of the old model are not used for the new one: every text is
embedded again, and the old vectors are removed when the new index is
published. The LLM that asks the questions is no part of any of this; it
can be changed without a word to aildb.

## A coding agent, if wanted

`aildb-mcp` is an adapter for a client of the Model Context Protocol
([mcp.md](mcp.md)); it runs the search above for each call. Whole paths,
since the client starts it from where it likes:

```
claude mcp add aildb -- /path/of/aildb-mcp -d /path/of/project -a /path/of/aildb
```

The provider is found as the configuration names it, so `aildb-llama`
and `llama-embedding` are to be on the `PATH` the client gives its
servers, or named by whole paths in step 3 (`-x` of `aildb-llama` names
`llama-embedding`).

## What was checked

`make dist` packs the four executables, and `make dist-check` unpacks the
archive in a container of `debian:stable-slim` that has no AIL, no git
and no network, and there indexes a directory of two files, searches it
by text, writes a third file and searches again, which finds it, makes
the same search through `aildb-mcp`, and starts the two providers. The
provider of that check is a script of four lines, since the container has
no model. On 2026-11-24 the archive of the commit `c144bb1` printed there
what `tools/dist-check.sh` expects.

On the same day, on an Intel Core i7-12700H with Linux 7.0.0, the four
executables of that archive, built by AIL at `d9e069e`, were unpacked and
put on `PATH`, with `llama-embedding` built from llama.cpp `b12676` and
the model file of nomic-embed-text that Ollama 0.40.17 keeps. The
directory `docs` of a clone of this repository was indexed by the command
of step 3, which printed the line shown there; the search of step 4
printed the lines shown there; a section of three lines added to
`usage.md` without a commit was the first result of the next search, at
its lines 321 to 323 and with no revision named; and `aildb index` after
it printed `"embedded":0,"published":false`. Steps 1 and 2 as they are
written, with an archive of a release and a model file that is
downloaded, were not run: no release has the archive yet.
