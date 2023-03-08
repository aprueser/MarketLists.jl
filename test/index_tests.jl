using DataFrames

@testset "General" begin
    sample404HTTPResp    = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(404), :message=>"Not Found", :file=>"")
    sampleNoFileHTTPResp = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(200), :message=>"OK", :file=>"doesNotExist.xlsx")

    @test length(MarketLists.getIndexOptions()) == MarketLists.numIndexes                          skip = false
    @test MarketLists.parseIndexMembersFileToDataFrame(sample404HTTPResp, "DIA") isa DataFrame     skip = false
    @test MarketLists.parseIndexMembersFileToDataFrame(sampleNoFileHTTPResp, "DIA") isa DataFrame  skip = false
end

@testset "State Street" begin
    sampleIndex    = "DIA"
    sampleHTTPResp = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(200), :message=>"OK", :file=>"./sample/holdings-daily-us-en-dia.xlsx")

    @test MarketLists.getIndexMembersFile(sampleIndex) isa Dict{Symbol, Union{String, Int16, Vector{UInt8}}} skip = false
    @test MarketLists.parseIndexMembersFileToDataFrame(sampleHTTPResp, sampleIndex) isa DataFrame            skip = false
end

@testset "Invesco" begin
    sampleIndex    = "QQQ"
    sampleHTTPResp = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(200), :message=>"OK", :file=>"./sample/holdings-daily-us-en-qqq.xlsx")

    @test MarketLists.getIndexMembersFile(sampleIndex) isa Dict{Symbol, Union{String, Int16, Vector{UInt8}}} skip = false
    @test MarketLists.parseIndexMembersFileToDataFrame(sampleHTTPResp, sampleIndex) isa DataFrame            skip = false
end
