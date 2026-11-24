# The embedding provider

An index of a directory is made of vectors that an embedding model gives
for texts, and a search by text needs the vector of the query from the
same model. aildb computes no embedding. It asks an **embedding
provider** for them: a program outside aildb, which the user chooses
apart from the LLM that asks the questions. This page says what a
provider is asked and what it is to answer, how an index remembers which
provider made it, and what aildb checks of an answer.

`src/lib/config.aiw` is the configuration and `src/lib/provider.aiw` the
requests, the running of the command and the reading of an answer;
[library.md](library.md) lists their functions. Two providers come with
aildb, `aildb-llama` for a model file run by llama.cpp and
`aildb-ollama` for a model that Ollama serves, and any program that
reads a request and prints an answer is a third.

## Two operations

A provider is asked for one of two things:

- **documents**: the vectors of some texts that are to be found, the
  chunks of the files of an index, several in one request;
- **query**: the vector of one text that asks, the query of a search.

They are apart because models are trained to be told which of the two a
text is. nomic-embed-text wants `search_document: ` before the one and
`search_query: ` before the other; another model takes an instruction
for queries alone, or a parameter. What is done with the operation is
the provider's, from the settings of the configuration it is sent.

## The configuration of an index

The provider of an index is configured once, when the index is made, in
the file `.aildb/config` of the indexed directory. It is text, one line
for each thing, a word, a tab and a value, and may be edited by hand,
all but its command, which is run only as you named it
([below](#which-commands-are-run)):

```
aildb	1
provider	ollama
model	nomic-embed-text
revision	0a109f422b47
dimension	768
timeout	120000
batch	32
set	document_prefix	search_document: 
set	query_prefix	search_query: 
arg	/usr/local/bin/aildb-ollama
```

| Line | Is |
|---|---|
| `aildb 1` | the first line: the version of this file |
| `provider` | a name for the provider, 1 to 255 bytes; it says whose vectors these are, not how the program is started |
| `model` | the model, 1 to 255 bytes; it is the model identifier of the snapshot ([format.md](format.md)) |
| `revision` | which weights of the model, up to 255 bytes: a digest, a tag, the name of a file. The line may be left out |
| `dimension` | the elements of a vector, 1 to 65536 |
| `timeout` | the milliseconds one request may take, 1 to 3600000; 120000 if the line is left out |
| `batch` | the most texts of one request for documents, 1 to 1024; 32 if the line is left out |
| `fingerprint` | 64 digits for the bytes of the program of the command and of the files it depends on, as they were when `aildb index` was given the options; written for a provider that was given no name with `-n`, and left out for one that was |
| `set` | a setting: a name, a tab and a value. The name is 1 to 255 bytes and is there once; the value is up to 4095 bytes and may be empty. Any number of lines |
| `arg` | an argument of the command that is the provider, up to 4095 bytes; the first is the program, a path from the root. At least one line, in their order |
| `file` | a file the command depends on, a path from the root of up to 4095 bytes, as `-f` and `-x` of `aildb index` found it. Up to 64 lines, or none |

Every value is a string as a snapshot holds one: well-formed UTF-8
without control bytes. The file ends with a line feed. Lines of the
first eight words are there once at most, in any order after the first;
the settings are written in the order of the bytes of their names,
whatever order they were given in. A file that is not this is refused
with the number of the line at fault.

## The identity of a configuration

Two vectors can be compared only if the same model made them in the same
way. The dimension does not say that: two models may share it, and one
model with another prefix gives other vectors. So a configuration has an
**identity**, 32 bytes, and vectors of two identities are never put
together: the identity names the file of kept vectors and stands in the
manifest of an index, and a configuration with another identity starts
from no vector.

The identity is the SHA-256 of this text, where `<s>` stands for the
number of bytes of a string in decimal, a colon and the bytes, and a
number is in decimal:

```
aildb-provider 3
<provider>
<model>
<revision>
<fingerprint>          empty for a provider with a name of its own
dimension
number of settings
<name><value>          one line for each setting, in the order of the names
number of arguments of the command after its program
<argument>             one line for each of them, in their order
```

each line ended by a line feed. What changes the vectors is in it: the
provider, the model, its revision, the dimension and every setting. So
are the arguments of the command after its program, because a provider
is told there what aildb cannot know to matter: `aildb-llama` takes its
model file with `-m` and gives what follows `--` to llama.cpp. An
argument that changes, a path of a model file that moved among them,
is therefore another identity, and every text is asked for again; that
costs time once, where the same vectors under two arguments that differ
would be an index of two models. What is not in it: the time and the
number of texts of a request.

**The program of the command** is in it twice, for a provider that is
given no name. Without `-n`, the name is the path of the program from
the root, as `aildb index` found it: another program at another path is
another provider, even one of the same last name, and starts from no
vector. And the line `fingerprint` is of its bytes and of the bytes of
the files named with `-f` and `-x`, as they were when the options were
given: the SHA-256 of `aildb-fingerprint 1` and, on a line each, the
digits of the SHA-256 of the program and of each of those files in
their order. So a program that was changed at its path, or a script of
it that was, is another provider the next time the options are given,
and every text is asked for again. That is the moment at which a
changed file of the indexed directory is allowed again
([below](#which-commands-are-run)), so what such a file made before it
changed is never given out as made by what it is now.

With `-n NAME` you say what the provider is, and aildb takes your word:
there is no fingerprint, and the same name, model, settings and
arguments are the same identity under whatever path and with whatever
bytes. So a provider that you move or update keeps its vectors if it
has a name, and one that you replace by another under the same name
mixes the vectors of the two, which is yours to avoid: give the other
another name. A name is 1 to 255 bytes, so a program whose path is
longer needs one.

aildb cannot see the weights a provider runs. The identity is what the
configuration **says**: a model file that was replaced under the same
path and is not named with `-f`, or a model that a service replaced
under the same name, has the same identity, and its vectors are mixed
with the old ones. The revision is the line to change then. And the
fingerprint is taken when the options are given, not for every search:
a program outside the indexed directory that an update of the system
replaced at its path stays allowed, and keeps its identity until the
options are given again.

## Which commands are run

The configuration lies in the indexed directory, and a directory may be
somebody else's: a checkout of a repository can have a `.aildb/config`
in it, whatever its `.gitignore` says. Its command would run with your
rights the first time the directory is searched by text, by you or by a
coding agent through `aildb-mcp`. So the file alone starts nothing.

A command is run only if **you named it for that directory** on this
machine: `aildb index DIRECTORY -i MODEL -d DIMENSION -- COMMAND` notes
the command, every argument of it, the file its program is and the
files you say it depends on, as allowed for the directory, in a file of
yours outside every indexed directory:

```
$XDG_CONFIG_HOME/aildb/trusted      if the variable is a path from the root
$HOME/.config/aildb/trusted         else
```

**The program is found once, when you name it.** A name without a slash
is looked for in the directories of `PATH` as they are then, and a path
that does not start at the root is taken from the directory the command
is in; the configuration gets the result, a path from the root, as the
first argument of the command. A search started later in another
directory, or with another `PATH` in which the same name is another
program, as an MCP server may be, runs the program you named. The links
of the path are not resolved in the configuration, so a program that
looks at the name it was started by sees the one you gave. A program
that is no file that can be run ends `aildb index` with status 2.

**What else the command runs or reads, you name.** aildb does not guess
which arguments are files. `-f FILE` names a file that the command
depends on, a script given to an interpreter or a model file, and `-x
PROGRAM` a program that the command runs; both are found once, like the
program of the command (`-f` from the directory the command is in, `-x`
in `PATH` if it has no slash), and the configuration gets a line `file`
with the path from the root. An argument of the command that is the same
bytes as what `-f` or `-x` was given becomes that path, so the command
is run with it whatever directory and `PATH` a search has:

```
aildb index . -i m -d 384 -f embed.py -- python3 embed.py
aildb index . -i m -d 768 -x llama-embedding -- aildb-llama -m ~/m.gguf -x llama-embedding
```

write `arg /usr/bin/python3`, `arg /home/me/project/embed.py` and `file
/home/me/project/embed.py`, and for the second `arg
/opt/llama.cpp/bin/llama-embedding` after `arg -x` with a line `file` of
the same path. Each such file is allowed as the program is: by the file
its path leads to, and by its bytes if it lies in the indexed directory.

A line of the file is the SHA-256, in 64 digits, of this text, with
`<s>` and the numbers as in the identity above, and after a tab the
directory, for whoever reads the file:

```
aildb-trust 3
<directory>
number of arguments
<argument>             one line for each, the program first
<file>                 the file the program is
file DIGITS            or a line "-"
number of files        the lines "file" of the configuration
<path>                 for each of them: its path as the line has it,
<file>                 the file that path is,
file DIGITS            or a line "-"
```

The directory is the path the kernel gives for it, from the root and
with no symbolic link in it (`/proc/self/fd`), so it is the same under
whatever name it was given. `<file>` is what the kernel gives the same
way for the program, or for a file the command depends on: the file
that would be run or read now. The line after it is `file` and the
SHA-256 of the bytes of that file if it lies below the directory, and
`-` if it does not. Before a configuration that was read
from the file is used, by `aildb index` without options and by `aildb
search --text`, the line is looked for. If it is not there, nothing of
the configuration is run and the command ends with status 2 and one line
that names the command of the file and says how to allow it, which is
to give the options yourself:

```
aildb: c: the configuration of this index names a provider that was not set up by you on this machine, or whose program or a file it depends on is no longer the file it was, and nothing of it was run. Its command is: /bin/sh -c 'touch ran'; to allow it, name the provider yourself: aildb index c -i m1 -d 8 ... -- COMMAND
```

- **What takes the permission away**: an argument of the command changed
  in the file by hand, the program among them, or a program that is no
  path from the root; a line `file` changed, added or taken out; the
  directory moved or copied; another machine or another user; a link on
  the way to the program, or to a file the command depends on, that
  leads to another file than it did, which an update of a system that
  names its programs by links can be too; such a file that is gone; and,
  for a program or a file that lies in the indexed directory, any change
  of its bytes, as a checkout of another branch makes. A file of the
  directory that is named is read whole for every search, so a model
  file of gigabytes is better kept outside it. The model, the settings, the time and the number of texts may
  be edited: they are given to the command you allowed and choose no
  program.
- **What it does not see**: the bytes of a program or a file outside
  the directory, which are yours or your system's, and a file that the
  command reads and you did not name: `-- python3 embed.py` without `-f
  embed.py` allows `python3` and the word `embed.py`, which is then read
  from the directory the search is started in, whatever it is there.
  What a named file reads in turn, a module that a script imports, is
  named too or is not seen. Between the look at a file and its use it
  can be replaced by whoever can write there.
- **Without `HOME` and `XDG_CONFIG_HOME`**, or where the kernel has no
  `/proc`, nothing is allowed and nothing can be: `aildb index` with
  options ends with status 4 before the provider is asked.
- **To take a permission back**, remove its line from the file, or the
  file.
- A program that searches a snapshot, `aildb search INDEX -q`, and the
  library run no command and look at none of this.

## The protocol, version 1

A request is one object of JSON on one line:

```
{"aildb":1,"op":"documents","model":"nomic-embed-text","revision":"0a109f422b47","dimension":768,"settings":{"document_prefix":"search_document: ","query_prefix":"search_query: "},"texts":["first text","second text"]}
```

| Member | Is |
|---|---|
| `aildb` | the version of the protocol, 1 |
| `op` | `documents` or `query` |
| `model`, `revision`, `dimension` | those of the configuration |
| `settings` | an object with a string for each setting, in the order of the names |
| `texts` | the texts, strings of well-formed UTF-8: up to `batch` of them for `documents`, exactly one for `query` |

The answer is one object of JSON:

```
{"aildb":1,"embeddings":[{"index":0,"vector":[0.013,-0.27,...]},{"index":1,"vector":[...]}]}
```

`embeddings` has one object for each text, in the order of the texts;
`index` is the place of its text in the request, from 0, and `vector`
the numbers of its vector. Blanks and other members are allowed, and the
members may stand in any order.

## What is checked of an answer

`provparse` reads an answer where it enters aildb, and an answer that
fails one check is refused whole: no vector of it is kept.

| Check | Refused as |
|---|---|
| the bytes are one object of JSON | not one object of JSON |
| `aildb` is the number 1 | not of version 1 of the protocol |
| `embeddings` is an array of objects, each with a number `index` and an array `vector` | no embeddings, each with an index and a vector |
| there are as many as there were texts | not as many vectors as there were texts |
| each `index` is the place it stands at | a vector that is not at the place of its text |
| each vector has `dimension` elements | a vector that has not the dimension of the index |
| each element is a number, and finite when it is rounded to the nearest binary32 | an element that is no finite number |
| no vector is all zeros when it is rounded | a vector that is all zeros |

The last two are what `build` asks of a vector
([format.md](format.md)), made by the same function, `normwide` of
`src/lib/norm.aiw`: a vector that passes here is one that a snapshot can
hold. A number is read as the nearest double and rounded to the nearest
binary32, a tie to the even one, as the vectors of the example are
([example.md](example.md#embeddings)). The vectors are kept as the
provider gave them; `build` and the command `index` divide them by their
norm.

The order is checked by the index of each vector and not taken on
trust, since a provider that answers a batch in another order would
give every chunk the vector of another, and nothing after it could tell.

## How a provider is run

A provider is a **command**: the lines `arg` of the configuration. For
each request aildb starts it once, directly and not through a shell, by
its path if the first argument has a slash and else found in `PATH`,
with the environment aildb was started with. The request is its stdin
and the answer what it prints on stdout; what it writes to stderr is
kept for a message. No service listens and no socket is opened by
aildb.

- **One process a request.** A request for documents has up to `batch`
  texts, so an index of many chunks is many runs of the command, one
  after the other, and a search is one. A provider that loads a model
  loads it each time. `batch` is what trades that against the size of a
  request: 32 if the configuration does not say, 1024 at most.
- **Time.** A run may take `timeout` milliseconds, 120000 if the
  configuration does not say. After that the process is killed (SIGKILL)
  and the request has failed. A provider that starts a program of its
  own is to make that program end with it, as `aildb-llama` does.
- **A provider ends with aildb.** The kernel is told to kill the
  provider when the `aildb` that started it ends (`procheld` of AIL), so
  a command that is itself killed, by `aildb-mcp` when the time of a
  call is over or by anyone, leaves no provider running. With a
  provider that holds its own program the same way, the whole chain
  ends.
- **What it reads and writes are files in memory**, not pipes: the
  request is there whole before the provider starts, and the provider
  never waits for aildb to read what it prints.
- **A run has failed** if the command could not be started, ended with a
  status other than 0, was ended by a signal or took too long; and if
  it ended with 0, if its answer is refused by a check above. A provider
  says why it failed in a line on stderr and ends with a status other
  than 0; the first line it said, 400 bytes of it at most, is put after
  the reason. What a provider says when it ends with 0 is not shown.
- **Nothing is kept of a failed request**, and no request after it is
  made: `provdocs` gives all the vectors it was asked for or none.

| Reason | Is |
|---|---|
| the provider could not be started | no such program, or one that may not be run (the status 127), or no process could be made |
| the provider ended with the status N | N is not 0 |
| the provider was ended by the signal N | |
| the provider took longer than it may | it was killed after `timeout` |
| a text that is not well-formed UTF-8 | the query, before anything is asked |

## `aildb-llama`: a model file, run by llama.cpp

```
aildb-llama -m MODEL -x PROGRAM [-- ARGUMENT...]
```

`MODEL` is a model file of llama.cpp (GGUF) and `PROGRAM` the program
`llama-embedding` of llama.cpp, by its path from the root. The adapter
looks for no program in `PATH` or in the current directory, which would
be those of each search: a name that is no path from the root, and no
`-x`, end it with status 2 and a line that says so. `aildb index` finds
the program once and writes the path, and allows the command with it:

```
aildb index DIRECTORY -i MODEL -d DIMENSION -x llama-embedding -- aildb-llama -m FILE -x llama-embedding
```

For each request the program is started once:

```
PROGRAM -m MODEL -f /dev/stdin --embd-separator SEPARATOR --embd-output-format json --embd-normalize -1 ARGUMENT...
```

Its stdin is the texts of the request, each after the value of the
setting `document_prefix` for `documents` or `query_prefix` for `query`,
if the configuration has that setting, with `SEPARATOR` between two of
them, a text that none of them has. The vectors go into the answer as
the program wrote their numbers. It is asked not to divide them by
their norm (`--embd-normalize -1`): it prints seven decimals, which are
more of a number near 1 than of one near 0.03, and aildb divides by the
norm itself. The arguments after `--` are passed on, for the threads or
the layers on a graphics card. Nothing listens anywhere: the model is
loaded for each request and gone after it.

- **`llama-embedding` is built from the sources of llama.cpp.** The
  archives of its releases do not have the program: the one of `b12676`
  (2026-11-24) has `llama-server`, `llama-cli` and others, and no
  program that prints embeddings without a server. `cmake -S . -B build`
  and `cmake --build build --target llama-embedding` in a checkout make
  `build/bin/llama-embedding`.
- **The model file** is any GGUF of an embedding model. The file that
  Ollama keeps for a model is one: the layer of the type
  `application/vnd.ollama.image.model` in the manifest of the model,
  under `~/.ollama/models/manifests/`, names it by its digest, and the
  file is `~/.ollama/models/blobs/sha256-` and that digest.
- **A text of more tokens than the program takes at once** (2048 unless
  `-b` says another number after `--`) is refused by it, and the request
  fails with its line; Ollama cuts such a text instead. A chunk of an
  index is 1500 bytes at most or one line, and a token is at least a
  byte, so it is a long query or a long line that meets this.
- **A line feed at the very end** of what the program reads is taken off
  by it, so the last text of a request loses one if it ends with one. A
  chunk does not end with a line feed.
- **The program ends when the adapter is killed**: it is started with
  `procheld` of AIL, as aildb starts a provider, with the request that
  the kernel kill it when its parent dies, so a request that takes too
  long leaves no llama.cpp behind. Where the kernel refuses that
  request, the program is not started and the adapter ends with 1.
- The status is 0, 2 for wrong usage, and 1 with a line on stderr for a
  request that is none or a program that cannot be started, fails or
  prints no embeddings; the line has the last line the program said.

A configuration for it (`aildb index` writes the file,
[usage.md](usage.md)):

```
aildb	1
provider	llama.cpp
model	nomic-embed-text-v1.5
revision	970aa74c0a90
dimension	768
set	document_prefix	search_document: 
set	query_prefix	search_query: 
arg	/usr/local/bin/aildb-llama
arg	-m
arg	/home/me/models/nomic-embed-text-v1.5.f16.gguf
arg	-x
arg	/opt/llama.cpp/build/bin/llama-embedding
file	/opt/llama.cpp/build/bin/llama-embedding
```

## `aildb-ollama`: a model that Ollama serves

```
aildb-ollama [-e ENDPOINT]
```

The texts of a request are sent to `/api/embed` of Ollama for the model
of the request, with the prefix of the operation as above and with
`truncate`, so that Ollama cuts a text that is longer than the model
reads. `ENDPOINT` is where Ollama listens, `http://` or not, an IPv4
address or `localhost`, and a port or not; without `-e` it is the
environment variable `OLLAMA_HOST`, or `http://127.0.0.1:11434`. The
vectors go into the answer as Ollama wrote their numbers. This provider
needs the service of Ollama to run; it is here for whoever has it
running already. The status is 0, 2 for wrong usage, and 1 with a line
on stderr.

`adapters/lib/ollama.aiw` is the address and the request, which
`build/embed` of the example uses too.

## A provider of your own

Any program that reads the request on stdin and prints the answer is a
provider; the line `arg` names it. In Python, with a model that
sentence-transformers runs:

```python
#!/usr/bin/env python3
import json, sys
from sentence_transformers import SentenceTransformer
request = json.load(sys.stdin)
prefix = request["settings"].get(request["op"] + "_prefix", "")
model = SentenceTransformer(request["model"])
vectors = model.encode([prefix + text for text in request["texts"]])
json.dump({"aildb": 1, "embeddings": [
    {"index": i, "vector": [float(x) for x in vector]}
    for i, vector in enumerate(vectors)]}, sys.stdout)
```

This one was not run for this page; the two above were.

## What was checked

`make test` runs the protocol without a model and without a service:
`tests/provider_command.aiw` asks `build/provider-fake`
(`tests/lib/provfake.aiw`), a provider whose vectors are the number of
bytes of a text and their sum, for five documents in requests of two and
for a query, and then a provider that answers wrongly in each way, ends
with a status, takes longer than 200 ms, is not there and is ended by a
signal. `tests/adapter_llama.aiw` runs `aildb-llama` with
`build/llama-fake` in the place of `llama-embedding`, a program that
prints in the layout the real one printed on 2026-11-24, and
`tests/adapter_ollama.aiw` runs `aildb-ollama` against the service of
the example's test. `tests/cli_index_trust.aiw` is the rule of which
commands are run, with `tests/lib_trust.aiw` for its key and its file:
among its cases a script given to `/bin/sh` and named with `-f`, which
is searched from another directory and refused once its bytes change,
and `aildb-llama` with `-x llama-embedding`, found in one `PATH` and
searched with another in which that name is a program that leaves a
file, which is not run;
`tests/kill_index.aiw` kills a run whose provider hangs and finds the
provider gone. `make dist-check` on the archive of `d07892b`
(2026-11-24, in `debian:stable-slim`, where `HOME` is `/root`) indexed
and searched a directory by text with the rule in force.

On 2026-11-24, on an Intel Core i7-12700H with Linux 7.0.0, with the
command `ail` of AIL at `d9e069e`, both adapters were given a request
for two documents by hand, with the model file of nomic-embed-text that
Ollama 0.40.17 keeps (its digest starts with `970aa74c0a90`):
`aildb-llama` with `llama-embedding` built from llama.cpp `b12676`, and
`aildb-ollama` with that Ollama. Both ended with the status 0 and an
answer of two vectors of 768 numbers with the indexes 0 and 1; with a
model file that is not there `aildb-llama` ended with 1 and the line
`main: unable to load model` of the program, and `aildb-ollama` with a
model Ollama does not have ended with 1 and its `status 404`. A program
started by `aildb-llama` was gone after the adapter was killed.
