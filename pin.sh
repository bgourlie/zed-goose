#!/bin/sh
# Set the grammar's rev in zed/extension.toml to the last commit that changed
# grammar/. Zed fetches the grammar with git at that commit and compiles its
# src/, so the commit must be pushed. A commit cannot name itself, which is why
# this is a step of its own: commit grammar/, run this, commit
# zed/extension.toml, push both.
set -e
cd "$(dirname "$0")"
if [ -n "$(git status --porcelain -- grammar)" ]; then
    echo "grammar/ has changes that are not committed: commit them first" >&2
    exit 1
fi
rev=$(git log -1 --format=%H -- grammar)
[ -n "$rev" ] || { echo "grammar/ has never been committed" >&2; exit 1; }
sed -i.bak "s/^rev = \".*\"/rev = \"$rev\"/" zed/extension.toml
rm zed/extension.toml.bak
echo "zed/extension.toml: rev = $rev"
