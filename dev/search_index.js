var documenterSearchIndex = {"docs":
[{"location":"#Julia-Syntax-Highlighting","page":"JuliaSyntaxHighlighting","title":"Julia Syntax Highlighting","text":"","category":"section"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"The JuliaSyntaxHighlighting library serves as a small convenience package to syntax highlight Julia code using JuliaSyntax and StyledStrings.","category":"page"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"It is intended for use across the standard library, and the wider ecosystem.","category":"page"},{"location":"#stdlib-jsh-api","page":"JuliaSyntaxHighlighting","title":"Functions","text":"","category":"section"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"JuliaSyntaxHighlighting.highlight\nJuliaSyntaxHighlighting.highlight!","category":"page"},{"location":"#JuliaSyntaxHighlighting.highlight","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting.highlight","text":"highlight(content::Union{AbstractString, IO},\n          ast::JuliaSyntax.GreenNode = <parsed content>;\n          syntax_errors::Bool = false) -> AnnotatedString{String}\n\nApply syntax highlighting to content using JuliaSyntax.\n\nBy default, JuliaSyntax.parseall is used to generate to ast with the ignore_errors keyword argument set to true. Alternatively, one may provide a pre-generated ast.\n\nWhen syntax_errors is set, the julia_error face is applied to detected syntax errors.\n\nwarning: Warning\nNote that the particular faces used by JuliaSyntax, and the way they are applied, is subject to change.\n\nExamples\n\njulia> JuliaSyntaxHighlighting.highlight(\"sum(1:8)\")\n\"sum(1:8)\"\n\njulia> JuliaSyntaxHighlighting.highlight(\"sum(1:8)\") |> Base.annotations\n6-element Vector{Tuple{UnitRange{Int64}, Pair{Symbol, Any}}}:\n (1:3, :face => :julia_funcall)\n (4:4, :face => :julia_rainbow_paren_1)\n (5:5, :face => :julia_number)\n (6:6, :face => :julia_operator)\n (7:7, :face => :julia_number)\n (8:8, :face => :julia_rainbow_paren_1)\n\n\n\n\n\n","category":"function"},{"location":"#JuliaSyntaxHighlighting.highlight!","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting.highlight!","text":"highlight!(content::Union{AnnotatedString, SubString{AnnotatedString}},\n           ast::JuliaSyntax.GreenNode = <parsed content>;\n           syntax_errors::Bool = false) -> content\n\nModify content by applying syntax highlighting using JuliaSyntax.\n\nBy default, JuliaSyntax.parseall is used to generate to ast with the ignore_errors keyword argument set to true. Alternatively, one may provide a pre-generated ast.\n\nWhen syntax_errors is set, the julia_error face is applied to detected syntax errors.\n\nwarning: Warning\nNote that the particular faces used by JuliaSyntax, and the way they are applied, is subject to change.\n\nExamples\n\njulia> str = Base.AnnotatedString(\"sum(1:8)\")\n\"sum(1:8)\"\n\njulia> JuliaSyntaxHighlighting.highlight!(str)\n\"sum(1:8)\"\n\njulia> Base.annotations(str)\n6-element Vector{Tuple{UnitRange{Int64}, Pair{Symbol, Any}}}:\n (1:3, :face => :julia_funcall)\n (4:4, :face => :julia_rainbow_paren_1)\n (5:5, :face => :julia_number)\n (6:6, :face => :julia_operator)\n (7:7, :face => :julia_number)\n (8:8, :face => :julia_rainbow_paren_1)\n\n\n\n\n\n","category":"function"},{"location":"#stdlib-jsh-faces","page":"JuliaSyntaxHighlighting","title":"Faces","text":"","category":"section"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"The highlight/highlight! methods work by applying custom faces to Julia code. As part of the standard library, these faces use privileged face names, of the form julia_*. These can be re-used in other packages, and customised with faces.toml configuration.","category":"page"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"warning: Unstable faces\nThe particular faces used by JuliaSyntaxHighlighting are liable to change without warning in point releases. As the syntax highlighting rules are refined over time, changes should become less and less frequent though.","category":"page"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"The current set of faces, and their default values are as follows:","category":"page"},{"location":"","page":"JuliaSyntaxHighlighting","title":"JuliaSyntaxHighlighting","text":"julia_macro: magenta\njulia_symbol: magenta\njulia_singleton_identifier: inherits from julia_symbol\njulia_type: yellow\njulia_typedec: bright blue\njulia_comment: grey\njulia_string: green\njulia_regex: inherits from julia_string\njulia_backslash_literal: magenta, inherits from julia_string\njulia_string_delim: bright green\njulia_cmdstring: inherits from julia_string\njulia_char: inherits from julia_string\njulia_char_delim: inherits from julia_string_delim\njulia_number: bright magenta\njulia_bool: inherits from julia_number\njulia_funcall: cyan\njulia_broadcast: bright blue, bold\njulia_builtin: bright blue\njulia_operator: blue\njulia_comparator: inherits from julia_operator\njulia_assignment: bright red\njulia_keyword: red\njulia_parentheses: unstyled\njulia_unpaired_parentheses: inherit from julia_error and julia_parentheses\njulia_error: red background\njulia_rainbow_paren_1: bright green, inherits from julia_parentheses\njulia_rainbow_paren_2: bright blue, inherits from julia_parentheses\njulia_rainbow_paren_3: bright red, inherits from julia_parentheses\njulia_rainbow_paren_4: inherits from julia_rainbow_paren_1\njulia_rainbow_paren_5: inherits from julia_rainbow_paren_2\njulia_rainbow_paren_6: inherits from julia_rainbow_paren_3\njulia_rainbow_bracket_1: blue, inherits from julia_parentheses\njulia_rainbow_bracket_2: brightmagenta, inherits from `juliaparentheses`\njulia_rainbow_bracket_3: inherits from julia_rainbow_bracket_1\njulia_rainbow_bracket_4: inherits from julia_rainbow_bracket_2\njulia_rainbow_bracket_5: inherits from julia_rainbow_bracket_1\njulia_rainbow_bracket_6: inherits from julia_rainbow_bracket_2\njulia_rainbow_curly_1: bright yellow, inherits from julia_parentheses\njulia_rainbow_curly_2: yellow, inherits from julia_parentheses\njulia_rainbow_curly_3: inherits from julia_rainbow_curly_1\njulia_rainbow_curly_4: inherits from julia_rainbow_curly_2\njulia_rainbow_curly_5: inherits from julia_rainbow_curly_1\njulia_rainbow_curly_6: inherits from julia_rainbow_curly_2","category":"page"},{"location":"internals/#Internals","page":"Internals","title":"Internals","text":"","category":"section"},{"location":"internals/","page":"Internals","title":"Internals","text":"Everything documented in this page is internal and subject to breaking changes. These are provided here for those curious about how JuliaSyntaxHighlighting works, and as a reference for contributors.","category":"page"},{"location":"internals/","page":"Internals","title":"Internals","text":"JuliaSyntaxHighlighting.MAX_PAREN_HIGHLIGHT_DEPTH\nJuliaSyntaxHighlighting.RAINBOW_DELIMITERS_ENABLED\nJuliaSyntaxHighlighting.UNMATCHED_DELIMITERS_ENABLED\nJuliaSyntaxHighlighting.SINGLETON_IDENTIFIERS\nJuliaSyntaxHighlighting.BASE_TYPE_IDENTIFIERS\nJuliaSyntaxHighlighting.BUILTIN_FUNCTIONS\nJuliaSyntaxHighlighting.HIGHLIGHT_FACES\nJuliaSyntaxHighlighting.paren_type\nJuliaSyntaxHighlighting._hl_annotations\nJuliaSyntaxHighlighting._hl_annotations!","category":"page"},{"location":"internals/#JuliaSyntaxHighlighting.MAX_PAREN_HIGHLIGHT_DEPTH","page":"Internals","title":"JuliaSyntaxHighlighting.MAX_PAREN_HIGHLIGHT_DEPTH","text":"MAX_PAREN_HIGHLIGHT_DEPTH\n\nThe number of julia_rainbow_{paren,bracket_curly}_{n} faces from HIGHLIGHT_FACES that can be cycled through.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.RAINBOW_DELIMITERS_ENABLED","page":"Internals","title":"JuliaSyntaxHighlighting.RAINBOW_DELIMITERS_ENABLED","text":"RAINBOW_DELIMITERS_ENABLED\n\nWhether to use julia_rainbow_{paren,bracket_curly}_{n} faces for delimitors/parentheses ((), [], {}) as opposed to just using julia_parentheses.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.UNMATCHED_DELIMITERS_ENABLED","page":"Internals","title":"JuliaSyntaxHighlighting.UNMATCHED_DELIMITERS_ENABLED","text":"UNMATCHED_DELIMITERS_ENABLED\n\nWhether to apply the julia_unpaired_parentheses face to unpaired closing parenthesis (), ], '}').\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.SINGLETON_IDENTIFIERS","page":"Internals","title":"JuliaSyntaxHighlighting.SINGLETON_IDENTIFIERS","text":"SINGLETON_IDENTIFIERS\n\nSymbols that represent identifiers known to be instances of a singleton type, currently just Nothing and Missing.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.BASE_TYPE_IDENTIFIERS","page":"Internals","title":"JuliaSyntaxHighlighting.BASE_TYPE_IDENTIFIERS","text":"BASE_TYPE_IDENTIFIERS\n\nA set of type identifiers defined in Base or Core.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.BUILTIN_FUNCTIONS","page":"Internals","title":"JuliaSyntaxHighlighting.BUILTIN_FUNCTIONS","text":"BUILTIN_FUNCTIONS\n\nA set of identifiers that are defined in Core and a Core.Builtin.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.HIGHLIGHT_FACES","page":"Internals","title":"JuliaSyntaxHighlighting.HIGHLIGHT_FACES","text":"HIGHLIGHT_FACES\n\nA list of name => Face(...) pairs that define the faces in JuliaSyntaxHighlighting. These are registered during module initialisation.\n\n\n\n\n\n","category":"constant"},{"location":"internals/#JuliaSyntaxHighlighting.paren_type","page":"Internals","title":"JuliaSyntaxHighlighting.paren_type","text":"paren_type(k::Kind) -> (Int, Symbol)\n\nReturn a pair of values giving the change in nesting depth caused by the paren k (+1 or -1), as well as a symbol indicating the kind of parenthesis:\n\n( and ) are a paren\n[ and ] are a bracket\n{ and } are a curly\n\nAnything else is of type none, and produced a depth change of 0.\n\n\n\n\n\n","category":"function"},{"location":"internals/#JuliaSyntaxHighlighting._hl_annotations","page":"Internals","title":"JuliaSyntaxHighlighting._hl_annotations","text":"_hl_annotations(content::AbstractString, ast::GreenNode) -> Vector{Tuple{UnitRange{Int}, Pair{Symbol, Any}}}\n\nGenerate a list of (range, annot) pairs for the given content and ast.\n\nThe range is a UnitRange{Int} that indexes into ctx.content and annot is a Pair of the form :face => <face>.\n\nThis is a small wrapper around _hl_annotations! for convenience.\n\n\n\n\n\n","category":"function"},{"location":"internals/#JuliaSyntaxHighlighting._hl_annotations!","page":"Internals","title":"JuliaSyntaxHighlighting._hl_annotations!","text":"_hl_annotations!(highlights::Vector{Tuple{UnitRange{Int}, Pair{Symbol, Any}}},\n                 lineage::GreenLineage, ctx::HighlightContext)\n\nPopulate highlights with (range, annot) pairs for the given lineage and ctx, where lineage is expected to be consistent with ctx.offset and ctx.lnode.\n\nThe range is a UnitRange{Int} that indexes into ctx.content and annot is a Pair of the form :face => <face>.\n\n\n\n\n\n","category":"function"}]
}
