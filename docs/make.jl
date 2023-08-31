using MakieTreeMaps
using Documenter

DocMeta.setdocmeta!(MakieTreeMaps, :DocTestSetup, :(using MakieTreeMaps); recursive=true)

makedocs(;
    modules=[MakieTreeMaps],
    authors="Julius Krumbiegel <julius.krumbiegel@gmail.com> and contributors",
    repo="https://github.com/jkrumbiegel/MakieTreeMaps.jl/blob/{commit}{path}#{line}",
    sitename="MakieTreeMaps.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jkrumbiegel.github.io/MakieTreeMaps.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jkrumbiegel/MakieTreeMaps.jl",
    devbranch="main",
)
