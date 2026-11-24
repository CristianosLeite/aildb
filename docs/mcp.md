# aildb for a coding agent: the MCP server

`aildb-mcp` lets a coding agent, such as Claude Code or Codex, search an
index in words. It is a server of the [Model Context
Protocol](https://modelcontextprotocol.io) (revision 2025-11-25) over
stdin and stdout, a program apart from `aildb`, in the directory `mcp/`.
Nobody needs it to search: it is an adapter for a client that speaks the
protocol, and what it does is one command of `aildb`.

```
aildb-mcp -d DIRECTORY [-a AILDB] [-t MS]
aildb-mcp -s SNAPSHOT -i MODEL -e ENDPOINT [-a AILDB] [-p PREFIX] [-t MS]
```

## A directory: `-d`

The client starts the server and gives it the directory in its
configuration. A call of the tool `search` is then

```
aildb search DIRECTORY --text QUERY -k K [-p PATH_PREFIX] [-l LANGUAGE]
```

([usage.md](usage.md#search---text)), started with no shell, and the
lines it prints become the result. The command owns the rest: it makes
the index of the directory what its files are now, an edit that is not
committed with them, and asks the embedding provider of that index for
the vector of the query ([index.md](index.md), [provider.md](provider.md)).
The server knows no model, no provider and no snapshot. So the LLM that
calls the tool can be another tomorrow and the index is not made again:
which model made the vectors is said once, in `DIRECTORY/.aildb/config`,
by the `aildb index` that indexed the directory first.

- `-d DIRECTORY`: the directory, which `aildb index` indexed once with its
  options. A relative path is taken from where the client starts the
  server, so a configuration that is to hold anywhere names a whole path.
- `-a AILDB`: the command of aildb; `aildb`, looked for on `PATH`, if it
  is not given.
- `-t MS`: the milliseconds a call may take, the refresh of the index
  with it; 600000 if it is not given. The first call after many files
  changed embeds them, which is where the time goes. A call that takes
  longer is a failure, and the command is killed; the next call goes on
  from the vectors that were kept.

Nothing is checked when the server starts but its arguments, status 2 if
they are wrong. A directory that has no index, a provider that fails and
an index that another run holds are failures of a call, in the words of
the command: the text of the result is `the search failed: ` and the line
the command said, the same line that `aildb search` prints on standard
error for the same call, and `isError` is true. Arguments that are wrong
are refused by the server before the command is started, as below.

## A snapshot: `-s`

With `-s` the server searches a snapshot that was built elsewhere, by
`aildb build` or `make index`, and asks an endpoint for the vector of a
query itself. It reads the snapshot and writes nothing.

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
which `mcp/Ailfile` names by its address and the version 0.1.2, with the
revision in `mcp/Ailfile.lock`; the first build fetches it into
`mcp/deps/` with git:

```
make                  # build/aildb
cd mcp && ail build   # mcp/build/aildb-mcp
make mcp-test         # its test, with the build/aildb above; make test runs it too
```

## In Claude Code and in Codex

For a directory, the index is made once and the server is named with the
directory; the paths are whole so that they hold wherever the client
starts the server:

```
aildb index /path/of/project -i nomic-embed-text -d 768 -s 'document_prefix=search_document: ' -s 'query_prefix=search_query: ' -- /path/of/aildb-llama -m /path/of/model.gguf
claude mcp add aildb -- /path/of/aildb-mcp -d /path/of/project -a /path/of/aildb
```

and for Codex, in `~/.codex/config.toml`:

```toml
[mcp_servers.aildb]
command = "/path/of/aildb-mcp"
args = ["-d", "/path/of/project", "-a", "/path/of/aildb"]
```

After that the index follows the files by itself: each call looks at them
first. What follows is the other way, a snapshot of a revision.

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
`build/index/<name of the directory>.idx`, or the file `IDX=`; a path
may have spaces in it. Without
`REPO` it indexes aildb itself, into `build/index/aildb.idx`. It is
`tools/index.sh REPO OUT [REVISION]`, the steps of [the
example](example.md) for a repository of one's own: the files of the
revision are cut into chunks, nomic-embed-text gives their vectors, and
`aildb build -r` publishes the index with the whole name of the
revision. Two things follow from those steps:

- The chunker takes every file that is text, whatever the language: a
  source of AIL is cut at its functions, Markdown at its headings, and
  any other file by its lines alone, with the language that the end of
  its path names, `python` for `.py` and `text` for an end it does not
  know ([example.md](example.md#every-text-file)). A file that is not
  text is passed over, and so is one of more than 1048576 bytes, which
  is not taken out of git at all; the second has a line on standard
  error. A revision with no text in it is an error.
- A PDF file, one named `.pdf` that starts with `%PDF-`, is indexed by
  its pages, up to 33554432 bytes: `start_line` and `end_line` of a
  result in it are the number of the page, and its language is `pdf`
  ([example.md](example.md#pdf-files)). A result has no language, so in
  a search of all languages it is the end of the path that says whether
  the two numbers are lines or a page; `language` set to `pdf` gives
  pages alone. A page or a file that cannot be read, an encrypted one
  among them, is passed over with a line on standard error. There is no
  OCR.
- A file is indexed as the bytes git has for it at the revision, each
  written from its blob: what an attribute would do to an archive or a
  checkout (`export-ignore`, `export-subst`, a filter, line ends) is not
  done. Only a regular file is taken: a symbolic link is passed over,
  since what it names may be outside the revision, and so is a
  submodule. A path with a double quote, a backslash or a byte below
  0x20 is passed over with a line on standard error.
- The index is of a revision: a change that is not committed is not in
  it. `make index` again, after a commit, replaces the file as `aildb
  build` does, and the next call of the tool searches the new one, with
  the server left running.

Then the server is added with the paths of the two executables and of
the index, each a whole path, since the agent starts the server in a
directory of its own choice. In the clone:

```
claude mcp add aildb -- "$PWD/mcp/build/aildb-mcp" \
    -s "$PWD/build/index/<name>.idx" -i nomic-embed-text \
    -e http://127.0.0.1:11434 -a "$PWD/build/aildb" -p "search_query: "
codex mcp add aildb -- "$PWD/mcp/build/aildb-mcp" \
    -s "$PWD/build/index/<name>.idx" -i nomic-embed-text \
    -e http://127.0.0.1:11434 -a "$PWD/build/aildb" -p "search_query: "
```

The paths are between double quotes, so that a clone or an index whose
name has a blank is still one argument each.

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
older revision is indexed by its name, a repository with a document
whose path is not ASCII, a source in a directory with a space, a
document that `export-ignore` keeps out of an archive, a symbolic link
to a document outside it and a path that git quotes, a file that is not text and one of more than
1048576 bytes gives the three records of its three regular files of
text, and a revision or a repository that is not there, a repository
with no text in it and a service that is gone leave the index as it
was.

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

With the chunker that takes every text file, the same day, the same
machine and the same Ollama: `make index` in a checkout of aildb at
`510bf11` printed `139 files, 768 chunks`, `768 vectors of 768
dimensions` and the line of `aildb build` with 768 records and
`510bf11cd9e0e26b8657a9dd3ba54c603d488d04`. A server started with that
index gave `tools/dist-check.sh` 1 to 32 as the third of three results
for "unpack the release archive in a Docker container without AIL and
compare what the commands print", after two passages of
`docs/BACKLOG.md` about the same script, and `.github/workflows/test.yml`
1 to 36 as the one result of the language `yaml` for "run make test on a
pull request with the released AIL": a script of the shell and a
workflow, which the index of before did not have.

With a PDF file, the same day and machine: a repository of one commit
with a `README.md` and `docs/bzip2-manual.pdf`, the manual of bzip2
1.0.8 as pdfTeX 1.40.14 wrote it, 38 pages and 183803 bytes. `make
index` printed `2 files, 84 chunks` and built 84 records in 4.3
seconds. A server on that index, asked with `language` set to `pdf` and
`k` 3 for "how much memory does decompression need with the small
option", gave the pages 8, 19 and 10 of the manual, and `pdftotext -f 8
-l 8` shows on page 8 the heading "2.5. MEMORY MANAGEMENT"; asked for
"recovering data from a damaged compressed file" it gave the pages 9,
29 and 7, and `bzip2recover` is on the pages 5, 7, 9 and 10.

`mcp/tests/directory.aiw` is the server with `-d`, between a client
written as lines and the command, with `build/provider-fake` as the
provider of the index: the first call, in a directory that has a
configuration and no snapshot, asks the provider for the documents and
the query and gives the result that `aildb search DIRECTORY --text`
prints for the same query, shown after it; a call after an edit that is
not committed finds the edit and asks for the changed text and the query;
the two filters; a provider that fails, for the query and for the
documents, whose line is the text of the failure, the same line the
command says with the status 7; arguments that are wrong; a directory
that was never indexed; and starts that are wrong.

On 2026-11-24, on the machine of [index.md](index.md), the server was
started by hand with `-d` on the clone of this repository that was
indexed with nomic-embed-text through `aildb-ollama`, and was sent the
three lines of a client: the call of `search` for `compute the CRC-32 of
a run of bytes` with `k` 3 came back with `isError` false, the model, the
revision `0abc708d71aa47accfd3c48b54c2c9fd8d649e19` and the three hits of
the command, `src/lib/crc.aiw` 44 to 82 with the score 0.826291 first.
The server with `-d` was not yet added to Claude Code or to Codex.
