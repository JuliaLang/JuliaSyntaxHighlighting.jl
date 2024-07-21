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
code. As part of the standard library, these faces use privileged face names, of
the form `julia_*`. These can be re-used in other packages, and customised with
`faces.toml` configuration.

!!! warning "Unstable faces"
    The particular faces used by `JuliaSyntaxHighlighting` are liable to change
    without warning in point releases. As the syntax highlighting rules are refined
    over time, changes should become less and less frequent though.

The current set of faces, and their default values are as follows:
- `julia_macro`: magenta
- `julia_symbol`: magenta
- `julia_singleton_identifier`: inherits from `julia_symbol`
- `julia_type`: yellow
- `julia_typedec`: bright blue
- `julia_comment`: grey
- `julia_string`: green
- `julia_regex`: inherits from `julia_string`
- `julia_backslash_literal`: magenta, inherits from `julia_string`
- `julia_string_delim`: bright green
- `julia_cmdstring`: inherits from `julia_string`
- `julia_char`: inherits from `julia_string`
- `julia_char_delim`: inherits from `julia_string_delim`
- `julia_number`: bright magenta
- `julia_bool`: inherits from `julia_number`
- `julia_funcall`: cyan
- `julia_broadcast`: bright blue, bold
- `julia_builtin`: bright blue
- `julia_operator`: blue
- `julia_comparator`: inherits from `julia_operator`
- `julia_assignment`: bright red
- `julia_keyword`: red
- `julia_parentheses`: unstyled
- `julia_unpaired_parentheses`: inherit from `julia_error` and `julia_parentheses`
- `julia_error`: red background
- `julia_rainbow_paren_1`: bright green, inherits from `julia_parentheses`
- `julia_rainbow_paren_2`: bright blue, inherits from `julia_parentheses`
- `julia_rainbow_paren_3`: bright red, inherits from `julia_parentheses`
- `julia_rainbow_paren_4`: inherits from `julia_rainbow_paren_1`
- `julia_rainbow_paren_5`: inherits from `julia_rainbow_paren_2`
- `julia_rainbow_paren_6`: inherits from `julia_rainbow_paren_3`
- `julia_rainbow_bracket_1`: blue, inherits from `julia_parentheses`
- `julia_rainbow_bracket_2`: bright_magenta, inherits from `julia_parentheses`
- `julia_rainbow_bracket_3`: inherits from `julia_rainbow_bracket_1`
- `julia_rainbow_bracket_4`: inherits from `julia_rainbow_bracket_2`
- `julia_rainbow_bracket_5`: inherits from `julia_rainbow_bracket_1`
- `julia_rainbow_bracket_6`: inherits from `julia_rainbow_bracket_2`
- `julia_rainbow_curly_1`: bright yellow, inherits from `julia_parentheses`
- `julia_rainbow_curly_2`: yellow, inherits from `julia_parentheses`
- `julia_rainbow_curly_3`: inherits from `julia_rainbow_curly_1`
- `julia_rainbow_curly_4`: inherits from `julia_rainbow_curly_2`
- `julia_rainbow_curly_5`: inherits from `julia_rainbow_curly_1`
- `julia_rainbow_curly_6`: inherits from `julia_rainbow_curly_2`
