# Julia Syntax Highlighting

The `JuliaSyntaxHighlighting` library serves as a small convenience package to
syntax highlight Julia code using `JuliaSyntax` and `StyledStrings`.

It is intended for use across the standard library, and the wider ecosystem.

## [Functions](@id stdlib-jsh-api)

```@docs
JuliaSyntaxHighlighting.highlight
JuliaSyntaxHighlighting.highlight!
```

## [Faces](@id stdlib-jsh-faces)

The `highlight`/`highlight!` methods work by applying custom faces to Julia
code. These faces make up the palette of `JuliaSyntaxHighlighting`, so other
packages can use them after `@usepalette JuliaSyntaxHighlighting`, or as
`face"JuliaSyntaxHighlighting.keyword"` and so on. As part of the standard
library, they are registered under privileged names of the form `julia_*`, which
is how they are customised in `faces.toml`.

!!! warning "Unstable faces"
    The particular faces used by `JuliaSyntaxHighlighting` are liable to change
    without warning in point releases. As the syntax highlighting rules are refined
    over time, changes should become less and less frequent though.

The current set of faces, and their default values are as follows:
- `julia_macro`: unstyled
- `julia_symbol`: unstyled
- `julia_singleton_identifier`: inherits from `julia_symbol`
- `julia_type`: unstyled
- `julia_typedec`: inherits from `julia_operator`
- `julia_comment`: grey
- `julia_string`: green
- `julia_regex`: unstyled
- `julia_backslash_literal`: unstyled
- `julia_string_delim`: the foreground of `julia_string`
- `julia_cmd`: unstyled
- `julia_cmd_delim`: unstyled
- `julia_char`: inherits from `julia_string`
- `julia_char_delim`: inherits from `julia_string_delim`
- `julia_number`: unstyled
- `julia_bool`: inherits from `julia_number`
- `julia_funcall`: unstyled
- `julia_funcdef`: inherits from `julia_funcall`
- `julia_broadcast`: inherits from `julia_operator`
- `julia_builtin`: unstyled
- `julia_operator`: unstyled
- `julia_opassignment`: inherits from `julia_assignment`
- `julia_comparator`: inherits from `julia_operator`
- `julia_assignment`: unstyled
- `julia_keyword`: red
- `julia_label`: inherits from `julia_keyword`
- `julia_parentheses`: unstyled
- `julia_unpaired_parentheses`: inherits from `julia_error` and `julia_parentheses`
- `julia_error`: red background
- `julia_rainbow_paren_1`: inherits from `julia_parentheses`
- `julia_rainbow_paren_2`: inherits from `julia_parentheses`
- `julia_rainbow_paren_3`: inherits from `julia_parentheses`
- `julia_rainbow_paren_4`: inherits from `julia_rainbow_paren_1`
- `julia_rainbow_paren_5`: inherits from `julia_rainbow_paren_2`
- `julia_rainbow_paren_6`: inherits from `julia_rainbow_paren_3`
- `julia_rainbow_bracket_1`: inherits from `julia_parentheses`
- `julia_rainbow_bracket_2`: inherits from `julia_parentheses`
- `julia_rainbow_bracket_3`: inherits from `julia_rainbow_bracket_1`
- `julia_rainbow_bracket_4`: inherits from `julia_rainbow_bracket_2`
- `julia_rainbow_bracket_5`: inherits from `julia_rainbow_bracket_1`
- `julia_rainbow_bracket_6`: inherits from `julia_rainbow_bracket_2`
- `julia_rainbow_curly_1`: inherits from `julia_parentheses`
- `julia_rainbow_curly_2`: inherits from `julia_parentheses`
- `julia_rainbow_curly_3`: inherits from `julia_rainbow_curly_1`
- `julia_rainbow_curly_4`: inherits from `julia_rainbow_curly_2`
- `julia_rainbow_curly_5`: inherits from `julia_rainbow_curly_1`
- `julia_rainbow_curly_6`: inherits from `julia_rainbow_curly_2`
