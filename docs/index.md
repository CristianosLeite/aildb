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
| `.gitignore` | one line, `*`, so that git ignores the directory and everything in it: an index does not make a work tree dirty, and is not committed by `git add .` |

The directory moves with the tree it is in and is removed with it. To
start over, remove it. `.gitignore` is written when it is not there and
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

1. The directory `.aildb` is made, and the lock of `index.lock` taken; a
   run that finds it held ends with status 5.
2. The configuration is written from the options, or read.
3. The files are listed and each is cut.
4. The provider is asked for the vectors of the chunks, `batch` texts a
   request ([provider.md](provider.md#how-a-provider-is-run)).
5. The snapshot is written to a temporary file beside `index`, flushed,
   read back, renamed to `index`, and the directory flushed, as `build`
   does it ([durability.md](durability.md)).

A run that fails before the rename leaves `index` as it was: a provider
that fails or is not there, a full disk, a kill. The configuration is
written before the provider is asked, so after options that name a
provider which then fails, `config` is the new one and `index` the old
one, of the old model; the next run tries the new provider again.

A directory with no file that can be cut gives a snapshot of no records,
which is valid.

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
