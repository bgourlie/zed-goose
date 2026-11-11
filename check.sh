#!/bin/sh
# Regenerate (./generate.sh), run the grammar's tests, compile every query,
# parse every .goose file under the directories given (an unpacked Goose
# release, a project written in Goose), and say whether zed/extension.toml
# names the commit grammar/ was last changed in. Fails if the generated files
# were out of date with their sources, after regenerating them and running the
# rest against the regenerated ones.
#
#   ./check.sh ~/goose-v2026.4-macos-arm64 ~/src/my-goose-project
set -e
for dir in "$@"; do
    [ -d "$dir" ] || { echo "not a directory: $dir" >&2; exit 2; }
done
here=$(cd "$(dirname "$0")" && pwd)
# The CLI compiles the parser to test it, and on macOS needs Xcode's SDK.
if [ "$(uname)" = Darwin ]; then
    export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
fi

# The directories given are taken from where the script was run, so resolve
# them before moving.
for dir in "$@"; do
    shift
    set -- "$@" "$(cd "$dir" && pwd)"
done
cd "$here"

# Compare what generate.sh makes with what was there before it ran, not with
# what is committed: after ./sync.sh the generated files differ from the last
# commit, as they should.
before=$(mktemp -d)
cp -R grammar/src "$before/src"
cp zed/languages/goose/highlights.scm "$before/highlights.scm"
./generate.sh
stale=
if ! diff -r -q "$before/src" grammar/src || ! cmp -s "$before/highlights.scm" zed/languages/goose/highlights.scm; then
    stale=yes
    echo "note: the generated files were out of date with grammar/ and zed/highlights-zed.scm: regenerated"
fi
rm -rf "$before"

cd grammar
ts=node_modules/.bin/tree-sitter
$ts test

# A query that names a node the grammar does not have stops compiling, and Zed
# then drops the whole file without a word.
sample=$(mktemp -t goose-sample)
printf 'fn main() { print("hello"); }\n' > "$sample"
for query in queries/*.scm ../zed/languages/goose/*.scm; do
    $ts query "$query" "$sample" > /dev/null
done
rm -f "$sample"
echo "all queries compile"

if [ $# -gt 0 ]; then
    find -L "$@" -name '*.goose' -print0 | xargs -0 $ts parse --quiet --stat
else
    echo "no directories given: parsed no Goose sources beyond the tests"
fi

cd "$here"
rev=$(sed -n 's/^rev = "\(.*\)"/\1/p' zed/extension.toml)
last=$(git log -1 --format=%H -- grammar 2>/dev/null || true)
if [ -n "$(git status --porcelain -- grammar)" ]; then
    echo "note: grammar/ has changes that are not committed; Zed builds the grammar at $rev"
elif [ "$rev" != "$last" ]; then
    echo "note: zed/extension.toml names $rev, but grammar/ last changed in $last: run ./pin.sh"
fi
if [ -n "$stale" ]; then
    echo "the generated files were out of date and have been regenerated: commit them" >&2
    exit 1
fi
