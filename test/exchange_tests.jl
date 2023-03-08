using DataFrames

sampleExchange = "NYSE"
@testset "General" begin
    badSampleHTTPResp = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(200), :message=>"OK", :body=>"{}")

    @test MarketLists.getExchangeOptions() == MarketLists.validExchanges                                                                                                    skip = false
    @test MarketLists.parseExchangeResponseToDataFrame(badSampleHTTPResp, sampleExchange)[1, :results] == "Could not get exchange members for exchange: " * sampleExchange  skip = false
end

@testset "Exchange" begin
    sampleFile     = read("./sample/getExchangeMember.json", String)
    sampleHTTPResp = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code=>Int16(200), :message=>"OK", :body=>sampleFile)

    @test MarketLists.getExchangeMembers(sampleExchange) isa Dict{Symbol, Union{String, Int16, Vector{UInt8}}}  skip = false

    @test MarketLists.parseExchangeResponseToDataFrame(sampleHTTPResp, sampleExchange) isa DataFrame            skip = false
    @test size(MarketLists.parseExchangeResponseToDataFrame(sampleHTTPResp, sampleExchange))[1] > 10            skip = false

end
