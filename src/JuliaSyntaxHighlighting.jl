module JuliaSyntaxHighlighting

import Base: JuliaSyntax, AnnotatedString, annotate!
import Base.JuliaSyntax: var"@K_str", Kind, GreenNode, parseall, kind, flags
using StyledStrings: Face, addface!

public highlight, highlight!

const MAX_PAREN_HIGHLIGHT_DEPTH = 6
const RAINBOW_DELIMITERS_ENABLED = Ref(true)
const UNMATCHED_DELIMITERS_ENABLED = Ref(true)

const SINGLETON_IDENTIFIERS = ("nothing", "missing")

const HIGHLIGHT_FACES = [
    # Julia syntax highlighting faces
    :julia_identifier => Face(foreground=:bright_white),
    :julia_singleton_identifier => Face(inherit=:julia_symbol),
    :julia_macro => Face(foreground=:magenta),
    :julia_symbol => Face(foreground=:magenta),
    :julia_type => Face(foreground=:yellow),
    :julia_comment => Face(foreground=:grey),
    :julia_string => Face(foreground=:green),
    :julia_string_delim => Face(foreground=:bright_green),
    :julia_cmdstring => Face(inherit=:julia_string),
    :julia_char => Face(inherit=:julia_string),
    :julia_char_delim => Face(inherit=:julia_string_delim),
    :julia_number => Face(foreground=:bright_red),
    :julia_bool => Face(foreground=:bright_red),
    :julia_funcall => Face(foreground=:cyan),
    :julia_operator => Face(foreground=:cyan),
    :julia_comparator => Face(foreground=:yellow),
    :julia_assignment => Face(foreground=:bright_blue),
    :julia_keyword => Face(foreground=:red),
    :julia_error => Face(background=:red),
    :julia_parenthetical => Face(),
    :julia_unpaired_parenthetical => Face(inherit=:julia_error),
    # Rainbow delimitors (1-6, (), [], and {})
    :julia_rainbow_paren_1 => Face(foreground=:bright_green),
    :julia_rainbow_paren_2 => Face(foreground=:bright_blue),
    :julia_rainbow_paren_3 => Face(foreground=:bright_red),
    :julia_rainbow_paren_4 => Face(inherit=:julia_rainbow_paren_1),
    :julia_rainbow_paren_5 => Face(inherit=:julia_rainbow_paren_2),
    :julia_rainbow_paren_6 => Face(inherit=:julia_rainbow_paren_3),
    :julia_rainbow_bracket_1 => Face(foreground=:blue),
    :julia_rainbow_bracket_2 => Face(foreground=:bright_magenta),
    :julia_rainbow_bracket_3 => Face(inherit=:julia_rainbow_bracket_1),
    :julia_rainbow_bracket_4 => Face(inherit=:julia_rainbow_bracket_2),
    :julia_rainbow_bracket_5 => Face(inherit=:julia_rainbow_bracket_1),
    :julia_rainbow_bracket_6 => Face(inherit=:julia_rainbow_bracket_2),
    :julia_rainbow_curly_1 => Face(foreground=:bright_yellow),
    :julia_rainbow_curly_2 => Face(foreground=:yellow),
    :julia_rainbow_curly_3 => Face(inherit=:julia_rainbow_curly_1),
    :julia_rainbow_curly_4 => Face(inherit=:julia_rainbow_curly_2),
    :julia_rainbow_curly_5 => Face(inherit=:julia_rainbow_curly_1),
    :julia_rainbow_curly_6 => Face(inherit=:julia_rainbow_curly_2),
]

__init__() = foreach(addface!, HIGHLIGHT_FACES)

function paren_type(k::Kind)
    if     k == K"(";  1, :paren
    elseif k == K")"; -1, :paren
    elseif k == K"[";  1, :bracket
    elseif k == K"]"; -1, :bracket
    elseif k == K"{";  1, :curly
    elseif k == K"}"; -1, :curly
    else               0, :none
    end
end

struct ParenDepthCounter
    paren::Ref{UInt}
    bracket::Ref{UInt}
    curly::Ref{UInt}
end

ParenDepthCounter() =
    ParenDepthCounter(Ref(zero(UInt)), Ref(zero(UInt)), Ref(zero(UInt)))

struct GreenLineage
    node::GreenNode
    parent::Union{Nothing, GreenLineage}
end

struct HighlightContext{S <: AbstractString}
    content::S
    offset::Int
    lnode::GreenNode
    llnode::GreenNode
    pdepths::ParenDepthCounter
end

function _hl_annotations(content::AbstractString, ast::GreenNode)
    highlights = Vector{Tuple{UnitRange{Int}, Pair{Symbol, Any}}}()
    ctx = HighlightContext(content, 0, ast, ast, ParenDepthCounter())
    _hl_annotations!(highlights, GreenLineage(ast, nothing), ctx)
    highlights
end

function _hl_annotations!(highlights::Vector{Tuple{UnitRange{Int}, Pair{Symbol, Any}}},
                          lineage::GreenLineage, ctx::HighlightContext)
    (; node, parent) = lineage
    (; content, offset, lnode, llnode, pdepths) = ctx
    region = firstindex(content)+offset:node.span+offset
    nkind = node.head.kind
    pnode = if !isnothing(parent) parent.node end
    pkind = if !isnothing(parent) kind(parent.node) end
    face = if nkind == K"Identifier"
        if pkind == K"::" && JuliaSyntax.is_trivia(pnode)
            :julia_type
        elseif pkind == K"curly" && kind(lnode) == K"curly" && !isnothing(parent.parent) && kind(parent.parent.node) == K"call"
            :julia_identifier
        elseif pkind == K"curly"
            :julia_type
        elseif pkind == K"braces" && lnode != pnode
            :julia_type
        elseif kind(lnode) == K"::" && JuliaSyntax.is_trivia(lnode)
            :julia_type
        elseif kind(lnode) == K":" && !JuliaSyntax.is_number(llnode) &&
            kind(llnode) ∉ (K"Identifier", K")", K"]", K"end", K"'")
            highlights[end] = (highlights[end][1], :face => :julia_symbol)
            :julia_symbol
        elseif view(content, region) in SINGLETON_IDENTIFIERS
            :julia_singleton_identifier
        elseif view(content, region) == "NaN"
            :julia_number
        else
            :julia_identifier
        end
    elseif nkind == K"@"; :julia_macro
    elseif nkind == K"MacroName"; :julia_macro
    elseif nkind == K"StringMacroName"; :julia_macro
    elseif nkind == K"CmdMacroName"; :julia_macro
    elseif nkind == K"::"; :julia_type
    elseif nkind == K"Comment"; :julia_comment
    elseif nkind == K"String"; :julia_string
    elseif JuliaSyntax.is_string_delim(node); :julia_string_delim
    elseif nkind == K"CmdString"; :julia_cmdstring
    elseif nkind == K"`" || nkind == K"```"; :julia_cmdstring
    elseif nkind == K"Char"
        kind(lnode) == K"'" && !isempty(highlights) &&
            (highlights[end] = (highlights[end][1], :face => :julia_char_delim))
        :julia_char
    elseif nkind == K"'" && kind(lnode) == K"Char"; :julia_char_delim
    elseif nkind == K"true" || nkind == K"false"; :julia_bool
    elseif JuliaSyntax.is_number(nkind); :julia_number
    elseif JuliaSyntax.is_prec_assignment(nkind) && JuliaSyntax.is_trivia(node);
        :julia_assignment
    elseif JuliaSyntax.is_word_operator(nkind) && JuliaSyntax.is_trivia(node);
        :julia_assignment
    elseif nkind == K";" && pkind == K"parameters" && pnode == lnode
        :julia_assignment
    elseif JuliaSyntax.is_prec_comparison(nkind); :julia_comparator
    elseif JuliaSyntax.is_operator(nkind) && !JuliaSyntax.is_prec_assignment(nkind) &&
        !JuliaSyntax.is_word_operator(nkind) && nkind != K"." &&
        (JuliaSyntax.is_trivia(node) || iszero(flags(node)));
        :julia_operator
    elseif JuliaSyntax.is_keyword(nkind) && JuliaSyntax.is_trivia(node); :julia_keyword
    elseif JuliaSyntax.is_error(nkind); :julia_error
    elseif ((depthchange, ptype) = paren_type(nkind)) |> last != :none
        if nkind == K"(" && !isempty(highlights) && kind(lnode) == K"Identifier" && last(last(highlights[end])) == :julia_identifier
            highlights[end] = (highlights[end][1], :face => :julia_funcall)
        end
        depthref = getfield(pdepths, ptype)[]
        pdepth = if depthchange > 0
            getfield(pdepths, ptype)[] += depthchange
        else
            depth0 = getfield(pdepths, ptype)[]
            getfield(pdepths, ptype)[] += depthchange
            depth0
        end
        if pdepth <= 0 && UNMATCHED_DELIMITERS_ENABLED[]
            :julia_unpaired_parenthetical
        elseif !RAINBOW_DELIMITERS_ENABLED[]
            :julia_parenthetical
        else
            displaydepth = mod1(pdepth, MAX_PAREN_HIGHLIGHT_DEPTH)
            Symbol("julia_rainbow_$(ptype)_$(displaydepth)")
        end
    end
    !isnothing(face) &&
        push!(highlights, (region, :face => face))
    isempty(node.args) && return
    llnode, lnode = node, node
    for child in node.args
        cctx = HighlightContext(content, offset, lnode, llnode, pdepths)
        _hl_annotations!(highlights, GreenLineage(child, lineage), cctx)
        llnode, lnode = lnode, child
        offset += child.span
    end
end

"""
    highlight(content::Union{AbstractString, IO},
              ast::JuliaSyntax.GreenNode = <parsed content>) -> AnnotatedString{String}

Apply syntax highlighting to `content` using `JuliaSyntax`.

By default, `JuliaSyntax.parseall` is used to generate to `ast` with the
`ignore_errors` keyword argument set to `true`. Alternatively, one may provide a
pre-generated `ast`.

# Examples

```jldoctest
julia> JuliaSyntaxHighlighting.highlight("sum(1:8)")
"sum(1:8)"

julia> JuliaSyntaxHighlighting.highlight("sum(1:8)") |> Base.annotations
6-element Vector{Tuple{UnitRange{Int64}, Pair{Symbol, Any}}}:
 (1:3, :face => :julia_funcall)
 (4:4, :face => :julia_rainbow_paren_1)
 (5:5, :face => :julia_number)
 (6:6, :face => :julia_operator)
 (7:7, :face => :julia_number)
 (8:8, :face => :julia_rainbow_paren_1)
```
"""
function highlight end

highlight(str::AbstractString) =
    highlight(str, parseall(GreenNode, str, ignore_errors=true))

highlight(io::IO) = highlight(read(io, String))

highlight(io::IO, ast::GreenNode) =
    highlight(read(io, String), ast)

highlight(str::AbstractString, ast::GreenNode) =
    AnnotatedString(str, _hl_annotations(str, ast))

"""
    highlight!(content::Union{AnnotatedString, SubString{AnnotatedString}},
               ast::JuliaSyntax.GreenNode = <parsed content>)

Modify `content` by applying syntax highlighting using `JuliaSyntax`.

By default, `JuliaSyntax.parseall` is used to generate to `ast` with the
`ignore_errors` keyword argument set to `true`. Alternatively, one may provide a
pre-generated `ast`.

# Examples

```jldoctest
julia> str = Base.AnnotatedString("sum(1:8)")
"sum(1:8)"

julia> JuliaSyntaxHighlighting.highlight!(str)
"sum(1:8)"

julia> Base.annotations(str)
6-element Vector{Tuple{UnitRange{Int64}, Pair{Symbol, Any}}}:
 (1:3, :face => :julia_funcall)
 (4:4, :face => :julia_rainbow_paren_1)
 (5:5, :face => :julia_number)
 (6:6, :face => :julia_operator)
 (7:7, :face => :julia_number)
 (8:8, :face => :julia_rainbow_paren_1)
```
"""
function highlight!(str::AnnotatedString)
    for (range, annot) in _hl_annotations(str.string, parseall(GreenNode, str.string, ignore_errors=true))
        annotate!(str, range, annot)
    end
    str
end

function highlight!(str::SubString{AnnotatedString{S}}) where {S}
    plainstr = SubString{S}(str.string.string, str.offset, str.ncodeunits, Val(:noshift))
    for (range, annot) in _hl_annotations(plainstr, parseall(GreenNode, plainstr, ignore_errors=true))
        annotate!(str, range, annot)
    end
    str
end

end
