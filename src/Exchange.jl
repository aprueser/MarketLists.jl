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

"""
```julia
getExchangeOptions()::Vector{String}
```
Get a List of all supported Exchanges.
These are the Exchanges for which the getExchangeMembers function will return values.

See [`getExchangeMembers`](@ref).

# Example
```julia
getExchangeOptions()
3-element Vector{String}:
 "NASDAQ"
 "NYSE"
 "AMEX"
```
"""
function getExchangeOptions()::Vector{String}
    return(validExchanges)
end

"""
```julia
getExchangeMembers(exchange::String)::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}
```
Get all Members of the given Exchange.  Supported Exchanges can be seen by calling the [`getExchangeOptions`](@ref) function.
This method calls the nasdaq API at https://api.nasdaq.com/api to get the data.

# Arguments
-- `exchange::String`: The name of the Exchange to fetch members for.

# Example
```julia
Getting Data ...
Dict{Symbol, Union{Int16, String, Vector{UInt8}}} with 3 entries:
  :code    => 200
  :message => "OK"
  :body    => "{\"data\":{\"headers\":{\"symbol\":\"Symbol\",\"name\":\"Name\",\"lastsale\":\"Last Sale\",\"netchange\":
  [...]
```
"""
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

"""
```julia
parseExchangeResponseToDataFrame(httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}, exchange::String)::DataFrame
```
Parse the JSON result from the [`getExchangeMembers`](@ref) function into a DataFrame.
If the [`getExchangeMembers`](@ref) function does not return HTTP 200, or the results can not be parsed the DataFrame will contain an error message.

# Arguments
-- `httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}`: The return from the [`getExchangeMembers`](@ref) function.
-- `exchange::String`: The name of the Exchange members were fetched for. This is used in determining how to parse the data.

# Example
```julia
parseExchangeResponseToDataFrame(e, "NYSE")
3012x11 DataFrame
  Row | symbol  name                               lastsale    netchange   pctchange volume   marketCap   country       ipoYear          industry                           sector
      | String  String                             Float64     Float64     Float64   Int64    Union       String        Nothing          String                             String
  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    1 | A       Agilent Technologies Inc. Common   140.33      -2.9        -2.025    1088380  4.1518e10   United States                  Electrical Products                Industrials
    2 | AA      Alcoa Corporation Common Stock      50.17      -3.52       -6.556    6297138  8.87854e9                                  Metal Fabrications                 Industrials
    3 | AAC     Ares Acquisition Corporation Cla    10.25      -0.01       -0.097      27539  1.28125e9                                  Blank Checks                       Finance
    4 | AAIC    Arlington Asset Investment Corp      3.04       0.01        0.33       62580  8.62347e7   United States                  Real Estate Investment Trusts      Real Estate
    [...]
```
"""
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
