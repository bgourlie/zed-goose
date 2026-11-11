(function_declaration
  body: (block
    "{"
    (_)* @function.inside
    "}")) @function.around

; A function value: the block after a call, `all(xs) { it > 0 }`.
(function_value
  "{"
  (_)* @function.inside
  "}") @function.around

(struct_declaration
  body: (field_declaration_list
    "{"
    (_)* @class.inside
    "}")) @class.around

(enum_declaration
  "{"
  (_)* @class.inside
  "}") @class.around

[
  (line_comment)
  (block_comment)
]+ @comment.around
