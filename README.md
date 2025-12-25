# Julia Syntax Highlighting

[![][docs-dev-img]][docs-dev-url]
[![][ci-img]][ci-url]

The `JuliaSyntaxHighlighting` package builds on the `StyledStrings` and
`JuliaSyntax` standard libraries to provide a simple utility for applying syntax
highlighting to text.

```julia-repl
julia> using JuliaSyntaxHighlighting: highlight, highlight!

julia> highlight("String(reinterpret(UInt8, [0x293a2061696c756a]))")
"String(reinterpret(UInt8, [0x293a2061696c756a]))" # Colored in the REPL

julia> Base.annotations(ans)
9-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value::StyledStrings.Face}}:
 (region = 1:6, label = :face, value = StyledStrings.face"julia_funcall")
 (region = 7:7, label = :face, value = StyledStrings.face"julia_rainbow_paren_1")
 (region = 8:18, label = :face, value = StyledStrings.face"julia_funcall")
 (region = 19:19, label = :face, value = StyledStrings.face"julia_rainbow_paren_2")
 (region = 27:27, label = :face, value = StyledStrings.face"julia_rainbow_bracket_1")
 (region = 28:45, label = :face, value = StyledStrings.face"julia_number")
 (region = 46:46, label = :face, value = StyledStrings.face"julia_rainbow_bracket_1")
 (region = 47:47, label = :face, value = StyledStrings.face"julia_rainbow_paren_2")
 (region = 48:48, label = :face, value = StyledStrings.face"julia_rainbow_paren_1")
```


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://JuliaLang.github.io/JuliaSyntaxHighlighting.jl/dev/

[ci-img]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml/badge.svg?branch=main
[ci-url]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml?query=branch%3Amain
