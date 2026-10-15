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
9-element Vector{@NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}}:
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((1:6, StyledStrings.face"julia_funcall"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((7:7, StyledStrings.face"julia_rainbow_paren_1"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((8:18, StyledStrings.face"julia_funcall"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((19:19, StyledStrings.face"julia_rainbow_paren_2"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((27:27, StyledStrings.face"julia_rainbow_bracket_1"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((28:45, StyledStrings.face"julia_number"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((46:46, StyledStrings.face"julia_rainbow_bracket_1"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((47:47, StyledStrings.face"julia_rainbow_paren_2"))
 @NamedTuple{region::UnitRange{Int64}, value::StyledStrings.StyledValue}((48:48, StyledStrings.face"julia_rainbow_paren_1"))
```


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://JuliaLang.github.io/JuliaSyntaxHighlighting.jl/dev/

[ci-img]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml/badge.svg?branch=main
[ci-url]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml?query=branch%3Amain
