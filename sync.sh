#!/bin/sh
# Vendor Goose's tree-sitter grammar: copy the tree-sitter/ folder of
# aardappel/goose at a commit into grammar/, record the commit in UPSTREAM, and
# run ./generate.sh. Goose leaves the generated parser out of its repository,
# and Zed only compiles one, which is why this repository exists.
#
#   ./sync.sh          # the tip of Goose's default branch
#   ./sync.sh <ref>    # a branch, a tag or a full commit hash of aardappel/goose
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
if ! git -C "$tmp" fetch -q --depth 1 --filter=blob:none origin "$ref"; then
    # An abbreviated hash names no ref, and a server only hands out a commit
    # asked for by its full hash.
    case $ref in
        *[!0-9a-f]*) ;;
        *) [ ${#ref} -ge 40 ] || echo "give the commit's full 40-character hash, not $ref" >&2 ;;
    esac
    exit 1
fi
git -C "$tmp" checkout -q FETCH_HEAD
commit=$(git -C "$tmp" rev-parse HEAD)

# Replace grammar/ whole, keeping the installed CLI: generate.sh reinstalls it
# only if Goose has pinned another version. Goose's .gitignore leaves out the
# generated files this repository keeps.
if [ -d "$here/grammar/node_modules" ]; then
    mv "$here/grammar/node_modules" "$tmp/node_modules"
fi
rm -rf "$here/grammar"
cp -R "$tmp/tree-sitter" "$here/grammar"
rm -f "$here/grammar/.gitignore"
if [ -d "$tmp/node_modules" ]; then
    mv "$tmp/node_modules" "$here/grammar/node_modules"
fi
echo "$commit" > "$here/UPSTREAM"

echo "grammar/ is tree-sitter/ of aardappel/goose at $commit"
"$here/generate.sh"
