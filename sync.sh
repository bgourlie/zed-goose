#!/bin/sh
# Vendor Goose's tree-sitter grammar: copy the tree-sitter/ folder of
# aardappel/goose at a commit into grammar/, record the commit in UPSTREAM, and
# run ./generate.sh. Goose leaves the generated parser out of its repository,
# and Zed only compiles one, which is why this repository exists.
#
#   ./sync.sh          # the tip of Goose's default branch
#   ./sync.sh <ref>    # a branch, tag or commit of aardappel/goose
#
# Then run ./check.sh, commit, and run ./pin.sh.
set -e
ref=${1:-HEAD}
here=$(cd "$(dirname "$0")" && pwd)

# Fetch the one folder at the one commit: a shallow, blobless, sparse checkout.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q
git -C "$tmp" remote add origin https://github.com/aardappel/goose
git -C "$tmp" sparse-checkout set tree-sitter
git -C "$tmp" fetch -q --depth 1 --filter=blob:none origin "$ref"
git -C "$tmp" checkout -q FETCH_HEAD
commit=$(git -C "$tmp" rev-parse HEAD)

# Goose's .gitignore leaves out the generated files this repository keeps.
rm -rf "$here/grammar"
cp -R "$tmp/tree-sitter" "$here/grammar"
rm -f "$here/grammar/.gitignore"
echo "$commit" > "$here/UPSTREAM"

echo "grammar/ is tree-sitter/ of aardappel/goose at $commit"
"$here/generate.sh"
