using JuliaSyntaxHighlighting
using Documenter

DocMeta.setdocmeta!(JuliaSyntaxHighlighting, :DocTestSetup, :(using JuliaSyntaxHighlighting); recursive=true)

makedocs(;
    modules = [JuliaSyntaxHighlighting],
    sitename = "Julia Syntax Highlighting",
    authors = "tecosaur <contact@tecosaur.net> and contributors",
    repo = "https://github.com/JuliaLang/JuliaSyntaxHighlighting.jl/blob/{commit}{path}#{line}",
    format = Documenter.HTML(ansicolor = true),
    pages = [
        "JuliaSyntaxHighlighting" => "index.md",
        "Internals" => "internals.md",
    ],
    warnonly = [:cross_references],
)

deploydocs(repo="github.com/JuliaLang/JuliaSyntaxHighlighting.jl",
           push_preview = true)
