//! Goose for Zed: starts the compiler's language server, `goose lsp`.
//!
//! The server needs no download: it is the compiler, here `goose` on the PATH.
//! A project whose compiler is elsewhere names it in `lsp.goose.binary.path`,
//! with `"arguments": ["lsp"]`: Zed then runs that binary itself, with only the
//! arguments the settings give, and does not ask the extension for a command.
//! Zed also adds the shell's environment, `binary.env` and any
//! `binary.arguments` to the command returned here.
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
        _id: &LanguageServerId,
        worktree: &Worktree,
    ) -> Result<zed::Command> {
        let command = worktree.which("goose").ok_or_else(|| {
            "goose is not on the PATH: in Zed's settings, set lsp.goose.binary.path \
             to the goose compiler and lsp.goose.binary.arguments to [\"lsp\"]"
                .to_string()
        })?;
        Ok(zed::Command {
            command,
            args: vec!["lsp".to_string()],
            env: Vec::new(),
        })
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
