# zed-goose

A Zed extension for [Goose](https://github.com/aardappel/goose). It highlights with Goose's
own tree-sitter grammar and starts the compiler's language server, `goose lsp`, for
everything else: errors as you type, hover, go to definition, references, rename, completion,
formatting, inlay hints and semantic highlighting.

Goose keeps its grammar in the `tree-sitter/` folder of its repository, but leaves out the
parser that `tree-sitter generate` makes from it. Zed fetches a grammar with git at a commit
and compiles the `src/parser.c` it finds; it does not generate one. So this repository
vendors Goose's `tree-sitter/` folder with the parser generated, and the extension's
`extension.toml` points at that copy.

| Path | What it is |
|---|---|
| `grammar/` | Goose's `tree-sitter/` folder as it is at the commit in `UPSTREAM`, plus what `tree-sitter generate` makes from it in `grammar/src/`. Goose's own README for it is `grammar/README.md`. Not edited by hand. |
| `UPSTREAM` | The aardappel/goose commit that `grammar/` was copied from. |
| `zed/extension.toml` | The extension's manifest: the language, the grammar (`grammar/` of this repository, at a commit), the language server. |
| `zed/src/goose.rs` | Starts `goose lsp` and passes it the entry files. Zed builds it to WebAssembly. |
| `zed/languages/goose/config.toml` | The language: `.goose` files, comments, brackets that close themselves. |
| `zed/languages/goose/highlights.scm` | Made by `generate.sh`: Goose's highlight query, then `zed/highlights-zed.scm`. |
| `zed/highlights-zed.scm` | Zed's additions to Goose's highlight query (its head comment says why). |
| `zed/languages/goose/*.scm` | Zed's own queries, written against Goose's grammar: brackets, indentation, the outline, text objects, and the scopes in which quotes do not close themselves. |
| `sync.sh`, `generate.sh`, `check.sh`, `pin.sh` | Following Goose: see below. |

## Installing it

Zed needs Rust installed with rustup. In Zed, run **zed: install dev extension** from the
command palette and pick this repository's `zed/` folder. Zed builds `zed/src/goose.rs`,
fetches this repository from GitHub at the commit `zed/extension.toml` names, compiles
`grammar/src/`, then opens `.goose` files as Goose. To pick up a change, use **Rebuild** on the
extension in the Extensions page. Its log is under **zed: open log**.

## Settings

The extension starts the compiler named by `lsp.goose.binary.path`, or `goose` on the PATH.
A project's `.zed/settings.json` might say:

```json
{
  "lsp": {
    "goose": {
      "binary": { "path": "goose-dist/goose-v2026.4-macos-arm64/goose" },
      "settings": { "entryFiles": ["src/main.goose"] }
    }
  },
  "languages": { "Goose": { "semantic_tokens": "combined" } }
}
```

- `binary.path` may be relative: it is taken from the project's root. `binary.arguments`
  replaces `["lsp"]`, and `binary.env` adds to the shell's environment.
- `settings.entryFiles` names the programs' root files, relative to the project's root. The
  server then checks a module as part of the programs that import it, and shows their errors
  in it; without them, each open file is checked as a program of its own. The server wants
  them absolute, as `initialization_options.entryFiles`, and Zed passes
  `initialization_options` through unchanged, so the extension reads relative ones from
  `settings` and makes them absolute.
- `semantic_tokens` is off in Zed unless set. `"combined"` lays the server's colors for names
  (functions, types, fields, variants, parameters) over the grammar's.

## Following Goose

Needs git, Node.js, and on macOS Xcode's command line tools.

```bash
./sync.sh                                   # Goose's default branch; or ./sync.sh <ref>
./check.sh path/to/goose-v2026.4-macos-arm64 path/to/a/goose/project
git add -A && git commit -m "Goose's grammar at $(cut -c1-10 UPSTREAM)"
./pin.sh
git commit -am "Build the grammar at its new commit" && git push
```

- `sync.sh` copies Goose's `tree-sitter/` at a ref (a branch, a tag or a full commit hash:
  git cannot fetch an abbreviated one) into `grammar/` and writes the commit to `UPSTREAM`,
  then runs `generate.sh`.
- `generate.sh` generates the parser in `grammar/src/` with the tree-sitter CLI that Goose's
  `package.json` pins, and remakes `zed/languages/goose/highlights.scm`. Run it after editing
  `zed/highlights-zed.scm`.
- `check.sh` runs `generate.sh`, then Goose's corpus, compiles every query (Zed drops a
  query file that names a node the grammar does not have, without a word), and parses every
  `.goose` file under the folders given. A sync that renames a node shows up here as a query
  that no longer compiles. It fails, too, if `generate.sh` changed what was on disk: the
  generated files had fallen behind `grammar/` or `zed/highlights-zed.scm`.
- `pin.sh` sets `rev` in `zed/extension.toml` to the commit that last changed `grammar/`. A
  commit cannot name itself, so a new grammar takes two commits: the grammar, then the `rev`
  that points at it. Zed fetches from GitHub, so both must be pushed before Zed sees them; to
  try an unpushed grammar, point `repository` at `file:///path/to/zed-goose` for the while.

Changes to the grammar itself belong in Goose's repository; `grammar/` is only ever replaced
by `sync.sh`.

## License

Apache-2.0, as Goose is: see `LICENSE`. `grammar/` is Goose's work, under Goose's license.
