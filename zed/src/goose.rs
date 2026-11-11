//! Goose for Zed: starts the compiler's language server, `goose lsp`.
//!
//! The server needs no download: it is the compiler. It is found where the
//! settings say (`lsp.goose.binary.path`), else on the PATH. A relative path in
//! the settings is taken from the project's root, so a `.zed/settings.json`
//! checked into a project can name a compiler unpacked inside it.
//!
//! The server checks a module as part of the programs that import it when the
//! client names their root files (`entryFiles` in its initialization options),
//! and wants them as absolute paths. Zed lays the user's
//! `initialization_options` over what an extension returns, unchanged, so a
//! relative path there would reach the server as written. Relative entry files
//! go under `lsp.goose.settings.entryFiles` instead, and are made absolute here.

use zed_extension_api::{
    self as zed, LanguageServerId, Result, Worktree,
    serde_json::{Value, json},
    settings::LspSettings,
};

struct GooseExtension;

/// `path` as it is if absolute, else under the project's root.
fn from_root(root: &str, path: &str) -> String {
    if path.starts_with('/') {
        path.to_string()
    } else {
        format!(
            "{}/{}",
            root.trim_end_matches('/'),
            path.trim_start_matches("./")
        )
    }
}

impl zed::Extension for GooseExtension {
    fn new() -> Self {
        GooseExtension
    }

    fn language_server_command(
        &mut self,
        id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<zed::Command> {
        let binary = LspSettings::for_worktree(id.as_ref(), worktree)
            .ok()
            .and_then(|settings| settings.binary);
        let configured = binary.as_ref().and_then(|b| b.path.clone());
        let command = match configured {
            Some(path) => from_root(&worktree.root_path(), &path),
            None => worktree.which("goose").ok_or_else(|| {
                "goose is not on the PATH: set lsp.goose.binary.path in Zed's settings \
                 to the goose compiler"
                    .to_string()
            })?,
        };
        let args = binary
            .as_ref()
            .and_then(|b| b.arguments.clone())
            .unwrap_or_else(|| vec!["lsp".to_string()]);

        // The shell's environment, so that GOOSE_HOME and the like are as in a
        // terminal, with the settings' own variables over it.
        let mut env = worktree.shell_env();
        if let Some(extra) = binary.and_then(|b| b.env) {
            for (name, value) in extra {
                env.retain(|(existing, _)| *existing != name);
                env.push((name, value));
            }
        }
        Ok(zed::Command { command, args, env })
    }

    fn language_server_initialization_options(
        &mut self,
        id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<Option<Value>> {
        let settings = LspSettings::for_worktree(id.as_ref(), worktree)
            .ok()
            .and_then(|settings| settings.settings);
        let Some(files) = settings
            .as_ref()
            .and_then(|s| s.get("entryFiles"))
            .and_then(Value::as_array)
        else {
            return Ok(None);
        };
        let root = worktree.root_path();
        let files: Vec<String> = files
            .iter()
            .filter_map(Value::as_str)
            .map(|file| from_root(&root, file))
            .collect();
        Ok(Some(json!({ "entryFiles": files })))
    }
}

zed::register_extension!(GooseExtension);
