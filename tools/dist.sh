#!/bin/sh
# tools/dist.sh REVISION AIL -- the archive of a release (make dist):
# the sources of aildb at REVISION, a tag or a commit, are taken out of
# git into build/dist/src and built there by the command AIL, and
# build/dist/aildb-<version>-x86_64-linux.tar.gz gets the executable,
# LICENSE and NOTICE as that revision has them, and a file BUILD that
# says which revisions of aildb and of AIL made it. The file .sha256
# beside the archive is its checksum, as sha256sum prints and checks it.
#
# A revision that has the directory adapters/ has the index of a
# directory and the search by text (docs/install.md), and its archive
# has what they need beside aildb: the providers aildb-llama and
# aildb-ollama, and aildb-mcp, the package of mcp/. Their packages name
# ail-extensions as a dependency, which the command AIL fetches from
# the network the first time. The archive of an older revision has
# aildb alone, as it had.
#
# The revision of AIL is the one of the checkout the command is in; for
# an AIL that is installed, which has none, name it: AILREV=<revision>.
set -eu
[ $# -eq 2 ] || { echo "usage: tools/dist.sh REVISION AIL" >&2; exit 2; }
rev=$1
ail=$2
commit=$(git rev-parse --verify --quiet "$rev^{commit}") || {
	echo "dist: $rev is no revision of this repository" >&2; exit 1; }
ailrev=${AILREV:-}
if [ -z "$ailrev" ]; then
	cmd=$(command -v "$ail") || { echo "dist: no command $ail" >&2; exit 1; }
	root=$(dirname "$(dirname "$(readlink -f "$cmd")")")
	if [ -f "$root/Ailfile" ] && git -C "$root" rev-parse --verify --quiet HEAD >/dev/null; then
		[ -z "$(git -C "$root" status --porcelain)" ] || {
			echo "dist: the checkout of AIL at $root has changes" >&2; exit 1; }
		ailrev=$(git -C "$root" rev-parse HEAD)
	else
		echo "dist: $cmd is in no checkout of AIL, name its revision with AILREV=" >&2
		exit 1
	fi
fi
d=build/dist
rm -rf "$d"
mkdir -p "$d/src"
git archive "$commit" | tar -x -C "$d/src"
version=$(sed -n 's/^version //p' "$d/src/Ailfile")
[ -n "$version" ] || { echo "dist: $rev has no version in Ailfile" >&2; exit 1; }
case $ail in */*) ail=$(readlink -f "$ail") ;; esac
programs=aildb
if [ -d "$d/src/adapters" ]; then
	programs="aildb aildb-llama aildb-ollama aildb-mcp"
	(cd "$d/src" && "$ail" build)
	(cd "$d/src/mcp" && "$ail" build aildb-mcp)
	cp "$d/src/mcp/build/aildb-mcp" "$d/src/build/"
else
	(cd "$d/src" && "$ail" build aildb)
fi
name=aildb-$version-x86_64-linux
mkdir "$d/$name"
cp "$d/src/LICENSE" "$d/src/NOTICE" "$d/$name/"
for p in $programs; do
	cp "$d/src/build/$p" "$d/$name/"
done
{
	echo "aildb $version for x86-64 Linux"
	echo "aildb: $commit ($rev)"
	echo "AIL: $ailrev ($("$ail" version))"
} > "$d/$name/BUILD"
# the same bytes whoever makes it: the modes, the owner and the times
chmod 755 "$d/$name"
for p in $programs; do
	chmod 755 "$d/$name/$p"
done
chmod 644 "$d/$name/LICENSE" "$d/$name/NOTICE" "$d/$name/BUILD"
tar -C "$d" --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 -czf "$d/$name.tar.gz" "$name"
rm -rf "$d/$name"
(cd "$d" && sha256sum "$name.tar.gz" > "$name.tar.gz.sha256")
cat "$d/$name.tar.gz.sha256"
