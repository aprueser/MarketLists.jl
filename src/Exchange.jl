validExchanges = ["NASDAQ", "NYSE", "AMEX"]
nasdaqAPIUrl = "https://api.nasdaq.com/api"

struct exchangeMember
    symbol::String
    name::String
    lastsale::String
    netchange::String
    pctchange::String
    volume::String
    marketCap::String
    country::String
    ipoYear::Union{String, Nothing}
    industry::String
    sector::String
end

function getExchangeOptions()::Vector{String}
    return(validExchanges)
end

function getExchangeMembers(exchange::String)::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}
    @argcheck exchange in validExchanges

    exchange = lowercase(strip(exchange));

    println("Getting Data ...");

    NASDAQurl = nasdaqAPIUrl * "/screener/stocks?tableonly=true&exchange=" * exchange * "&download=true";
    uri = HTTP.URI(NASDAQurl);

    result = HTTP.request("GET", string(uri), status_exception=false);

    res = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code => result.status, 
                                                            :message => HTTP.statustext(result.status), 
                                                            :body => String(result.body))

    return(res)
end

function parseExchangeResponseToDataFrame(httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}, exchange::String)::DataFrame

    if haskey(httpRet, :code) && httpRet[:code] == 200
        ljson = LazyJSON.value(httpRet[:body])

        if length(ljson) > 0
            v = Vector{exchangeMember}()

            for r in ljson["data"]["rows"]
                rc = convert(exchangeMember, r)
                push!(v, rc)
            end

            df = DataFrame(v, copycols = false);
            @transform! df begin
                :lastsale = replace.(:lastsale, '$' => "")
                :pctchange = replace.(:pctchange, '%' => "")
            end

            @transform! df begin
                :symbol = String.(strip.(:symbol))
                :lastsale = tryparse.(Float64, :lastsale)
                :netchange = tryparse.(Float64, :netchange)
                :pctchange = tryparse.(Float64, :pctchange)
                :volume = tryparse.(Int64, :volume)
                :marketCap = tryparse.(Float64, :marketCap)
            end
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "Could not get exchange members for exchange: " * exchange])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => httpRet[:body]])
    end

    return(df)
end