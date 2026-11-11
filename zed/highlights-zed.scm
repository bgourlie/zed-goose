; Zed's additions to Goose's highlight query, which sync.sh appends to it to
; make zed/languages/goose/highlights.scm.
;
; Goose's query uses Neovim's capture names. Zed styles a capture by the
; longest theme name that is a dotted prefix of it, so @function.call is
; styled as function and @keyword.return as keyword. A few of Neovim's names
; have no such prefix among the names Zed's themes style: these patterns
; capture the same nodes again under names they do. Later patterns win in
; Zed, so these come after Goose's.

(char_literal) @string
(escape_sequence) @string.escape

((identifier) @variable.special
 (#eq? @variable.special "it"))
(self) @variable.special
(wildcard_pattern) @variable.special
