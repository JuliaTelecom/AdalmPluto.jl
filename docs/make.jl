using AdalmPluto
using Documenter

if haskey(ENV, "DOCSARGS")
    for arg in split(ENV["DOCSARGS"])
        (arg in ARGS) || push!(ARGS, arg)
    end
end

makedocs(;
    modules=[AdalmPluto, libIIO_jl],
    authors="JuliaTelecom and contributors",
    repo="https://github.com/JuliaTelecom/AdalmPluto.jl/blob/{commit}{path}#L{line}",
    sitename="AdalmPluto.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "AdalmPluto" => "adalmpluto.md",
        "libIIO_jl" => Any[
            "libiio/scan.md",
            "libiio/toplevel.md",
            "libiio/context.md",
            "libiio/device.md",
            "libiio/channel.md",
            "libiio/buffer.md",
            "libiio/debug.md",
            "libiio/structures.md",
            "libiio/helpers.md"
        ],
    ],
)

deploydocs(
    repo = "github.com/JuliaTelecom/AdalmPluto.jl.git",
    target = "build",
    push_preview = true,
)
