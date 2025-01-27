# This file is a part of Julia. License is MIT: https://julialang.org/license

using JuliaSyntaxHighlighting: highlight, highlight!
using Test

# We could go to the effort of testing each individual highlight face,
# however here we're aiming for the much lower bar of ensuring that
# `highlight` consistently returns a reasonable result.
# This also avoids testing as much of the particulars of JuliaSyntax.

sum1to8_highlighted = Base.AnnotatedString("sum(1:8)", [
    (1:3, :face, :julia_funcall),
    (4:4, :face, :julia_rainbow_paren_1),
    (5:5, :face, :julia_number),
    (7:7, :face, :julia_number),
    (8:8, :face, :julia_rainbow_paren_1)
])

@test highlight("sum(1:8)") == sum1to8_highlighted
@test highlight(IOBuffer("sum(1:8)")) == sum1to8_highlighted
@test highlight(IOContext(IOBuffer("sum(1:8)"))) == sum1to8_highlighted

astr_sum1to8 = Base.AnnotatedString("sum(1:8)")
@test highlight!(astr_sum1to8) == sum1to8_highlighted
@test astr_sum1to8 == sum1to8_highlighted

# Check for string indexing issues
@test Base.annotations(highlight(":π")) |> first |> first == 1:3
