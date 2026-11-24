# aildb in a program

aildb is a package of AIL (`Ailfile`): besides the command, a program
written in AIL can search a snapshot itself, with the functions the
command is made of. This page is how a program gets them and what they
are. `example/consumer` is such a program, with a test that compares its
results with those of the command; `make test` runs it. It names aildb
as above, by its address and the version 0.1.1, so what it searches with
is the library of that tag, not the one of the checkout it lies in, and
its first test in a new checkout fetches the tag from the network.

## Getting it

A package names aildb in its manifest, which the command `ail` of AIL
writes ([its documentation](https://github.com/CristianosLeite/ail/blob/main/docs/cli.md)):

```
ail new finder
cd finder
ail add https://github.com/CristianosLeite/aildb.git 0.1.1
```

That takes a released version, its tag `v0.1.1`; without the number it
is the newest tag. `ail` writes the revision the tag names into
`Ailfile.lock`, which is kept with the sources, and clones aildb into
`deps/aildb` when the package is next built. `ail add --path ../aildb`
names a checkout beside the package instead, for work on both. A source
then names a
file of aildb with the name of the package and a colon:

```
use "aildb:src/lib/search.aiw"
```

That line brings the reader of snapshots, the normalization and the
selection with it, and the files of the library of AIL they need. The
executable has no part of the command: nothing prints, nothing ends the
process, and an error is a result.

## A search

```
use "lib/std/io.aiw"
use "lib/std/bytes.aiw"
use "lib/std/file.aiw"
use "aildb:src/lib/search.aiw"
buf snap 104
buf sel 24
buf query 24

call snapopen snap "index.aildb" as r       # 0, or why it is no snapshot
call fileread "query.bin" query as r        # the binary32 of the query
call searchdim snap as dim
load query as p
alloc dim*8 as q                            # 0 without memory
call searchquery snap p q as r              # the query, of the norm 1
call searchrun snap sel q 10 0 0 0 0 as r o # the 10 best, no filter
call searchcount sel as c
i=0
while i<c
	call searchhit snap sel i as score p n first last ok
	call print p n                          # the path of the result
	call print "\n"
	i+=1
end
```

`example/consumer/src/main.aiw` is this program with its checks and with
the score printed.

| Function | Does |
|---|---|
| `snapopen s p n` | maps and validates the snapshot at the path into the 104 bytes at `s`: 0, a reason above zero (`snapwhy` puts it into words), or the error of the kernel, negated |
| `snapclose s` | unmaps it |
| `searchdim s` | the dimension: the number of binary32 of a query |
| `searchquery s p q` | makes the doubles at `q` the query of binary32 at `p`, divided by its norm: 0, `normnan` or `normzero` |
| `searchrun s t q k pp pn lp ln` | scores every record that passes the filters and keeps the best `k` in the selection `t`, the best first; `pp pn` is a prefix of the path and `lp ln` a language, each left out with 0 for its address |
| `searchcount t` | the number of results |
| `searchhit s t i` | the result at the rank `i`, from 0: the score, the path (address and length), the first and the last line, and 1 |
| `topkfree t` | gives the memory of the selection back; a selection is all zero before `searchrun`, or freed |

- **`searchrun` returns two values**: 0 and 0; `searchnomem` and 0; or
  `searchvalue` and the ordinal of a record whose vector has an element
  that is not finite, which makes the file no valid snapshot. After an
  error the selection is not read.
- **A score** is the double that [format.md](format.md#scores) defines,
  the same bits the command prints as `score_bits`;
  `aildb:src/lib/fmt.aiw` has `fmtfix` and `fmthex`, which the command
  prints it with.
- **The checks are those of `search`**: `snapopen` verifies the header
  and the metadata, not the checksum of the vectors, which `snapcheck`
  reads them for ([format.md](format.md#integrity-checks)).
- **The path** of a result is bytes of the mapped file, good while the
  snapshot is open.
- **Names.** A file of aildb owns the names that start with its own:
  `search`, `snap`, `topk`, `norm`, `text`, `crc`, `fmt`, `meta`, `pack`,
  `chunk`, `sha`, `conf`, `prov`.
  A program has no `var` and no function of such a name.

## The chunker

`aildb:src/lib/chunk.aiw` cuts a file into the chunks that
[example.md](example.md#chunks) describes. It needs the module `pdf` of
the package ail-extensions, so a package that uses it names that package
as a dependency too, with the version of the `Ailfile` of aildb.

| Function | Does |
|---|---|
| `chunkfile rp rn p l m t no` | cuts the file at the path `p l` below the directory `rp rn` if it is text or a PDF file: for each chunk a line of metadata added to the bytes buffer `m` and the chunk as a string of JSON on a line added to `t`; the number of chunks and 0, or 0 and a reason, after which `m` and `t` hold what they held; `no` gets a line for each page of a PDF file that was passed over |
| `chunkcorpus rp rn p l m t` | the same with the rules of the corpora (`chunk -c`): a path that ends in `.aiw` or `.md`, whatever it holds |
| `chunklang p n` | the language that a path names, its address and length, and 1; `text` and 0 for an end that is not in the table |
| `chunkwhy b w` | adds the words of the reason `w` to the bytes buffer `b` |

A reason is a constant of the file, `chunkpath` to `chunkmem`;
`chunkquiet` is a file that is not text under a name that does not say
it should be, of which nothing is to be said. The functions print
nothing and end no program. One file is cut at a time.

Writing a snapshot from a program is not offered as one call: `build`
is the command, with its lock, its temporary file and its syncs
([durability.md](durability.md)), and a program starts it.

## The provider

`aildb:src/lib/config.aiw` and `aildb:src/lib/provider.aiw` are the
configuration of an embedding provider and the protocol it is asked
with ([provider.md](provider.md)).

| Function | Does |
|---|---|
| `confinit c`, `conffree c` | make the `confsize` bytes at `c` an empty configuration; give its memory back |
| `confparse c p n` | reads the text of a file `.aildb/config`: 0 and 0, or a reason and the line at fault |
| `confwrite b c` | adds the configuration to a bytes buffer as that text |
| `confput c k p n`, `confstr c k` | set and read the string `confname`, `confmodel` or `confrev`; the numbers are at `c+confdim`, `c+conftime` and `c+confbatch` |
| `confadd c p n q m`, `confget c p n`, `confnext c lp ln` | add a setting, read one, and walk them in the order of their names |
| `confarg c p n`, `confargs c` | add an argument of the command; the arguments and their number |
| `confcheck c` | 0 if the configuration may be used, or the reason |
| `confident c out` | writes the 32 bytes of its identity |
| `confwhy b w` | adds the words of a reason |
| `provrequest b c op p n` | adds the request of `provdocuments` or `provquery` to a bytes buffer; `p n` is the texts, a string of JSON on each line, or the bytes of the query |
| `provparse p n dim k out` | reads an answer to `k` texts: `k` times `dim` binary32 added to the bytes buffer `out`, or a reason |
| `provdocs c p n k out err` | asks the provider of the configuration for the vectors of `k` documents, in requests of as many texts as the configuration allows: 0 and 0, or a reason and what `procwait` gave, with what the command said in the bytes buffer `err` |
| `provquerytext c p n out err` | the same for the vector of one query |
| `provtell b w st q n` | adds the words of a reason, with the status and the first line of what the command said |
| `provwhy b w` | adds the words of a reason of an answer |
