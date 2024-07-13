# Julia Syntax Highlighting

<!-- [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaLang.github.io/JuliaSyntaxHighlighting.jl/stable/) -->
<!-- [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaLang.github.io/JuliaSyntaxHighlighting.jl/dev/) -->
<!-- [![Build Status](https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/actions/workflows/CI.yml?query=branch%3Amain) -->
<!-- [![Coverage](https://codecov.io/gh/JuliaLang/JuliaSyntaxHighlighting.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaLang/JuliaSyntaxHighlighting.jl) -->

The `JuliaSyntaxHighlighting` package builds on the `StyledStrings` and
`JuliaSyntax` standard libraries to provide a simple utility for applying syntax
highlighting to text.

```julia-repl
julia> using JuliaSyntaxHighlighting: highlight, highlight!

julia> highlight("String(reinterpret(UInt8, [0x293a2061696c756a]))")
"String(reinterpret(UInt8, [0x293a2061696c756a]))" # Colored in the REPL

julia> Base.annotations(ans)
11-element Vector{Tuple{UnitRange{Int64}, Pair{Symbol, Any}}}:
 (1:6, :face => :julia_funcall)
 (1:6, :face => :julia_type)
 (7:7, :face => :julia_rainbow_paren_1)
 (8:18, :face => :julia_funcall)
 (19:19, :face => :julia_rainbow_paren_2)
 (20:24, :face => :julia_type)
 (27:27, :face => :julia_rainbow_bracket_1)
 (28:45, :face => :julia_number)
 (46:46, :face => :julia_rainbow_bracket_1)
 (47:47, :face => :julia_rainbow_paren_2)
 (48:48, :face => :julia_rainbow_paren_1)
```
