#!/usr/bin/env python3
"""Make the embeddings of the example with a model that Ollama runs.

    embed.py document TEXT VECTORS
    embed.py query QUERIES VECTORS
    embed.py model

TEXT has a string of JSON on each line, as build/chunk writes it; QUERIES
has lines of fields with tabs between, of which the first is a query; an
empty line is passed over.
VECTORS gets one vector for each line, in order: 768 binary32,
little-endian, which is what "aildb build -v" and "aildb search -q" read.
"embed.py model" prints the version of Ollama and which model it has under
the name, with its digest, for a report that is to say what made its
vectors.

The model is nomic-embed-text. It wants to be told what a text is for, so
a chunk is sent after "search_document: " and a query after
"search_query: ". Ollama is asked at the address of the environment
variable OLLAMA_HOST, or at http://127.0.0.1:11434. Only the standard
library of Python is used. docs/example.md says more.
"""
import json
import math
import os
import struct
import sys
import urllib.request

MODEL = "nomic-embed-text"
DIMENSION = 768
BATCH = 16
PREFIX = {"document": "search_document: ", "query": "search_query: "}


def texts(kind, path):
    # a file of AIL may hold bytes that are not UTF-8; the model gets
    # U+FFFD for each
    with open(path, encoding="utf-8", errors="replace", newline="\n") as f:
        lines = f.read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    if kind == "document":
        return [json.loads(line) for line in lines]
    # an empty line is no query: build/example-check and
    # build/example-eval pass over it too, and count a vector a query
    return [line.split("\t")[0] for line in lines if line]


def embed(host, batch):
    request = urllib.request.Request(
        host + "/api/embed",
        json.dumps({"model": MODEL, "input": batch, "truncate": True}).encode(),
        {"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=600) as answer:
        vectors = json.load(answer)["embeddings"]
    if len(vectors) != len(batch):
        raise ValueError("as many vectors as texts were expected")
    for vector in vectors:
        if len(vector) != DIMENSION or not all(map(math.isfinite, vector)):
            raise ValueError("a vector is not %d finite numbers" % DIMENSION)
    return vectors


def model(host):
    with urllib.request.urlopen(host + "/api/version", timeout=60) as answer:
        version = json.load(answer)["version"]
    with urllib.request.urlopen(host + "/api/tags", timeout=60) as answer:
        models = json.load(answer)["models"]
    for m in models:
        if m["name"] in (MODEL, MODEL + ":latest"):
            d = m.get("details", {})
            return "Ollama %s, %s: digest %s, %s, %s" % (
                version,
                m["name"],
                m["digest"],
                d.get("quantization_level", "?"),
                "a context of %s tokens" % d.get("context_length", "?"),
            )
    raise ValueError("Ollama has no model %s" % MODEL)


def main(argv):
    about = argv[1:] == ["model"]
    if not about and (len(argv) != 4 or argv[1] not in PREFIX):
        sys.stderr.write(__doc__.split("\n\n")[1] + "\n")
        return 2
    host = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434").rstrip("/")
    if "://" not in host:
        host = "http://" + host
    if about:
        try:
            print(model(host))
        except (OSError, ValueError, KeyError) as e:
            sys.stderr.write("embed.py: %s\n" % e)
            return 1
        return 0
    try:
        inputs = [PREFIX[argv[1]] + text for text in texts(argv[1], argv[2])]
        out = bytearray()
        for i in range(0, len(inputs), BATCH):
            for vector in embed(host, inputs[i : i + BATCH]):
                out += struct.pack("<%df" % DIMENSION, *vector)
        # the whole file or none: build reads no half of it
        with open(argv[3] + ".part", "wb") as f:
            f.write(out)
        os.replace(argv[3] + ".part", argv[3])
    except (OSError, ValueError, KeyError, struct.error) as e:
        sys.stderr.write("embed.py: %s\n" % e)
        return 1
    print("%d vectors of %d dimensions" % (len(inputs), DIMENSION))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
