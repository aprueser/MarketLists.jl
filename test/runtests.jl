using MarketLists
using Test

@testset verbose = true "MarketLists.Exchange" begin
    include("exchange_tests.jl")
end

@testset verbose = true "MarketLists.Index" begin
    include("index_tests.jl")
end
