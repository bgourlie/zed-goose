; The scopes that config.toml's `not_in` names: no quote is closed for you
; inside a string or a comment.
[
  (string_literal)
  (raw_string_literal)
  (char_literal)
] @string

[
  (line_comment)
  (block_comment)
] @comment
