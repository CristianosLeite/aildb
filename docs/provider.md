# The embedding provider

An index of a directory is made of vectors that an embedding model gives
for texts, and a search by text needs the vector of the query from the
same model. aildb computes no embedding. It asks an **embedding
provider** for them: a program outside aildb, which the user chooses
apart from the LLM that asks the questions. This page says what a
provider is asked and what it is to answer, how an index remembers which
provider made it, and what aildb checks of an answer.

`src/lib/config.aiw` is the configuration and `src/lib/provider.aiw` the
requests and the reading of an answer; [library.md](library.md) lists
their functions.

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
for each thing, a word, a tab and a value, and may be edited by hand:

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
arg	aildb-ollama
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
| `set` | a setting: a name, a tab and a value. The name is 1 to 255 bytes and is there once; the value is up to 4095 bytes and may be empty. Any number of lines |
| `arg` | an argument of the command that is the provider, up to 4095 bytes; the first is the program. At least one line, in their order |

Every value is a string as a snapshot holds one: well-formed UTF-8
without control bytes. The file ends with a line feed. Lines of the
first seven words are there once at most, in any order after the first;
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
aildb-provider 1
<provider>
<model>
<revision>
dimension
number of settings
<name><value>          one line for each setting, in the order of the names
```

each line ended by a line feed. What changes the vectors is in it: the
provider, the model, its revision, the dimension and every setting. What
does not is not: the command and its arguments, so that a program moved
to another path keeps the index, and the time and the number of texts of
a request. A setting is therefore the place for whatever of a provider
changes its vectors.

aildb cannot see the weights a provider runs. The identity is what the
configuration **says**: a model that was replaced under the same name
and revision has the same identity, and its vectors are mixed with the
old ones. The revision is the line to change then.

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
