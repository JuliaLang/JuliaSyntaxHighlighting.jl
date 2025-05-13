module JuliaSyntaxHighlighting

import Base: JuliaSyntax, AnnotatedString, annotate!
import Base.JuliaSyntax: @K_str, Kind, GreenNode, parseall, kind, flags, children, numchildren, span
using StyledStrings: Face, addface!

public highlight, highlight!

"""
    MAX_PAREN_HIGHLIGHT_DEPTH

The number of `julia_rainbow_{paren,bracket_curly}_{n}` faces
from [`HIGHLIGHT_FACES`](@ref) that can be cycled through.
"""
const MAX_PAREN_HIGHLIGHT_DEPTH = 6
"""
    RAINBOW_DELIMITERS_ENABLED

Whether to use `julia_rainbow_{paren,bracket_curly}_{n}` faces for
delimitors/parentheses (`()`, `[]`, `{}`) as opposed to just using
`julia_parentheses`.
"""
const RAINBOW_DELIMITERS_ENABLED = Ref(true)
"""
    UNMATCHED_DELIMITERS_ENABLED

Whether to apply the `julia_unpaired_parentheses` face to unpaired closing
parenthesis (`)`, `]`, '}').
"""
const UNMATCHED_DELIMITERS_ENABLED = Ref(true)
"""
    SINGLETON_IDENTIFIERS

Symbols that represent identifiers known to be instances of a singleton type,
currently just `Nothing` and `Missing`.
"""
const SINGLETON_IDENTIFIERS = (:nothing, :missing)

"""
    BASE_TYPE_IDENTIFIERS

A set of type identifiers defined in `Base` or `Core`.
"""
const BASE_TYPE_IDENTIFIERS =
    Set([n for n in names(Base, imported=true) if getglobal(Base, n) isa Type]) ∪
    Set([n for n in names(Core, imported=true) if getglobal(Core, n) isa Type])

"""
    BUILTIN_FUNCTIONS

A set of identifiers that are defined in `Core` and a `Core.Builtin`.
"""
const BUILTIN_FUNCTIONS =
    Set([n for n in names(Core) if getglobal(Base, n) isa Core.Builtin])

"""
    HIGHLIGHT_FACES

A list of `name => Face(...)` pairs that define the faces in
`JuliaSyntaxHighlighting`. These are registered during module initialisation.
"""
const HIGHLIGHT_FACES = [
    # Julia syntax highlighting faces
    :julia_macro => Face(),
    :julia_symbol => Face(),
    :julia_singleton_identifier => Face(),
    :julia_type => Face(),
    :julia_typedec => Face(),
    :julia_comment => Face(foreground=:grey),
    :julia_string => Face(foreground=:green),
    :julia_regex => Face(),
    :julia_backslash_literal => Face(),
    :julia_string_delim => Face(foreground=:julia_string),
    :julia_cmdstring => Face(),
    :julia_char => Face(inherit=:julia_string),
    :julia_char_delim => Face(inherit=:julia_string_delim),
    :julia_number => Face(),
    :julia_bool => Face(),
    :julia_funcall => Face(),
    :julia_broadcast => Face(),
    :julia_builtin => Face(),
    :julia_operator => Face(),
    :julia_comparator => Face(),
    :julia_assignment => Face(),
    :julia_keyword => Face(foreground=:red),
    :julia_parentheses => Face(),
    :julia_unpaired_parentheses => Face(inherit=[:julia_error, :julia_parentheses]),
    :julia_error => Face(background=:red),
    # Rainbow delimitors (1-6, (), [], and {})
    :julia_rainbow_paren_1 => Face(inherit=:julia_parentheses),
    :julia_rainbow_paren_2 => Face(inherit=:julia_parentheses),
    :julia_rainbow_paren_3 => Face(inherit=:julia_parentheses),
    :julia_rainbow_paren_4 => Face(inherit=:julia_rainbow_paren_1),
    :julia_rainbow_paren_5 => Face(inherit=:julia_rainbow_paren_2),
    :julia_rainbow_paren_6 => Face(inherit=:julia_rainbow_paren_3),
    :julia_rainbow_bracket_1 => Face(inherit=:julia_parentheses),
    :julia_rainbow_bracket_2 => Face(inherit=:julia_parentheses),
    :julia_rainbow_bracket_3 => Face(inherit=:julia_rainbow_bracket_1),
    :julia_rainbow_bracket_4 => Face(inherit=:julia_rainbow_bracket_2),
    :julia_rainbow_bracket_5 => Face(inherit=:julia_rainbow_bracket_1),
    :julia_rainbow_bracket_6 => Face(inherit=:julia_rainbow_bracket_2),
    :julia_rainbow_curly_1 => Face(inherit=:julia_parentheses),
    :julia_rainbow_curly_2 => Face(inherit=:julia_parentheses),
    :julia_rainbow_curly_3 => Face(inherit=:julia_rainbow_curly_1),
    :julia_rainbow_curly_4 => Face(inherit=:julia_rainbow_curly_2),
    :julia_rainbow_curly_5 => Face(inherit=:julia_rainbow_curly_1),
    :julia_rainbow_curly_6 => Face(inherit=:julia_rainbow_curly_2),
]

__init__() = foreach(addface!, HIGHLIGHT_FACES)

"""
    paren_type(k::Kind) -> (Int, Symbol)

Return a pair of values giving the change in nesting depth
caused by the paren `k` (+1 or -1), as well as a symbol
indicating the kind of parenthesis:
- `(` and `)` are a `paren`
- `[` and `]` are a `bracket`
- `{` and `}` are a `curly`

Anything else is of type `none`, and produced a depth change of `0`.
"""
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

mutable struct ParenDepthCounter
    paren::UInt
    bracket::UInt
    curly::UInt
end

ParenDepthCounter() =
    ParenDepthCounter(zero(UInt), zero(UInt), zero(UInt))

struct GreenLineage
    node::GreenNode
    parent::Union{Nothing, GreenLineage}
end

struct HighlightContext{S <: AbstractString}
    content::S
    offset::UInt
    lnode::GreenNode
    pdepths::ParenDepthCounter
end

"""
    _hl_annotations(content::AbstractString, ast::GreenNode)
      -> Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Any}}

Generate a list of annotations for the given `content` and `ast`.

Each annotation takes the form of a `@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Any}`,
where the region indexes into `content` and the value is a `julia_*` face name.

This is a small wrapper around [`_hl_annotations!`](@ref) for convenience.
"""
function _hl_annotations(content::AbstractString, ast::GreenNode; syntax_errors::Bool = false)
    highlights = Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Any}}()
    ctx = HighlightContext(content, zero(UInt), ast, ParenDepthCounter())
    _hl_annotations!(highlights, GreenLineage(ast, nothing), ctx; syntax_errors)
    highlights
end

"""
    _hl_annotations!(highlights::Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Any}},
                     lineage::GreenLineage, ctx::HighlightContext)

Populate `highlights` with annotations for the given `lineage` and `ctx`,
where `lineage` is expected to be consistent with `ctx.offset` and `ctx.lnode`.
"""
function _hl_annotations!(highlights::Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Any}},
                          lineage::GreenLineage, ctx::HighlightContext; syntax_errors::Bool = false)
    (; node, parent) = lineage
    (; content, offset, lnode, pdepths) = ctx
    region = firstindex(content)+offset:span(node)+offset
    regionstr = view(content, firstindex(content)+offset:prevind(content, span(node)+offset+1))
    nkind = node.head.kind
    pnode = if !isnothing(parent) parent.node end
    pkind = if !isnothing(parent) kind(parent.node) end
    ppkind = if !isnothing(parent) && !isnothing(parent.parent)
        kind(parent.parent.node) end
    isplainoperator(node) =
        JuliaSyntax.is_operator(node) &&
        !JuliaSyntax.is_trivia(node) &&
        !JuliaSyntax.is_prec_assignment(node) &&
        !JuliaSyntax.is_word_operator(node) &&
        nkind != K"." && nkind != K"..." &&
        (JuliaSyntax.is_trivia(node) || JuliaSyntax.is_leaf(node))
    face = if nkind == K"Identifier"
        if pkind == K"curly"
            :julia_type
        else
            name = Symbol(regionstr)
            if name in SINGLETON_IDENTIFIERS
                :julia_singleton_identifier
            elseif name == :NaN
                :julia_number
            elseif name in BASE_TYPE_IDENTIFIERS
                :julia_type
            end
        end
    elseif nkind == K"macrocall" && numchildren(node) >= 2 &&
        kind(node[1]) == K"@" && kind(node[2]) == K"MacroName"
        region = first(region):first(region)+span(node[2])
        :julia_macro
    elseif nkind == K"StringMacroName"; :julia_macro
    elseif nkind == K"CmdMacroName"; :julia_macro
    elseif nkind == K"::"
        if JuliaSyntax.is_trivia(node) || numchildren(node) == 0
            :julia_typedec
        else
            literal_typedecl = findfirst(
                c -> kind(c) == K"::" && JuliaSyntax.is_trivia(c),
                something(children(node), GreenNode[]))
            if !isnothing(literal_typedecl)
                shift = sum(c ->Int(span(c)), node[1:literal_typedecl])
                region = first(region)+shift:last(region)
                :julia_type
            end
        end
    elseif nkind == K"quote" && numchildren(node) == 2 &&
        kind(node[1]) == K":" && kind(node[2]) == K"Identifier"
        :julia_symbol
    elseif nkind == K"Comment"; :julia_comment
    elseif nkind == K"String"; :julia_string
    elseif JuliaSyntax.is_string_delim(node); :julia_string_delim
    elseif nkind == K"CmdString"; :julia_cmdstring
    elseif nkind == K"`" || nkind == K"```"; :julia_cmdstring
    elseif nkind == K"Char"
        kind(lnode) == K"'" && !isempty(highlights) &&
            (highlights[end] = (highlights[end][1], :face, :julia_char_delim))
        :julia_char
    elseif nkind == K"'" && kind(lnode) == K"Char"; :julia_char_delim
    elseif nkind == K"Bool"; :julia_bool
    elseif JuliaSyntax.is_number(nkind); :julia_number
    elseif JuliaSyntax.is_prec_assignment(nkind) && JuliaSyntax.is_trivia(node);
        if nkind == K"="
            ifelse(ppkind == K"for", :julia_keyword, :julia_assignment)
        else # updating for <op>=
            push!(highlights, (firstindex(content)+offset:span(node)+offset-1, :face, :julia_operator))
            push!(highlights, (span(node)+offset:span(node)+offset, :face, :julia_assignment))
            nothing
        end
    elseif nkind == K";" && pkind == K"parameters" && pnode == lnode
        :julia_assignment
    elseif (JuliaSyntax.is_keyword(nkind) ||nkind == K"->" ) && JuliaSyntax.is_trivia(node)
        :julia_keyword
    elseif nkind == K"where"
        if JuliaSyntax.is_trivia(node) || numchildren(node) == 0
            :julia_keyword
        else
            literal_where = findfirst(
                c -> kind(c) == K"where" && JuliaSyntax.is_trivia(c),
                something(children(node), GreenNode[]))
            if !isnothing(literal_where)
                shift = sum(c ->Int(span(c)), node[1:literal_where])
                region = first(region)+shift:last(region)
                :julia_type
            end
        end
    elseif nkind == K"in"
        ifelse(ppkind == K"for", :julia_keyword, :julia_comparator)
    elseif nkind == K"isa"; :julia_builtin
    elseif nkind in (K"&&", K"||", K"<:", K"===") && JuliaSyntax.is_trivia(node)
        :julia_builtin
    elseif JuliaSyntax.is_prec_comparison(nkind) && JuliaSyntax.is_trivia(node);
        :julia_comparator
    elseif isplainoperator(node); :julia_operator
    elseif nkind == K"..." && JuliaSyntax.is_trivia(node); :julia_operator
    elseif nkind == K"." && JuliaSyntax.is_trivia(node) && kind(pnode) == K"dotcall";
        :julia_broadcast
    elseif nkind in (K"call", K"dotcall") && JuliaSyntax.is_prefix_call(node)
        argoffset, arg1 = 0, nothing
        for arg in something(children(node), GreenNode[])
            argoffset += span(arg)
            if !JuliaSyntax.is_trivia(arg)
                arg1 = arg
                break
            end
        end
        if isnothing(arg1)
        elseif kind(arg1) == K"Identifier"
            region = first(region):first(region)+argoffset-1
            name = Symbol(regionstr)
            ifelse(name in BUILTIN_FUNCTIONS, :julia_builtin, :julia_funcall)
        elseif kind(arg1) == K"." && numchildren(arg1) == 3  &&
            kind(arg1[end]) == K"quote" &&
            numchildren(arg1[end]) == 1 &&
            kind(arg1[end][1]) == K"Identifier"
            region = first(region)+argoffset-span(arg1[end][1]):first(region)+argoffset-1
            name = Symbol(regionstr)
            ifelse(name in BUILTIN_FUNCTIONS, :julia_builtin, :julia_funcall)
        end
    elseif syntax_errors && JuliaSyntax.is_error(nkind); :julia_error
    elseif ((depthchange, ptype) = paren_type(nkind)) |> last != :none
        depthref = getfield(pdepths, ptype)
        pdepth = if depthchange > 0
            setfield!(pdepths, ptype, depthref + depthchange)
        else
            depth0 = getfield(pdepths, ptype)
            setfield!(pdepths, ptype, depthref + depthchange)
            depth0
        end
        if pdepth <= 0 && UNMATCHED_DELIMITERS_ENABLED[]
            :julia_unpaired_parentheses
        elseif !RAINBOW_DELIMITERS_ENABLED[]
            :julia_parentheses
        else
            displaydepth = mod1(pdepth, MAX_PAREN_HIGHLIGHT_DEPTH)
            Symbol("julia_rainbow_$(ptype)_$(displaydepth)")
        end
    end
    !isnothing(face) &&
        push!(highlights, (region, :face, face))
    if nkind == K"Comment"
        for match in eachmatch(
            r"(?:^|[(\[{[:space:]-])`([^[:space:]](?:.*?[^[:space:]])?)`(?:$|[!,\-.:;?\[\][:space:]])",
            regionstr)
            code = first(match.captures)
            push!(highlights, (firstindex(content)+offset+code.offset:firstindex(content)+offset+code.offset+code.ncodeunits-1,
                               :face, :code))
        end
    elseif nkind == K"String"
        for match in eachmatch(r"\\.", regionstr)
            push!(highlights, (firstindex(content)+offset+match.offset-1:firstindex(content)+offset+match.offset+ncodeunits(match.match)-2,
                               :face, :julia_backslash_literal))
        end
    end
    numchildren(node) == 0 && return
    lnode = node
    for child in something(children(node), GreenNode[])
        cctx = HighlightContext(content, offset, lnode, pdepths)
        _hl_annotations!(highlights, GreenLineage(child, lineage), cctx)
        lnode = child
        offset += span(child)
    end
end

"""
    highlight(content::Union{AbstractString, IO},
              ast::JuliaSyntax.GreenNode = <parsed content>;
              syntax_errors::Bool = false) -> AnnotatedString{String}

Apply syntax highlighting to `content` using `JuliaSyntax`.

By default, `JuliaSyntax.parseall` is used to generate to `ast` with the
`ignore_errors` keyword argument set to `true`. Alternatively, one may provide a
pre-generated `ast`.

When `syntax_errors` is set, the `julia_error` face is applied to detected syntax errors.

!!! warning
    Note that the particular faces used by `JuliaSyntax`, and the way they
    are applied, is subject to change.

# Examples

```jldoctest
julia> JuliaSyntaxHighlighting.highlight("sum(1:8)")
"sum(1:8)"

julia> JuliaSyntaxHighlighting.highlight("sum(1:8)") |> Base.annotations
5-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value}}:
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((1:3, :face, :julia_funcall))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((4:4, :face, :julia_rainbow_paren_1))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((5:5, :face, :julia_number))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((7:7, :face, :julia_number))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((8:8, :face, :julia_rainbow_paren_1))
```
"""
function highlight end

highlight(str::AbstractString; syntax_errors::Bool = false) =
    highlight(str, parseall(GreenNode, str, ignore_errors=true); syntax_errors)

highlight(io::IO; syntax_errors::Bool = false) =
    highlight(read(io, String); syntax_errors)

highlight(io::IO, ast::GreenNode; syntax_errors::Bool = false) =
    highlight(read(io, String), ast; syntax_errors)

highlight(str::AbstractString, ast::GreenNode; syntax_errors::Bool = false) =
    AnnotatedString(str, _hl_annotations(str, ast; syntax_errors))

"""
    highlight!(content::Union{AnnotatedString, SubString{AnnotatedString}},
               ast::JuliaSyntax.GreenNode = <parsed content>;
               syntax_errors::Bool = false) -> content

Modify `content` by applying syntax highlighting using `JuliaSyntax`.

By default, `JuliaSyntax.parseall` is used to generate to `ast` with the
`ignore_errors` keyword argument set to `true`. Alternatively, one may provide a
pre-generated `ast`.

When `syntax_errors` is set, the `julia_error` face is applied to detected syntax errors.

!!! warning
    Note that the particular faces used by `JuliaSyntax`, and the way they
    are applied, is subject to change.

# Examples

```jldoctest
julia> str = Base.AnnotatedString("sum(1:8)")
"sum(1:8)"

julia> JuliaSyntaxHighlighting.highlight!(str)
"sum(1:8)"

julia> Base.annotations(str)
5-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value}}:
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((1:3, :face, :julia_funcall))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((4:4, :face, :julia_rainbow_paren_1))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((5:5, :face, :julia_number))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((7:7, :face, :julia_number))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((8:8, :face, :julia_rainbow_paren_1))
```
"""
function highlight!(str::AnnotatedString; syntax_errors::Bool = false)
    for ann in _hl_annotations(str.string, parseall(GreenNode, str.string, ignore_errors=true); syntax_errors)
        annotate!(str, ann.region, ann.label, ann.value)
    end
    str
end

function highlight!(str::SubString{AnnotatedString{S}}; syntax_errors::Bool = false) where {S}
    plainstr = SubString{S}(str.string.string, str.offset, str.ncodeunits, Val(:noshift))
    for ann in _hl_annotations(plainstr, parseall(GreenNode, plainstr, ignore_errors=true); syntax_errors)
        annotate!(str, ann.region, ann.label, ann.value)
    end
    str
end

if Base.generating_output()
    highlight(read(@__FILE__, String))
    highlight!(Base.AnnotatedString("1 + 2"))
    highlight!(Base.AnnotatedString("1 + 2")[1:5])
end

end
