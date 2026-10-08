# This file is a part of Julia. License is MIT: https://julialang.org/license

using JuliaSyntaxHighlighting: JuliaSyntaxHighlighting, highlight, highlight!
using Test

using StyledStrings: @face_str, @usepalette

@usepalette JuliaSyntaxHighlighting

@test isempty(Test.detect_closure_boxes(JuliaSyntaxHighlighting))

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

# Faces are compared by identity, as distinct faces can be equal in structure
facewise(s) = (String(s), [(a.region, a.label, objectid(a.value)) for a in Base.annotations(s)])

@test facewise(highlight("sum(1:8)")) == facewise(sum1to8_highlighted)
@test facewise(highlight(IOBuffer("sum(1:8)"))) == facewise(sum1to8_highlighted)
@test facewise(highlight(IOContext(IOBuffer("sum(1:8)")))) == facewise(sum1to8_highlighted)

astr_sum1to8 = Base.AnnotatedString("sum(1:8)")
@test facewise(highlight!(astr_sum1to8)) == facewise(sum1to8_highlighted)
@test facewise(astr_sum1to8) == facewise(sum1to8_highlighted)
# A string whose values cannot hold a face is refused, naming its value type
let symbolic = Base.AnnotatedString("x", [(1:1, :tag, :sym)])
    @test_throws r"annotation values are `Symbol`" highlight!(symbolic)
    @test_throws r"annotation values are `Symbol`" highlight!(SubString(symbolic, 1:1))
end

# Ensure generic operators inside parse error nodes do not crash highlighting.
@test any(a -> a.region == 5:5 && a.value === face"julia_operator",
          Base.annotations(highlight("1 2 / 3")))
@test any(a -> a.region == 5:6 && a.value === face"julia_operator",
          Base.annotations(highlight("1 2 == 3")))
@test any(a -> a.region == 3:5 && a.value === face"julia_operator",
          Base.annotations(highlight("1 <-- 2")))
@test any(a -> a.region == 3:6 && a.value === face"julia_operator",
          Base.annotations(highlight("1 <--> 2")))
@test any(a -> a.region == 2:7 && a.value === face"julia_error",
          Base.annotations(highlight("1 2 / 3", syntax_errors = true)))

# Check for string indexing issues
@test Base.annotations(highlight(":π")) |> first |> first == 1:3

# Test that labeled break/continue labels are highlighted, but not the
# (possibly juxtaposed) break value
labeled_break = highlight("@label x begin\n  break x i * 3\nend")
anns = Base.annotations(labeled_break)
@test any(a -> a.region == 24:24 && a.value === face"julia_label", anns)
@test all(a -> a.value !== face"julia_label" || a.region == 24:24, anns)
@test any(a -> a.region == 10:14 && a.value === face"julia_label",
          Base.annotations(highlight("continue outer")))
@test all(a -> a.value !== face"julia_label", Base.annotations(highlight("break")))

# Test unpaired parentheses (issue #17)
# Test consecutive unpaired closing parens and that depth counter resets properly
reset_after_unpaired = highlight("(()))) ()")
anns = Base.annotations(reset_after_unpaired)
@test anns[5].value === face"unpaired_parentheses"  # First unpaired
@test anns[6].value === face"unpaired_parentheses"  # Second unpaired
@test anns[7].value === face"rainbow_paren_1"       # Opening after reset
@test anns[8].value === face"rainbow_paren_1"       # Closing after reset
