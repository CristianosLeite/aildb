# Using aildb

`aildb` is one executable with four commands. `build` makes a snapshot, the
one file of an index, from embeddings and source metadata that were computed
elsewhere; `search` ranks the records of a snapshot against a query vector;
`check` validates a snapshot. `index` makes the index of a directory by
itself: it cuts the files, asks an embedding provider for their vectors and
publishes the snapshot in the directory `.aildb` of it
([index.md](index.md)); `search` with `--text` searches such a directory
for a query in words, and makes its index what the files are now first. [format.md](format.md) is the format of the file.

```
aildb build -o INDEX -v VECTORS -m METADATA -d DIMENSION -i MODEL [-r REVISION]
aildb search INDEX -k LIMIT [-q QUERY] [-p PREFIX] [-l LANGUAGE] [-i MODEL]
aildb search [DIRECTORY] --text QUERY -k LIMIT [-p PREFIX] [-l LANGUAGE] [-w MILLISECONDS]
aildb check INDEX
aildb index [DIRECTORY] [-i MODEL -d DIMENSION [-n PROVIDER] [-r REVISION] [-s NAME=VALUE]... [-t MILLISECONDS] [-b TEXTS] -- COMMAND [ARGUMENT...]]
```

An option is a letter and its value, two arguments; the options of a command
may come in any order, each at most once. Without a command, with an unknown
one, with an option the command has not got, an option twice, a value
missing, a required option missing or a number that is not one, `aildb`
prints the usage above on standard error and ends with status 2.

## Exit status

| Status | Means |
|---:|---|
| 0 | success |
| 2 | wrong usage |
| 3 | an invalid snapshot or invalid input: a file that is no snapshot, of another version, truncated or damaged; a wrong length or dimension; a value that is not finite; a zero vector; a malformed line of metadata; a model identifier that differs; a destination whose name ends in `.lock` |
| 4 | an I/O failure: a file that cannot be opened, read, written, synced, mapped or renamed, output that cannot be written, and no memory |
| 5 | another build is in progress for the same destination |
| 6 | the snapshot was published, but its durability is not confirmed |
| 7 | the embedding provider of `index` or of `search --text` failed: it could not be started, ended with a status other than 0, was ended by a signal, took too long, or gave an answer that is refused ([provider.md](provider.md)) |

Status 1 is not used. With any status but 0 there is one line on standard
error, `aildb: ` and what was wrong, with the file and, for metadata, the
line. Nothing that is a result is printed on standard output then, except
by `search` when its output fails while it is being written.

Output that cannot be written is status 4 whatever the reason, a pipe
whose reader is gone included: `aildb` ignores the signal `SIGPIPE`, which
would end it without a line and without a status, so `aildb search ... |
head -1` may end with status 4 and the line `aildb: cannot write the
output`. For `build` this is the one status 4 that comes after the
snapshot was published: see below.

## `build`

```
aildb build -o INDEX -v VECTORS -m METADATA -d DIMENSION -i MODEL [-r REVISION]
```

Makes the snapshot `INDEX` from the vectors and the metadata, replacing a
snapshot that is there. `INDEX` is any path whose name does not end in
`.lock`, which is the name of the lock of another destination.

- `-d DIMENSION`: the number of elements of every vector, 1 to 65536.
- `-i MODEL`: the identifier of the embedding model, any name the caller
  uses for it, 1 to 255 bytes.
- `-r REVISION`: the revision the sources were at, 1 to 255 bytes; leave it
  out when there is none.
- `-v VECTORS`: a file of the vectors, one after the other with nothing
  between and nothing before: each element an IEEE 754 binary32,
  little-endian, `DIMENSION` of them for each record, in the order of the
  lines of the metadata. Its size is exactly 4 times `DIMENSION` times the
  number of lines. Every element is finite, and no vector is all zeros; a
  vector need not have the norm 1, since `build` normalizes it
  ([format.md](format.md#vectors)). It is a regular file, which `build`
  maps: a directory, a device or a named pipe is an I/O failure, status
  4, and a named pipe is not waited for. The metadata and the query of
  `search` are read and may be a pipe, which is read to its end as any
  reader of a pipe does.
- `-m METADATA`: a text file with one line for each record, every line
  ended by a line feed, the last one too. A line is four fields with one
  tab between them:

  ```
  path<TAB>first line<TAB>last line<TAB>language
  ```

  The path is that of the source file from the top of the repository, 1 to
  4095 bytes. It does not start with `/` and no `..` in it leads above the
  top ([format.md](format.md#strings)), so that a result is a place in the
  repository whoever wrote the metadata. The lines are decimal numbers from 1 to 4294967295 without a
  sign, the last not below the first: the lines of the file that the vector
  stands for, counted from 1. What a line is, is the producer's to say, as
the language is: the engine keeps the two numbers and gives them back.
For a file that has no lines the chunker of `make index` counts pages,
so a record of the language `pdf` has the number of its page as both
([example.md](example.md#pdf-files)). The language is a name of the producer's
  choosing, at most 255 bytes, and may be empty. Fields are well-formed
  UTF-8 and hold no control character, so a path with a tab or a line end
  in it cannot be given. A file without lines makes a snapshot without
  records, which is valid.

The model identifier and the revision follow the rule of the fields.

`build` writes a temporary file beside `INDEX`, syncs it, validates it as
`check` would, renames it to `INDEX` and syncs the directory. Then, and
only then, it prints one line on standard output, the report of a durable
snapshot, in the form of [`check`](#check), and ends with status 0. The
temporary file is named `INDEX.`, sixteen hexadecimal digits chosen at
random and `.tmp`, and is created only if nothing has that name: `build`
never opens, cuts or removes a file that it did not create, so a snapshot
may be named `x.tmp` beside a destination `x`. A failure before the rename
removes the temporary file and leaves what was at `INDEX` as it was, a
snapshot or nothing. If the rename succeeded and the sync of the directory failed, the
new snapshot is at `INDEX` and complete, but may not survive a loss of
power: `build` prints no line on standard output, says so on standard error
and ends with status 6. If all of that succeeded and the line on standard
output cannot be written, the snapshot is published and durable and stays:
the status is 4, and the line on standard error starts with `published and
synced`. Every other status 4 of `build` leaves `INDEX` as it was. [durability.md](durability.md) says what is assumed
of the filesystem.

Only one `build` runs for a destination at a time: it holds a lock on the
file `INDEX.lock`, which it makes and never removes. A second one ends with
status 5 at once and changes nothing. A build that was killed holds no
lock; the temporary file it left stays until someone removes it, and no
later build reads it or is held up by it. Readers are not held up: a
`search` that opened the snapshot before the rename finishes on the old
one.

## `search`

```
aildb search INDEX -k LIMIT [-q QUERY] [-p PREFIX] [-l LANGUAGE] [-i MODEL]
```

Prints the `LIMIT` records of the snapshot `INDEX` that are most similar to
the query, best first.

- `-k LIMIT`: the largest number of results, 1 to 4294967295.
- `-q QUERY`: a file with the query vector, as many binary32 as the
  snapshot has dimensions, little-endian, and nothing else. Without `-q`
  the same bytes are read from standard input, to its end. A query of
  another length, with an element that is not finite, or of all zeros is
  invalid input. It need not have the norm 1. No more is read than the
  bytes of a query and one byte, which shows an input that is too long:
  `search` ends then, with status 3, and does not wait for the end of the
  input.
- `-p PREFIX`: only records whose path starts with the bytes of `PREFIX`.
  Bytes are compared, nothing is made of `/`, `.` or case: `-p lib/std`
  takes `lib/std/io.aiw` and also `lib/stdx.aiw`.
- `-l LANGUAGE`: only records whose language is `LANGUAGE`, byte for byte.
  An empty value takes the records without a language.
- `-i MODEL`: the identifier of the model the query was made with. If it
  is not the one of the snapshot, nothing is searched: status 3. Without
  `-i` nothing is compared.

Records that pass the filters are eligible; only they are scored. The score
is the cosine similarity as [format.md](format.md#scores) defines it. The
results are ordered by score, the highest first, and records with the same
score in the order of the snapshot. There are fewer than `LIMIT` when fewer
records are eligible, and none, with status 0, when a filter takes no record
or the snapshot has none.

The output is JSON Lines: each line one object, with the fields in the
order shown and no space between them. The first line is about the
snapshot:

```
{"source_revision":"7dea612a7f6e","model":"nomic-embed-text"}
```

`source_revision` is `null` when the snapshot has none. Then one line for
each result:

```
{"rank":1,"score":0.812346,"score_bits":"3fe9febd1a2b3c4d","path":"lib/std/io.aiw","start_line":12,"end_line":40}
```

| Field | Is |
|---|---|
| `rank` | the place of the result, from 1 |
| `score` | the score in decimal with six digits after the point: the decimal nearest to the exact value, a tie to the even digit; for reading |
| `score_bits` | the 64 bits of the score, an IEEE 754 binary64, as sixteen hexadecimal digits in lower case, the sign bit first; for comparing |
| `path` | the path of the record |
| `start_line`, `end_line` | its first and last line, counted from 1, as the metadata had them; for a record that `make index` made of a PDF file, the number of its page |

In a string, `"` and `\` are written `\"` and `\\`; no other byte needs an
escape, since a snapshot has no control character in a string, and bytes
above 0x7F are the UTF-8 they are in the snapshot.

`search` verifies the structure of the snapshot and the checksum of its
header and metadata, not the checksum of the vectors, which is the work of
`check`. A vector that was damaged may so be scored as if it were right.
The one damage `search` finds is an element that is not finite, in a
vector it scores: the snapshot is then invalid, status 3, and no line of
results is printed.

## `check`

```
aildb check INDEX
```

Validates the snapshot `INDEX` in full, the checksum of the vectors and
that every element of them is finite included
([format.md](format.md#validation)), and prints one line about it:

```
{"records":1234,"dimension":768,"model":"nomic-embed-text","source_revision":"7dea612a7f6e"}
```

`source_revision` is `null` when there is none. An invalid snapshot is one
line on standard error and status 3; a file that cannot be read, status 4:

```
aildb: old.idx: invalid snapshot: the checksum of the vectors differs
aildb: absent.idx: cannot open: no such file or directory
```

A snapshot is a regular file. A directory, a device or a named pipe is a
file that cannot be opened, status 4, said at once: `check` and `search`
do not wait for a writer of a named pipe.

## `index`

```
aildb index [DIRECTORY] [-i MODEL -d DIMENSION [-n PROVIDER] [-r REVISION] [-s NAME=VALUE]... [-t MILLISECONDS] [-b TEXTS] -- COMMAND [ARGUMENT...]]
```

Makes the index of `DIRECTORY`, or of the current directory if none is
named, from the files as they are on disk, and publishes it as
`DIRECTORY/.aildb/index`. [index.md](index.md) says which files are taken
and what is in `.aildb`; [provider.md](provider.md) what the provider is. A
directory whose name starts with `-` is named with `./` before it.

The first index of a directory names its embedding provider with the
options, which are written to `DIRECTORY/.aildb/config`; after that the
command is given no option and reads that file. Options given again take
the place of the whole configuration, which is how a model is changed.
The file is written when the snapshot of the options is published: a run
whose provider fails leaves the configuration that was there.

| Option | Is |
|---|---|
| `-i MODEL` | the model, 1 to 255 bytes: the model identifier of the snapshot. Required |
| `-d DIMENSION` | the elements of a vector, 1 to 65536. Required |
| `-- COMMAND [ARGUMENT...]` | the command that is the provider, everything after `--`. Required, and the last thing on the line |
| `-n PROVIDER` | a name for the provider; without it, the last part of the path of `COMMAND` |
| `-r REVISION` | which weights of the model, up to 255 bytes |
| `-s NAME=VALUE` | a setting, sent to the provider with every request; any number of times, each name once |
| `-t MILLISECONDS` | how long one request may take, 1 to 3600000; 120000 without it |
| `-b TEXTS` | the most texts of one request, 1 to 1024; 32 without it |

Of the letters `-i`, `-d`, `-n`, `-r`, `-t` and `-b` each is given once at
most. Options without `-i`, `-d` or a command, and a directory that was
never indexed without options, are wrong usage; so is a value that the
configuration does not take, with a line that says which.

On success one line of JSON is printed: that of `build`, and after its
members `files`, the number of files the records are of, `embedded`, the
number of texts whose vectors the provider was asked for, and `published`,
whether a snapshot was written: a run that finds nothing changed writes
none.

```
{"records":4,"dimension":3,"model":"m1","source_revision":"c0faccd7364870d24a192b3a835eab0f74a7612c","files":3,"embedded":4,"published":true}
```

A file that is passed over has a line on standard error, as `build/chunk`
has it ([example.md](example.md#chunks)): `aildb: passed over, a file that
is not text: PATH`, in the run that reads the file and not in those after
it. Such a file does not fail the command.

The snapshot is published as `build` publishes one
([durability.md](durability.md)), under the lock
`DIRECTORY/.aildb/index.lock`: a second `index` of the directory while one
runs ends with status 5, and a run that fails, at the provider or anywhere
before the rename, leaves the snapshot that was there. The statuses are
those above: 2 for wrong usage, and for a configuration whose command
was not named by the user for this directory
([provider.md](provider.md#which-commands-are-run)), of which nothing is
run; 3 for a file `.aildb/config` that is no configuration, 4 for a
directory or a file that cannot be read or written, 5, 6, and 7 for a
provider that failed.

## `search --text`

```
aildb search [DIRECTORY] --text QUERY -k LIMIT [-p PREFIX] [-l LANGUAGE] [-w MILLISECONDS]
```

Searches the index of `DIRECTORY`, or of the current directory if none is
named, for the query `QUERY`, a text in words, and prints what `search`
prints: the line of the snapshot and a line for each result, with the path
relative to `DIRECTORY` and the lines, or the page of a PDF file. With
`--text` the first argument is a directory, not a snapshot, and the
command has no `-q` and no `-i`: the vector of the query comes from the
embedding provider of the index, the one of `DIRECTORY/.aildb/config`,
asked with the operation `query` ([provider.md](provider.md)).

The directory was indexed once, by `aildb index` with its options. After
that a search needs nothing but the directory:

1. If the index is not what the files are now, it is made so first, as
   `aildb index` without options does it ([index.md](index.md#what-a-run-does)):
   a new, an edited and a removed file are in the results of the very
   search that follows them, committed or not.
2. The provider is asked for the vector of the query, one request.
3. The records are ranked as `search` ranks them.

An index that is up to date costs the one request for the query and no
other: whether it is up to date is found without reading a file, from the
sizes and the times in the manifest ([index.md](index.md#searching-by-text)).

| Option | Is |
|---|---|
| `--text QUERY` | the query, well-formed UTF-8, not empty. Required |
| `-k LIMIT` | the most results, as for `search`. Required |
| `-p PREFIX`, `-l LANGUAGE` | the filters of `search` |
| `-w MILLISECONDS` | how long to wait for another run that is refreshing the index, 0 to 3600000; without it, the time the configuration gives a request of the provider |

The statuses: 2 for wrong usage, for a directory that was never
indexed, and for one whose configuration names a command that the user
did not name for it ([provider.md](provider.md#which-commands-are-run));
3 for a query that is not well-formed UTF-8 and a configuration
that is none; 4; 5 if another run still holds the index after the wait; 6;
and 7 if the provider failed, for the documents or for the query. What a
refresh says of a file it passes over is on standard error; standard
output has the results alone.
