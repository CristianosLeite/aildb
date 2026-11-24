# The index of a directory

`aildb index` makes the index of a directory from the files that are in
it, and keeps it in the directory itself. Nothing runs between two
commands: no service, no watcher of the filesystem. The index is as new as
the last command that looked. [usage.md](usage.md#index) has the options,
the line that is printed and the statuses, and [provider.md](provider.md)
the embedding provider that gives the vectors.

```
aildb index ~/src/project -i nomic-embed-text -d 768 \
    -s 'document_prefix=search_document: ' -s 'query_prefix=search_query: ' \
    -- aildb-llama -m ~/models/nomic-embed-text-v1.5.f16.gguf
aildb index ~/src/project
```

The first line is given once, the second whenever the index is to be made
again.

## What is in `.aildb`

Everything of the index of `DIRECTORY` is in `DIRECTORY/.aildb/`, which the
command makes:

| File | Is |
|---|---|
| `index` | the snapshot ([format.md](format.md)): what `aildb search` and `aildb check` are given, and any program that reads a snapshot |
| `index.lock` | the lock of a run, empty, never removed |
| `config` | the configuration of the provider ([provider.md](provider.md#the-configuration-of-an-index)) |
| `manifest` | of which files the snapshot was made, and the chunks of each ([below](#the-manifest)) |
| `cache/` | the vectors that are kept, in one file named by the identity of the configuration ([below](#the-vectors-that-are-kept)) |
| `.gitignore` | one line, `*`, so that git ignores the directory and everything in it: an index does not make a work tree dirty, and is not committed by `git add .` |

The directory moves with the tree it is in and is removed with it. To
start over, remove it. `manifest` and `cache/` may be removed alone at any
time: what they save is work, and a run makes them again. `.gitignore` is written when it is not there and
left alone when it is, so a line taken out of it stays out.

## Which files are taken

- **In a work tree of git**: the files git knows and the files it does
  not ignore, which is what `git ls-files --cached --others
  --exclude-standard` prints for the directory. A new file that was never
  added is taken; a file that `.gitignore`, `.git/info/exclude` or the
  user's own exclude file names is not. The rules are git's, asked of
  git, not written again here. `DIRECTORY` may be a directory inside a
  work tree; then the files are those below it.
- **Anywhere else**: every file below the directory, hidden ones too. A
  directory is in a work tree if `git -C DIRECTORY rev-parse
  --is-inside-work-tree` says so; where git is not installed or says
  nothing good, it is not.
- **Never**: anything in a directory named `.aildb` or `.git`, at any
  depth.
- **Regular files only.** A symbolic link is neither followed nor taken,
  whether it leads to a file or to a directory, in the tree or out of it;
  a file that the link leads to is taken where it is, if it is in the
  tree. A pipe, a socket and a device are not taken. A file that git
  knows and that is no longer on disk is not taken.
- **The bytes are those on disk** when the command reads the file: an
  edit that is not committed, and not even saved to git's index, is what
  is indexed.

The files are taken in the order of the bytes of their paths, and each is
cut as [example.md](example.md#chunks) says for a file without `-c`: a text
file by its lines, with the language its path names, a PDF file page by
page, and a file that is neither passed over, with a line on standard
error if its name says it should be text.

## The revision

A snapshot can name a source revision ([format.md](format.md)). `index`
records one only when it says what was indexed: the name of the commit
`HEAD`, if the directory is in a work tree of git, `git status --porcelain
-- .` prints nothing for it (no file changed, added, removed or unknown to
git below the directory), and no file has other line ends on disk than in
git (`git ls-files --eol`). In every other case the snapshot names no
revision, and `source_revision` is `null`: the index is of a tree that no
commit is.

What a filter of git other than the one for line ends does to a file on
its way to disk (`ident`, a filter of Git LFS) is not seen: such a tree is
clean to git and its files are not the bytes of the commit.

For an index that is to be made again from a revision, byte for byte,
whatever is on disk, `make index` and `tools/index.sh` stay as they are
([mcp.md](mcp.md)): they take the files out of git at a revision.

## What a run does

A run makes the snapshot what the files are now, and does as little for it
as it can: a file that did not change is not read, a text whose vector is
kept is not sent to the provider, and if nothing of what the snapshot is
made of changed, no snapshot is written.

1. The directory `.aildb` is made, and the lock of `index.lock` taken; a
   run that finds it held ends with status 5. A temporary file that a
   killed run left is removed.
2. The configuration is that of the options, or the file is read. Its identity
   ([provider.md](provider.md#the-identity-of-a-configuration)) names the
   file of kept vectors, which is read.
3. The manifest is read. It counts only if it has the identity of the
   configuration and the size and the two sums of the snapshot that is
   there; else the run goes on as if there were none.
4. The files are listed. For each, the filesystem is asked for its size
   and its two times, without opening it:
   - **the same as in the manifest**, and changed before the run that
     wrote the manifest began: the file is not read. Its chunks are those
     of the manifest.
   - **anything else**: the file is read and the SHA-256 of its bytes is
     compared with the manifest. If it is the same, the file was only
     touched, and its chunks are those of the manifest. If not, or if the
     manifest has no such path, the file is cut again.
   A file that was changed while the run of the manifest was going, or
   after it began, is read once more by the next run: its times may be
   those of bytes that were not the ones indexed.
5. Each chunk has a key (below). The provider is asked for the vectors of
   the keys that are not kept, each text once, `batch` texts a request
   ([provider.md](provider.md#how-a-provider-is-run)), and what it gives
   is added to the file of kept vectors before the next request.
6. If the paths, the lines, the languages and the keys of all chunks, the
   identity and the revision are those of the manifest, the snapshot is
   left as it is; the manifest is written again if a file was touched.
   Else a whole snapshot is written to a temporary file beside `index`,
   flushed, read back, renamed to `index`, and the directory flushed, as
   `build` does it ([durability.md](durability.md)); then the manifest is
   written, to `manifest.new`, which is renamed. A configuration of the
   options is written here, to `config.new`, which is renamed to
   `config`: after the snapshot has its name and before the manifest, or
   when the snapshot is left as it is.
7. The vectors that no chunk of this run used are taken out of the file
   of kept vectors, and the files of other identities are removed.

The line that is printed says what the run did: `embedded` is the number
of texts the provider was asked for, and `published` whether a snapshot
was written.

- **A file that was moved or copied asks for nothing**: the key of a
  chunk has neither its path nor its lines, so the records get the new
  path and the vectors that are kept.
- **An edit of one file asks for its changed chunks**: the file is cut
  again, and the chunks whose text is the same have their vectors.
- **Another model, revision, dimension or setting is another identity**:
  the manifest does not count and no kept vector is used, so every text
  is asked for again, and the vectors of the old identity are removed
  when the run has published. The command of the provider, the time and
  the number of texts of a request are no part of the identity.
- **A directory with no file that can be cut** gives a snapshot of no
  records, which is valid; so does the removal of the last file.
- **A file that is passed over** has its line on standard error when it
  is read, not in every run: the manifest remembers that it gave nothing.

## Searching by text

`aildb search DIRECTORY --text QUERY -k LIMIT` ([usage.md](usage.md#search---text))
is the search of a directory: it makes the index what the files are now,
asks the provider of the index for the vector of the query, and ranks.
Nothing has to be run before it but the first `aildb index`, which names
the provider.

Whether the index is up to date is found without reading a file and
without the lock: the manifest must be of the configuration and of the
snapshot that is there, and must have every file of the directory with the
size and the two times it has now, older than the run that wrote the
manifest, and no file besides. Then the search maps the snapshot and asks
the provider for the query alone. The listing is the one of a run, so in a
work tree it is two commands of git.

If it is not up to date, the search takes the lock and does what a run of
`aildb index` does, and then searches the snapshot that run left. If
another run holds the lock, it waits for it, looking every 50 ms, for the
time `-w` gives or the time of a request of the provider, and then looks
at the files itself; a run that is still going after that is status 5.
Waiting is what makes a search after an edit see the edit, and a first
search has no older snapshot to fall back on.

- **The revision is not asked of git for an index that is up to date.**
  A snapshot whose files did not change still has the revision it was
  given, or none: a commit of files that were indexed uncommitted does
  not give the snapshot its revision until `aildb index` runs, which
  always asks.
- **A search may write**: the snapshot, the manifest and the kept
  vectors, when the files changed. A directory that cannot be written is
  status 4 once its index is out of date.

## The manifest

`.aildb/manifest` is text. Five lines say of what it is the manifest, and
then each file has a line, followed by a line for each of its chunks:

```
aildb-manifest	1
identity	1c3b0dd7b08a1a4a4daf381efe593a038d007d404de537550c6e023bdf4656ac
snapshot	4156	1653381763	2804466236
started	1795536000123456789
state	6a09e667f3bcc908bb67ae8584caa73b3c6ef372fe94f82ba54ff53a5f1d36f1
file	a.md	30	1795535999000000000	1795535999000000000	8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4	0	2
1	2	markdown	e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
4	5	markdown	ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb
```

| Line | Has |
|---|---|
| `identity` | the identity of the configuration whose vectors the snapshot has |
| `snapshot` | the size of the snapshot in bytes, the CRC-32 of its header and metadata and that of its vectors, as its header has them ([format.md](format.md)) |
| `started` | when the run that wrote the manifest began, in nanoseconds since 1970 |
| `state` | the SHA-256 of what the snapshot is made of: for each file its path and the lines of its chunks, then the identity and the revision |
| `file` | a path, the size of the file, the nanoseconds of its last change of contents and of its last change of anything, the SHA-256 of its bytes or `-` for a file of more bytes than are ever read, 0 or the reason why it gave no chunk, and the number of its chunks |
| a chunk | its first line, its last line, its language and its key |

The numbers and digits above are an example of the layout, not of a run.
A path that `build` would not take, with a control byte in it, has no
line: it is passed over by every run.

The manifest is written after the snapshot it is of, and a run believes it
only when its line `snapshot` is the snapshot that is there. So whatever
stopped a run between the two, a kill or a full disk, the next run sees a
manifest of another snapshot, takes it for none, and looks at every file
again; it still has the kept vectors, and asks the provider for nothing it
got before.

## The vectors that are kept

`.aildb/cache/` has one file, named by the 64 digits of the identity of
the configuration. It begins with `AILDBVEC`, the number 1 and the
dimension, 16 bytes, and then has a record for each vector: a key of 32
bytes, the vector as the provider gave it, binary32, not divided by its
norm, and the CRC-32 of the two.

The **key** of a chunk is the SHA-256 of the identity, the word
`documents` with a line feed, and the text of the chunk as the chunker
writes it, a string of JSON. It is the exact input of the embedding: two
chunks with the same text have one vector wherever they stand, and a
vector of another identity has another key and another file.

The file may be lost, and is read as far as it is good: a record that is
cut short or does not have its sum ends it, and what follows is written
over. A file that is no such file, or of another dimension, is begun
again. Records are added at the end as the provider answers, so a run that
is stopped keeps what it got; the file is written anew, without the
vectors that no chunk used, when a run ends that had such.

## Runs that fail, overlap or are killed

- **A provider that fails** ends the run with status 7. `index` and
  `manifest` are as they were; the vectors of the requests before the
  failing one are kept, and the next run asks for the rest.
- **Two runs of one directory**: the second finds the lock held and ends
  with status 5 at once, having changed nothing. Runs of two directories
  do not meet.
- **A run that is killed** leaves, before the rename, the snapshot and
  the manifest that were there, and a temporary file that the next run
  removes; after the rename, the new snapshot and the manifest of the old
  one, which the next run takes for none. In both the next run publishes
  a snapshot of the files as they are then and writes its manifest.
- **A configuration is written when its snapshot is there**, not
  before: after options that name a provider which then fails, or a run
  of them that is killed before the snapshot has its name, `config` and
  `index` are what they were, and a search by text goes on with the old
  provider. The vectors that the new one gave are kept, and the same
  options given again ask for the rest. A run that is killed between the
  two renames leaves the new snapshot with the old configuration, which
  the next run finds out by the manifest and makes one of the two again:
  the old one, unless the options are given again.

## What was checked

`tests/cli_index.aiw` makes a work tree of git and indexes it with
`build/provider-fake`: the first index and its revision, the tree clean to
git after it, a new file and an edited one that are not committed, a
removal, an ignored path, a symbolic link, `.aildb` absent from the
records, the revision absent while the tree is changed and back after a
commit, options that replace the configuration, wrong usage, a
configuration that cannot be read, and three providers that fail, after
which `check` prints what it printed before. `tests/cli_index_plain.aiw`
does it in a directory that is in no work tree, with hidden files, links,
a pipe and a directory named `.git`. `tests/lib_tree.aiw` is the listing
and the revision alone, with line ends on disk that are not those of git.

`tests/cli_index_refresh.aiw` counts what the provider is asked, from the
log of `build/provider-fake`: nothing for files that did not change, with
no file of `.aildb` written; nothing for a file that was touched, moved or
copied; one text for one edited section; nothing at all once the last file
is removed; every text for another setting, after which the vectors of the
old identity are gone; and after a provider that fails at its second
request, the snapshot that was there and, in the next run, the texts of
the second request alone. It then removes the kept vectors, the manifest
and the snapshot in turn. `tests/kill_index.aiw` kills a run of
`build/aildb-stops` before its snapshot has its name, before it publishes,
between the snapshot and its manifest and before the directory is flushed,
and runs a second `index` of the directory while the first is stopped.
`tests/lib_cache.aiw` and `tests/lib_manifest.aiw` are the two files alone.

`tests/cli_search_text.aiw` searches a directory by text from end to end:
the first search of a directory with a configuration and no snapshot asks
the provider for the documents and then for the query; the search after it
for the query alone; the search right after an edit that is not committed
for the one changed text and the query, and the edited file is the first
result; then a new and a removed file, the filters, the current directory,
wrong usage, a directory never indexed, a query that is not UTF-8, a
provider that fails for the query and for the documents, and an index held
by a run that is stopped.

On 2026-11-24, with the two indexes of the clones above, `aildb search .
--text "compute the CRC-32 of a run of bytes" -k 3` printed from both

```
{"rank":1,"score":0.826291,"score_bits":"3fea70fa2af74f23","path":"src/lib/crc.aiw","start_line":44,"end_line":82}
{"rank":2,"score":0.782079,"score_bits":"3fe906c996b4c515","path":"src/lib/crc.aiw","start_line":1,"end_line":10}
{"rank":3,"score":0.762721,"score_bits":"3fe86835304a5326","path":"tests/lib_crc.aiw","start_line":11,"end_line":50}
```

with the scores of the index made through `aildb-ollama`; those of the
one made through `aildb-llama` were 0.826321, 0.782175 and 0.762959 for
the same three records, the two programs running the same model file. A
function of four lines added to `src/lib/text.aiw` of the second clone,
not committed, was the first result of the next search for what its
comment says, at the lines 235 to 238, and that snapshot named no
revision.

On 2026-11-24, on an Intel Core i7-12700H with Linux 7.0.0, with the
command `ail` of AIL at `d9e069e`, a clone of this repository at `0abc708`
was indexed twice by `build/aildb` of the working tree, with
nomic-embed-text, 768 dimensions, and the two prefixes as settings: once
with `aildb-ollama` against Ollama 0.40.17, and once, in a second clone,
with `aildb-llama` and `llama-embedding` built from llama.cpp `b12676` on
the model file that Ollama keeps. Each printed

```
{"records":1015,"dimension":768,"model":"nomic-embed-text","source_revision":"0abc708d71aa47accfd3c48b54c2c9fd8d649e19","files":165,"embedded":1015}
```

and `aildb check` of the second printed the same records, dimension, model
and revision. The run with llama.cpp, which loads the model for each of
its 32 requests and computed on the processor, took many times as long as
the one with Ollama.
