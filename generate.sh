#!/bin/sh
# Make what is generated from grammar/ and zed/highlights-zed.scm: the parser
# in grammar/src (with the tree-sitter CLI that grammar/package.json pins), and
# zed/languages/goose/highlights.scm, which is Goose's highlight query followed
# by Zed's additions to it. ./sync.sh runs this; run it yourself after editing
# zed/highlights-zed.scm.
set -e
here=$(cd "$(dirname "$0")" && pwd)

cd "$here/grammar"
[ -x node_modules/.bin/tree-sitter ] || npm install --no-audit --no-fund --silent
node_modules/.bin/tree-sitter generate

cd "$here"
{
    echo "; Made by generate.sh: grammar/queries/highlights.scm, then zed/highlights-zed.scm."
    echo "; Edit those, not this."
    echo
    cat grammar/queries/highlights.scm
    echo
    cat zed/highlights-zed.scm
} > zed/languages/goose/highlights.scm
echo "generated grammar/src and zed/languages/goose/highlights.scm"
