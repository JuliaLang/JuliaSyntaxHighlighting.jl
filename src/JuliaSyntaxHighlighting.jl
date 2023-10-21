module JuliaSyntaxHighlighting

import Base: JuliaSyntax, AnnotatedString, annotate!
import Base.JuliaSyntax: var"@K_str", Kind, Tokenize, tokenize
import .Tokenize: kind, untokenize
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

function _hl_annotations(content::AbstractString, tokens)
    highlighted = Vector{Tuple{UnitRange{Int}, Pair{Symbol, Any}}}()
    lastk, last2k = K"None", K"None"
    lastf, last2f = :none, :none
    function paren_type(k)
        if     k == K"(";  1, :paren
        elseif k == K")"; -1, :paren
        elseif k == K"[";  1, :bracket
        elseif k == K"]"; -1, :bracket
        elseif k == K"{";  1, :curly
        elseif k == K"}"; -1, :curly
        else               0, :none
        end
    end
    depthcounters = (paren = Ref(0), bracket = Ref(0), curly = Ref(0))
    for (; head::JuliaSyntax.SyntaxHead, range::UnitRange{UInt32}) in tokens
        range = first(range):thisind(content, last(range))
        kind = head.kind
        face = if kind == K"Identifier"
            if lastk == K":" && !JuliaSyntax.is_number(last2k) &&
                last2k ∉ (K"Identifier", K")", K"]", K"end", K"'")
                highlighted[end] = (highlighted[end][1], :face => :julia_symbol)
                :julia_symbol
            elseif lastk == K"::"
                :julia_type
            elseif lastk ∈ (K".", K"{") && last2f == :julia_type
                :julia_type
            elseif view(content, range) in SINGLETON_IDENTIFIERS
                :julia_singleton_identifier
            elseif view(content, range) == "NaN"
                :julia_number
            else
                :julia_identifier
            end
        elseif kind == K"@"; :julia_macro
        elseif kind == K"MacroName"; :julia_macro
        elseif kind == K"StringMacroName"; :julia_macro
        elseif kind == K"CmdMacroName"; :julia_macro
        elseif kind == K"::"; :julia_type
        elseif kind == K"Comment"; :julia_comment
        elseif kind == K"String"; :julia_string
        elseif JuliaSyntax.is_string_delim(kind); :julia_string_delim
        elseif kind == K"CmdString"; :julia_cmdstring
        elseif kind == K"`" || kind == K"```"; :julia_cmdstring
        elseif kind == K"Char"
            lastk == K"'" &&
                (highlighted[end] = (highlighted[end][1], :face => :julia_char_delim))
            :julia_char
        elseif kind == K"'" && lastk == K"Char"; :julia_char_delim
        elseif kind == K"true" || kind == K"false"; :julia_bool
        elseif JuliaSyntax.is_number(kind); :julia_number
        elseif JuliaSyntax.is_prec_assignment(kind); :julia_assignment
        elseif JuliaSyntax.is_prec_comparison(kind); :julia_comparator
        elseif JuliaSyntax.is_operator(kind); :julia_operator
        elseif JuliaSyntax.is_keyword(kind); :julia_keyword
        elseif JuliaSyntax.is_error(kind); :julia_error
        elseif ((depthchange, ptype) = paren_type(kind)) |> last != :none
            if kind == K"(" && lastk == K"Identifier"
                highlighted[end] = (highlighted[end][1], :face => :julia_funcall)
            end
            depthref = getfield(depthcounters, ptype)[]
            pdepth = if depthchange > 0
                getfield(depthcounters, ptype)[] += depthchange
            else
                depth0 = getfield(depthcounters, ptype)[]
                getfield(depthcounters, ptype)[] += depthchange
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
        isnothing(face) || push!(highlighted, (range, :face => face))
        last2k, lastk = lastk, kind
        last2f, lastf = lastf, face
    end
    highlighted
end

"""
    highlight(content::Union{AbstractString, IOBuffer, IOContext{IOBuffer}})

Apply syntax highlighting to `content` using `JuliaSyntax`.

Returns an `AnnotatedString{String}`.
"""
highlight(str::AbstractString) =
    AnnotatedString(str, _hl_annotations(str, tokenize(str)))

function highlight(buf::IOBuffer)
    pos = position(buf)
    eof(buf) && seekstart(buf)
    str = read(buf, String)
    seek(buf, pos)
    highlight(str)
end

highlight(buf::IOContext{IOBuffer}) = highlight(buf.io)

"""
    highlight!(content::Union{AnnotatedString, SubString{AnnotatedString}})

Modify `content` by applying syntax highlighting using `JuliaSyntax`.
"""
function highlight!(str::AnnotatedString)
    for (range, annot) in _hl_annotations(str.string, tokenize(str.string))
        annotate!(str, range, annot)
    end
    str
end

function highlight!(str::SubString{AnnotatedString{S}}) where {S}
    plainstr = SubString{S}(str.string.string, str.offset, str.ncodeunits, Val(:noshift))
    for (range, annot) in _hl_annotations(plainstr, tokenize(plainstr))
        annotate!(str, range, annot)
    end
    str
end

end
