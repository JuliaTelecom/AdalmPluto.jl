using AdalmPluto
using Documenter

makedocs(;
    modules=[AdalmPluto],
    authors="Pierre Dénès <pdenes@enssat.fr> and contributors",
    repo="https://gitlab.inria.fr/x-pidenes/PlutoSDR.jl/blob/{commit}{path}#L{line}",
    sitename="AdalmPluto.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)
