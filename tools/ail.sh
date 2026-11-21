#!/bin/sh
# usage: tools/ail.sh [path]
#
# Make sure the repository of AIL is at ail/, which the compiler and the
# libraries are read from.
# - With a path, ail becomes a link to that checkout, and stays one until
#   it is removed: the way to build with a compiler that is being worked
#   on.
# - Without one, a link that is there is left alone. Otherwise ail is a
#   clone of the address in ail.pin at the revision pinned there: made if
#   it is not there, and moved to the revision if it is at another one,
#   unless it has changes of its own, which is an error.
# Then the link lib is made, which git ignores, so that a use line names
# a library as it does in the repository of AIL.
set -u
cd "$(dirname "$0")/.." || exit 1
die() { echo "ail: $*" >&2; exit 1; }

if [ $# -gt 0 ]; then
    [ -f "$1/compiler/ailc.aiw" ] || die "no AIL repository at $1"
    [ ! -e ail ] || [ -L ail ] || die "ail is a clone; remove it to use $1"
    ln -sfn "$(cd "$1" && pwd)" ail || exit 1
elif [ ! -L ail ]; then
    set -- $(grep -v -e '^#' -e '^[[:space:]]*$' ail.pin)
    [ $# -eq 2 ] || die "ail.pin must have one line, an address and a revision"
    url=$1 rev=$2
    if [ ! -d ail ]; then
        git clone -q "$url" ail || die "cannot clone $url (or run tools/ail.sh <path of a checkout>)"
    fi
    if [ "$(git -C ail rev-parse HEAD 2> /dev/null)" != "$rev" ]; then
        [ -z "$(git -C ail status --porcelain)" ] || die "ail has changes and is not at $rev"
        git -C ail cat-file -e "$rev^{commit}" 2> /dev/null || git -C ail fetch -q origin ||
            die "cannot fetch $url"
        git -C ail checkout -q --detach "$rev" || die "$url has no revision $rev"
    fi
fi
[ -f ail/compiler/ailc.aiw ] || die "ail is no AIL repository"
ln -sfn ail/lib lib
