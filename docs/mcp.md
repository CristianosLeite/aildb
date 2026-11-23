# aildb for a coding agent: the MCP server

`aildb-mcp` lets a coding agent, such as Claude Code or Codex, search a
snapshot in words. It is a server of the [Model Context
Protocol](https://modelcontextprotocol.io) (revision 2025-11-25) over
stdin and stdout, a program apart from `aildb`, in the directory `mcp/`.
It reads a snapshot and writes nothing: a snapshot is still made and
published by `aildb build`.

```
aildb-mcp -s SNAPSHOT -i MODEL -e ENDPOINT [-a AILDB] [-p PREFIX] [-t MS]
```

- `-s SNAPSHOT`: the file that `aildb build` publishes.
- `-i MODEL`: the identifier of the embedding model the snapshot was built
  with. It is sent to the model's service as the model to ask and given
  to `aildb search -i`, which searches nothing if the snapshot is of
  another.
- `-e ENDPOINT`: where the model is asked for the vector of a query:
  `http://`, an IPv4 address or `localhost`, a port and a path, as
  `http://127.0.0.1:11434`. Without a path it is `/api/embed`. The
  request and the answer are those of [Ollama](https://ollama.com): a
  POST of `{"model":MODEL,"truncate":true,"input":[TEXT]}`, answered by
  an object whose `embeddings` is an array with one array of numbers.
- `-a AILDB`: the command of aildb; `aildb`, looked for on `PATH`, if it
  is not given.
- `-p PREFIX`: what stands before the text of a query when it is sent to
  the model, for a model that is told what a text is for. For
  nomic-embed-text, as [the example](example.md) indexes with it, this is
  `"search_query: "`. None if it is not given.
- `-t MS`: the milliseconds the model may take for an answer, from the
  connection to the last byte of it, and the search for its results;
  30000 if it is not given.

When it starts, the server runs `aildb check SNAPSHOT` once and ends
with status 3 if the snapshot is invalid, cannot be
read or is of another model than `MODEL`, with status 2 for wrong usage
and 4 if the command of aildb cannot be run, each with a line on standard
error. It then answers until its input ends, status 0. Standard output
has the messages of the protocol and nothing else.

## The tool `search`

| Argument | Is |
|---|---|
| `query` | a string, what to look for in words; required |
| `k` | the largest number of results, 1 to 50; 10 if it is not given |
| `path_prefix` | only records whose path starts with these bytes, the `-p` of `aildb search` |
| `language` | only records of this language, its `-l` |

For a call the server sends `PREFIX` and the query to the model, rounds
each number of the answer to the nearest binary32 and starts `aildb search SNAPSHOT -k K -i
MODEL`, with the filters if they are given, without a shell and with the
vector on its standard input. The result is an object, sent as
`structuredContent` and as text:

```
{"model":"nomic-embed-text","source_revision":"a5b4559c2cffbef49538a668579a3820d5e16da5","hits":[{"rank":1,"score":0.787872,"score_bits":"3fe9363ff52df4a6","path":"lib/std/io.aiw","start_line":57,"end_line":68}]}
```

`model` and `source_revision` are those of the snapshot (`null` if it has
no revision), and a hit is a line of `aildb search` as it was printed
([usage.md](usage.md#search)): the paths and lines are of the sources at
`source_revision`, which is the revision to open them at. A filter that
takes no record gives `"hits":[]`.

A failure is a result with `isError` and a sentence, not an error of the
protocol: an argument of the wrong kind or out of range, a model that
cannot be reached, refuses or answers with no vector, an answer or a
search that takes longer than `MS`, and whatever `aildb search` said when
it did not end with status 0: a snapshot that is gone or damaged, and a
vector that is not of the dimension of the snapshot.

**A call starts the command anew**, so each search opens the snapshot
that is at the path then: after `aildb build` has published another one,
the next call searches it, with nothing to reload. The server keeps
nothing of the snapshot it started with, also not its dimension: the
length of a vector is compared by `aildb search` with the snapshot it
opens, so a snapshot of the same model and another dimension is searched
with vectors of that dimension from the next call on. The cost is a process
a query, which [performance.md](performance.md) measures.

## Building it

`mcp/` is a package of AIL of its own. It needs an AIL that has
`lib/std/json.aiw`, `lib/std/num.aiw` and `lib/net/http.aiw`, which the
version 0.1.1 of AIL is the first to have and `mcp/Ailfile` asks for, and
the server SDK, the module `mcp` of
the package [ail-extensions](https://github.com/CristianosLeite/ail-extensions),
which `mcp/Ailfile` names by its address and the version 0.1.1, with the
revision in `mcp/Ailfile.lock`; the first build fetches it into
`mcp/deps/` with git:

```
make                  # build/aildb
cd mcp && ail build   # mcp/build/aildb-mcp
make mcp-test         # its test, with the build/aildb above; make test runs it too
```

## In Claude Code and in Codex

The server searches an index, and a clone of this repository has none:
an index is built from sources and is no file of the repository. So it
is made first, and the server is started with its path. From a clone,
with [Ollama](https://ollama.com) running:

```
ollama pull nomic-embed-text
make                                  # build/aildb
(cd mcp && ail build)                 # mcp/build/aildb-mcp
make index REPO=/path/to/repository   # build/index/<its directory>.idx
```

`make index` writes the index of the git repository in the directory
`REPO` at its `HEAD`, or at the revision `AT=`, into
`build/index/<name of the directory>.idx`, or the file `IDX=`. Without
`REPO` it indexes aildb itself, into `build/index/aildb.idx`. It is
`tools/index.sh REPO OUT [REVISION]`, the steps of [the
example](example.md) for a repository of one's own: the files of the
revision are cut into chunks, nomic-embed-text gives their vectors, and
`aildb build -r` publishes the index with the whole name of the
revision. Two things follow from those steps:

- The chunker takes the sources of AIL (`.aiw`) and Markdown (`.md`) and
  passes over every other file, so of a repository in another language
  its documents are indexed. A revision with neither is an error.
- The index is of a revision: a change that is not committed is not in
  it. `make index` again, after a commit, replaces the file as `aildb
  build` does, and the next call of the tool searches the new one, with
  the server left running.

Then the server is added with the paths of the two executables and of
the index, each a whole path, since the agent starts the server in a
directory of its own choice. In the clone:

```
claude mcp add aildb -- $PWD/mcp/build/aildb-mcp -s $PWD/build/index/<name>.idx \
    -i nomic-embed-text -e http://127.0.0.1:11434 -a $PWD/build/aildb -p "search_query: "
codex mcp add aildb -- $PWD/mcp/build/aildb-mcp -s $PWD/build/index/<name>.idx \
    -i nomic-embed-text -e http://127.0.0.1:11434 -a $PWD/build/aildb -p "search_query: "
```

The agent then has the tool `search` of the server `aildb`. A server
that is named an index that is not there ends when it starts, with
status 3 and the line `aildb-mcp: aildb: <path>: cannot open: no such
file or directory`, and the agent shows it as failed.

## What was checked

`mcp/tests/search.aiw` runs the server between a client written as lines,
an embedding service that answers from a table (`mcp/tests/lib/fake.aiw`,
on the HTTP server of AIL) and `build/aildb`, on a snapshot of three
records: the discovery of the tool, calls whose hits are the lines that
`aildb search` prints for the same vectors (ranks, both filters and
`score_bits`), no result, wrong arguments, a model that refuses, answers
with what is no vector or one of three dimensions, answers too late or is
not there, a snapshot replaced between two calls, then replaced by one of
three dimensions, for which the vector of three is taken and the one of
two refused, a snapshot that is gone, and starts that fail.

`tests/tools_index.aiw` runs `tools/index.sh` on a repository that it
makes, with an embedding service in place of Ollama
(`tests/lib/embedfake.aiw`): the index of `HEAD` has a record for each
chunk and the name of the revision that `git rev-parse` prints, a second
commit replaces it and a file that is not committed is not in it, an
older revision is indexed by its name, and a revision or a repository
that is not there, a repository with nothing to index and a service that
is gone leave the index as it was.

Against the model itself, on 2026-11-23 (Ollama 0.40.17,
nomic-embed-text F16, digest `0a109f422b47`, on an NVIDIA RTX 3050
Laptop GPU and a Core i7-12700H, AIL 0.1.1 at `d9e069e`): `make index`
in a checkout of aildb at `39fcca3` printed `87 files, 648 chunks`, `648
vectors of 768 dimensions` and the line of `aildb build` with 648
records and `39fcca3a77103fcbc604c1846999ee97cea320bb` as the revision,
which `aildb check build/index/aildb.idx` printed again. A server
started with that index and asked by a client written as lines for
"make the index of a repository for the MCP server" with `k` 3 gave
`AGENTS.md` 32, `.agents/knowledge/status/open-items.md` 43 to 45 and
`docs/mcp.md` 100 to 128, the three lines, with the same `score_bits`,
that `aildb search -k 3` printed for the vector `build/embed query` made
of the same words: the paragraph, the open item and the section about
`make index` at that revision.

Against the model itself, on 2026-11-22 (Ollama 0.40.17, nomic-embed-text,
the index of AIL at `a5b4559` that `make eval` built): the three hits of
the query "print an unsigned number in decimal" were the three lines, with
the same `score_bits`, that `aildb search` printed for the vector
the embedding program of the example made of the same query (then
`example/embed.py`, since rewritten in AIL as `example/embed.aiw`).

From Claude Code, on 2026-11-22 (the version that `claude --version`
printed is in the commit that added this paragraph): `claude mcp add`
with the line above put the server in the configuration of the project,
`claude mcp get aildb` said "Connected", and a session asked to search
for "wait for a child process to end and kill it after a time limit" with
`k` 3 called the tool and got `tests/lib_proc_timeout.aiw` 1 to 22,
`lib/std/proc.aiw` 203 to 242, the record that `make eval` has at the
place 2 for this query, and `docs/language.md` 1432 to 1433, with
`source_revision` `a5b4559c2cffbef49538a668579a3820d5e16da5`; it then
opened the first with `git show <revision>:<path>` in a checkout of AIL
and printed its lines. Claude Code warns that the argument `"search_query:
"` ends in a blank, which it does on purpose: the model is given the
prefix as it stands.

From Codex (0.171.0), on 2026-11-22: a direct call through its app
server, with a temporary configuration and the local Ollama, gave the
three hits of the command with the same `score_bits`, the first checked
against the source at the returned revision; and the user validated a
session of Codex itself and reported that it passed in full. A session
of `codex exec` that is not interactive lists the tool and does not call
it, since a call of an MCP tool needs an approval there.
