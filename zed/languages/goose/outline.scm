(namespace_declaration
  "namespace" @context
  name: (_) @name) @item

(function_declaration
  (function_modifier)* @context
  ["fn" "thread_fn"] @context
  name: (_) @name) @item

(extern_block
  "extern" @context
  library: (_) @name) @item

(extern_member
  "fn" @context
  name: (_) @name) @item

(struct_declaration
  "root"? @context
  "struct" @context
  name: (_) @name) @item

(field_declaration
  name: (_) @name) @item

(enum_declaration
  "enum" @context
  name: (_) @name) @item

(enum_variant
  name: (_) @name) @item

(type_alias_declaration
  "type" @context
  name: (_) @name) @item

; Globals only: a variable declared in a block is not part of the outline.
(source_file
  (variable_declaration
    ["let" "var" "const"] @context
    name: (_) @name) @item)
