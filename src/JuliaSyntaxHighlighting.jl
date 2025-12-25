module JuliaSyntaxHighlighting

import Base: JuliaSyntax, AnnotatedString, annotate!
import Base.JuliaSyntax: @K_str, Kind, GreenNode, parseall, kind, flags, children, numchildren, span
using StyledStrings: StyledStrings, Face, @face_str as @F_str, @defpalette!, @registerpalette!

public highlight, highlight!

"""
    MAX_PAREN_HIGHLIGHT_DEPTH

The number of `julia_rainbow_{paren,bracket_curly}_{n}` faces
that can be cycled through.
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
    OPERATOR_KINDS

A set of known operator kind strings.

This is a workaround for operators that are classified as `K"Identifier"`.
"""
const OPERATOR_KINDS = Set{String}()

if isdefined(JuliaSyntax, :_kind_str_to_int) && isdefined(JuliaSyntax, :_kind_int_to_str)
    let (str2int, int2str) = (JuliaSyntax._kind_str_to_int, JuliaSyntax._kind_int_to_str)
        op_start = get(str2int, "BEGIN_OPS", typemax(UInt16))
        op_end = get(str2int, "END_OPS", typemin(UInt16))
        for int in op_start:op_end
            op = get(int2str, int, "")
            if !isempty(op) && !startswith(op, "Error")
                push!(OPERATOR_KINDS, op)
            end
        end
    end
end

"""
    BUILTIN_FUNCTIONS

A set of identifiers that are defined in `Core` and a `Core.Builtin`.
"""
const BUILTIN_FUNCTIONS =
    Set(push!([n for n in names(Base) if getglobal(Base, n) isa Core.Builtin], :ccall))

@defpalette! namespace=:julia begin
    var"macro" = Face()
    symbol = Face()
    singleton_identifier = Face(inherit = symbol)
    type = Face()
    typedec = Face(inherit = operator)
    comment = Face(foreground = grey)
    string = Face(foreground = green)
    regex = Face()
    backslash_literal = Face()
    string_delim = Face(foreground = string)
    cmd = Face()
    cmd_delim = Face()
    char = Face(inherit = string)
    char_delim = Face(inherit = string_delim)
    number = Face()
    bool = Face(inherit = number)
    funcall = Face()
    funcdef = Face(inherit = funcall)
    broadcast = Face(inherit = operator)
    builtin = Face()
    operator = Face()
    opassignment = Face(inherit = assignment)
    comparator = Face(inherit = operator)
    assignment = Face()
    keyword = Face(foreground = red)
    parentheses = Face()
    unpaired_parentheses = Face(inherit = [error, parentheses])
    error = Face(background = red)
    # Rainbow delimitors (1-6, (), [], and {})
    rainbow_paren_1 = Face(inherit = parentheses)
    rainbow_paren_2 = Face(inherit = parentheses)
    rainbow_paren_3 = Face(inherit = parentheses)
    rainbow_paren_4 = Face(inherit = rainbow_paren_1)
    rainbow_paren_5 = Face(inherit = rainbow_paren_2)
    rainbow_paren_6 = Face(inherit = rainbow_paren_3)
    rainbow_bracket_1 = Face(inherit = parentheses)
    rainbow_bracket_2 = Face(inherit = parentheses)
    rainbow_bracket_3 = Face(inherit = rainbow_bracket_1)
    rainbow_bracket_4 = Face(inherit = rainbow_bracket_2)
    rainbow_bracket_5 = Face(inherit = rainbow_bracket_1)
    rainbow_bracket_6 = Face(inherit = rainbow_bracket_2)
    rainbow_curly_1 = Face(inherit = parentheses)
    rainbow_curly_2 = Face(inherit = parentheses)
    rainbow_curly_3 = Face(inherit = rainbow_curly_1)
    rainbow_curly_4 = Face(inherit = rainbow_curly_2)
    rainbow_curly_5 = Face(inherit = rainbow_curly_1)
    rainbow_curly_6 = Face(inherit = rainbow_curly_2)
end

__init__() = @registerpalette!

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

const parenfaces = let pdict = Dict{Tuple{Symbol, Int}, Face}()
    for ptype in (:paren, :bracket, :curly), depth in 1:MAX_PAREN_HIGHLIGHT_DEPTH
        face_name = Symbol("rainbow_$(ptype)_$(depth)")
        face = StyledStrings.findface(@__MODULE__, face_name)::Face # NOTE: Private API
        pdict[(ptype, depth)] = face
    end
    pdict
end

mutable struct ParenDepthCounter
    paren::Int
    bracket::Int
    curly::Int
end

ParenDepthCounter() =
    ParenDepthCounter(0, 0, 0)

struct GreenLineage{H}
    node::GreenNode{H}
    parent::Union{Nothing, GreenLineage{H}}
end

struct HighlightContext{H, S <: AbstractString}
    content::S
    offset::UInt
    lnode::GreenNode{H}
    pdepths::ParenDepthCounter
end

"""
    _hl_annotations(content::AbstractString, ast::GreenNode)
      -> Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Face}}

Generate a list of annotations for the given `content` and `ast`.

Each annotation takes the form of a `@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Face}`,
where the region indexes into `content` and the value is a `julia_*` face name.

This is a small wrapper around [`_hl_annotations!`](@ref) for convenience.
"""
function _hl_annotations(content::AbstractString, ast::GreenNode; syntax_errors::Bool = false)
    highlights = Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Face}}()
    ctx = HighlightContext(content, zero(UInt), ast, ParenDepthCounter())
    _hl_annotations!(highlights, GreenLineage(ast, nothing), ctx; syntax_errors)
    highlights
end

"""
    _hl_annotations!(highlights::Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Face}},
                     lineage::GreenLineage, ctx::HighlightContext)

Populate `highlights` with annotations for the given `lineage` and `ctx`,
where `lineage` is expected to be consistent with `ctx.offset` and `ctx.lnode`.
"""
function _hl_annotations!(highlights::Vector{@NamedTuple{region::UnitRange{Int}, label::Symbol, value::Face}},
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
    isplainoperator(node, pnode) =
        JuliaSyntax.is_operator(node) &&
        (!JuliaSyntax.is_trivia(node) ||
         # HACK: This handles a case where an operator is misleadingly labelled as trivia
         !isnothing(pnode) && JuliaSyntax.is_infix_op_call(pnode)) &&
        !JuliaSyntax.is_prec_assignment(node) &&
        !JuliaSyntax.is_word_operator(node) &&
        nkind != K"." && nkind != K"..." &&
        (JuliaSyntax.is_trivia(node) || JuliaSyntax.is_leaf(node))
    face = if nkind == K"Identifier"
        if pkind == K"curly" && kind(lnode) != K"call" && !(kind(lnode) == K"curly" && ppkind == K"call")
            F"type"
        elseif pkind == kind(lnode) == K"call" && ppkind == K"function"
            F"funcdef"
        elseif pkind == K"op=" && kind(lnode) != K"op=" &&
            regionstr in OPERATOR_KINDS
            F"opassignment"
        elseif pkind ∈ (K"call", K"dotcall") && regionstr in OPERATOR_KINDS
            # HACK: The first operator isn't a `K"<op>"` for /some/ reason in
            # JuliaSyntax 1.0.
            F"operator"
        elseif pkind == K"comparison" && regionstr in OPERATOR_KINDS
            # HACK: The same as above.
            F"comparator"
        else
            name = Symbol(regionstr)
            if name in SINGLETON_IDENTIFIERS
                F"singleton_identifier"
            elseif name == :NaN
                F"number"
            end
        end
    elseif nkind == K"macrocall" && kind(node[1]) == K"macro_name"
        region = first(region):first(region)+span(node[1])-1
        F"macro"
    elseif nkind == K"StrMacroName"
        F"macro"
    elseif nkind == K"CmdMacroName"
        F"macro"
    elseif nkind == K"::"
        if JuliaSyntax.is_trivia(node) || numchildren(node) == 0
            F"typedec"
        else
            literal_typedecl = findfirst(
                c -> kind(c) == K"::" && JuliaSyntax.is_trivia(c),
                something(children(node), typeof(node)[]))
            if !isnothing(literal_typedecl)
                shift = sum(c ->Int(span(c)), node[1:literal_typedecl])
                region = first(region)+shift:last(region)
                F"type"
            end
        end
    elseif nkind == K"quote" && numchildren(node) == 2 &&
        kind(node[1]) == K":" && kind(node[2]) == K"Identifier"
        F"symbol"
    elseif nkind == K"Comment"
        F"comment"
    elseif nkind == K"String"
        F"string"
    elseif JuliaSyntax.is_string_delim(node)
        F"string_delim"
    elseif nkind == K"CmdString"
        F"cmd"
    elseif nkind == K"`" || nkind == K"```"
        F"cmd_delim"
    elseif nkind == K"Char"
        F"char"
    elseif nkind == K"'" && pkind == K"char"
        F"char_delim"
    elseif nkind == K"Bool"
        F"bool"
    elseif JuliaSyntax.is_number(nkind)
        F"number"
    elseif JuliaSyntax.is_prec_assignment(nkind) && JuliaSyntax.is_trivia(node);
        if JuliaSyntax.is_syntactic_assignment(nkind)
            ifelse(ppkind == K"for", F"keyword", F"assignment")
        else # updating for <op>=
            push!(highlights, (firstindex(content)+offset:span(node)+offset-1, :face, F"operator"))
            push!(highlights, (span(node)+offset:span(node)+offset, :face, F"assignment"))
            nothing
        end
    elseif nkind == K";" && pkind == K"parameters" && pnode == lnode
        F"assignment"
    elseif (JuliaSyntax.is_keyword(nkind) ||nkind == K"->" ) && JuliaSyntax.is_trivia(node)
        F"keyword"
    elseif nkind == K"where"
        if JuliaSyntax.is_trivia(node) || numchildren(node) == 0
            F"keyword"
        else
            literal_where = findfirst(
                c -> kind(c) == K"where" && JuliaSyntax.is_trivia(c),
                something(children(node), typeof(node)[]))
            if !isnothing(literal_where)
                shift = sum(c ->Int(span(c)), node[1:literal_where])
                region = first(region)+shift:last(region)
                F"type"
            end
        end
    elseif nkind == K"in" && pkind == K"in"
        F"keyword"
    elseif nkind == K"isa"
        F"builtin"
    elseif nkind in (K"&&", K"||", K"<:", K"===") && JuliaSyntax.is_trivia(node)
        F"builtin"
    elseif JuliaSyntax.is_prec_comparison(nkind) && JuliaSyntax.is_trivia(node);
        F"comparator"
    elseif isplainoperator(node, pnode)
        F"operator"
    elseif nkind == K"..." && JuliaSyntax.is_trivia(node)
        F"operator"
    elseif nkind == K"." && JuliaSyntax.is_trivia(node) && kind(pnode) == K"dotcall";
        F"broadcast"
    elseif nkind in (K"call", K"dotcall") && JuliaSyntax.is_prefix_call(node)
        cargs = children(node)
        if !isempty(cargs) && kind(first(cargs)) == K"curly"
            cargs = children(first(cargs))
        end
        argoffset, arg1 = 0, nothing
        for arg in something(cargs, typeof(node)[])
            argoffset += span(arg)
            if !JuliaSyntax.is_trivia(arg)
                arg1 = arg
                break
            end
        end
        argoffset = thisind(regionstr, argoffset)
        if isnothing(arg1)
        elseif kind(arg1) == K"Identifier" && pkind != K"function"
            region = first(region):first(region)+argoffset-1
            name = Symbol(view(regionstr, 1:argoffset))
            ifelse(name in BUILTIN_FUNCTIONS, F"builtin", F"funcall")
        elseif kind(arg1) == K"." && numchildren(arg1) == 3 && kind(arg1[end]) == K"Identifier"
            region = first(region)+argoffset-span(arg1[end]):first(region)+argoffset-1
            name = Symbol(view(regionstr, (1+argoffset-span(arg1[end])):argoffset))
            ifelse(name in BUILTIN_FUNCTIONS, F"builtin", F"funcall")
        end
    elseif syntax_errors && JuliaSyntax.is_error(nkind)
        F"error"
    elseif ((depthchange, ptype) = paren_type(nkind)) |> last != :none
        depthref = getfield(pdepths, ptype)
        pdepth = if depthchange > 0
            setfield!(pdepths, ptype, depthref + depthchange)
        else
            depth0 = getfield(pdepths, ptype)
            setfield!(pdepths, ptype, max(0, depthref + depthchange))
            depth0
        end
        if pdepth <= 0 && UNMATCHED_DELIMITERS_ENABLED[]
            F"unpaired_parentheses"
        elseif !RAINBOW_DELIMITERS_ENABLED[]
            F"parentheses"
        else
            displaydepth = mod1(pdepth, MAX_PAREN_HIGHLIGHT_DEPTH)
            parenfaces[(ptype, displaydepth)]
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
                               :face, F"code"))
        end
    elseif nkind == K"String"
        for match in eachmatch(r"\\.", regionstr)
            push!(highlights, (firstindex(content)+offset+match.offset-1:firstindex(content)+offset+match.offset+ncodeunits(match.match)-2,
                               :face, F"backslash_literal"))
        end
    end
    numchildren(node) == 0 && return
    lnode = node
    for child in something(children(node), typeof(node)[])
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
6-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value}}:
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((1:3, :face, F"funcall"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((4:4, :face, F"rainbow_paren_1"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((5:5, :face, F"number"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((6:6, :face, F"operator"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((7:7, :face, F"number"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((8:8, :face, F"rainbow_paren_1"))
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
6-element Vector{@NamedTuple{region::UnitRange{Int64}, label::Symbol, value}}:
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((1:3, :face, face"funcall"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((4:4, :face, face"rainbow_paren_1"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((5:5, :face, face"number"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((6:6, :face, face"operator"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((7:7, :face, face"number"))
 @NamedTuple{region::UnitRange{Int64}, label::Symbol, value}((8:8, :face, face"rainbow_paren_1"))
```
"""
function highlight!(str::AnnotatedString{<:Any, >:Face}; syntax_errors::Bool = false)
    for ann in _hl_annotations(str.string, parseall(GreenNode, str.string, ignore_errors=true); syntax_errors)
        annotate!(str, ann.region, ann.label, ann.value)
    end
    str
end

function highlight!(str::SubString{<:AnnotatedString{S, >:Face}}; syntax_errors::Bool = false) where {S}
    plainstr = SubString{S}(str.string.string, str.offset, str.ncodeunits, Val(:noshift))
    for ann in _hl_annotations(plainstr, parseall(GreenNode, plainstr, ignore_errors=true); syntax_errors)
        annotate!(str, ann.region, ann.label, ann.value)
    end
    str
end

if Base.generating_output()
    highlight(read(@__FILE__, String))
    highlight!(Base.AnnotatedString{String, Face}("1 + 2"))
    highlight!(Base.AnnotatedString{String, Face}("1 + 2")[1:5])
end

end
