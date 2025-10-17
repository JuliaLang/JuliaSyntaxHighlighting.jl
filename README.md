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
9-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value}}:
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((1:6, :face, :julia_funcall))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((7:7, :face, :julia_rainbow_paren_1))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((8:18, :face, :julia_funcall))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((19:19, :face, :julia_rainbow_paren_2))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((27:27, :face, :julia_rainbow_bracket_1))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((28:45, :face, :julia_number))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((46:46, :face, :julia_rainbow_bracket_1))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((47:47, :face, :julia_rainbow_paren_2))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((48:48, :face, :julia_rainbow_paren_1))
```


[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://JuliaLang.github.io/JuliaSyntaxHighlighting.jl/dev/

[ci-img]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml/badge.svg?branch=main
[ci-url]: https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/ci.yml?query=branch%3Amain
