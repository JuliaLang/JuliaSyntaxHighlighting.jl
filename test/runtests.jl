# This file is a part of Julia. License is MIT: https://julialang.org/license

using JuliaSyntaxHighlighting: JuliaSyntaxHighlighting, highlight, highlight!
using StyledStrings: @face_str, @usepalettes!
using Test

@usepalettes! JuliaSyntaxHighlighting

# We could go to the effort of testing each individual highlight face,
# however here we're aiming for the much lower bar of ensuring that
# `highlight` consistently returns a reasonable result.
# This also avoids testing as much of the particulars of JuliaSyntax.

sum1to8_highlighted = Base.AnnotatedString("sum(1:8)", [
    (1:3, :face, face"funcall"),
    (4:4, :face, face"rainbow_paren_1"),
    (5:5, :face, face"number"),
    (6:6, :face, face"operator"),
    (7:7, :face, face"number"),
    (8:8, :face, face"rainbow_paren_1")
])

@test highlight("sum(1:8)") == sum1to8_highlighted
@test highlight(IOBuffer("sum(1:8)")) == sum1to8_highlighted
@test highlight(IOContext(IOBuffer("sum(1:8)"))) == sum1to8_highlighted

astr_sum1to8 = Base.AnnotatedString("sum(1:8)")
@test highlight!(astr_sum1to8) == sum1to8_highlighted
@test astr_sum1to8 == sum1to8_highlighted

# Check for string indexing issues
@test Base.annotations(highlight(":π")) |> first |> first == 1:3

# Test unpaired parentheses (issue #17)
# Test consecutive unpaired closing parens and that depth counter resets properly
reset_after_unpaired = highlight("(()))) ()")
anns = Base.annotations(reset_after_unpaired)
@test anns[5].value == face"unpaired_parentheses"  # First unpaired
@test anns[6].value == face"unpaired_parentheses"  # Second unpaired
@test anns[7].value == face"rainbow_paren_1"       # Opening after reset
@test anns[8].value == face"rainbow_paren_1"       # Closing after reset
