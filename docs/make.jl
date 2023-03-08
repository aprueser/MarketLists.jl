push!(LOAD_PATH, "../src/")

using MarketLists
using Documenter

DocMeta.setdocmeta!(MarketLists, :DocTestSetup, :(using MarketLists); recursive=true)

makedocs(;
    modules=[MarketLists],
    authors="Andrew Prueser <aprueser@gmail.com> and contributors",
    repo="https://github.com/aprueser/MarketLists.jl/blob/{commit}{path}#{line}",
    sitename="MarketLists.jl",
    format=Documenter.HTML(;
        edit_link="main",
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://aprueser.github.io/MarketLists.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Exchange"   => "exchange.md",
        "Index ETF"  => "indexes.md",
    ],
)

deploydocs(;
    repo="github.com/aprueser/MarketLists.jl",
    devbranch="main",
    devurl="dev",
    versions=["stable" => "v^", "v#.#", "dev" => "dev"]
)
