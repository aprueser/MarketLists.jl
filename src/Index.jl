validIndexes = Dict{String, Dict{String, String}}( 
    "SMD"        => Dict("name" => "S&P 1000",    "manager" => "ssga"),
    "SLY"        => Dict("name" => "S&P 600",     "manager" => "ssga"),
    "SPY"        => Dict("name" => "S&P 500",     "manager" => "ssga"),
    "MDY"        => Dict("name" => "S&P 400",     "manager" => "ssga"),
    "DGT"        => Dict("name" => "DOW Global",  "manager" => "ssga"),
    "DIA"        => Dict("name" => "DOW 30",      "manager" => "ssga"),
    "ONEK"       => Dict("name" => "Russell 1000",  "manager" => "ssga"),
    "TWOK"       => Dict("name" => "Russell 2000",  "manager" => "ssga"),
    "THRK"       => Dict("name" => "Russell 3000",  "manager" => "ssga"), 
    "QQQ"        => Dict("name" => "Nasdaq 100",    "manager" => "invesco"),
    "QQQJ"       => Dict("name" => "Nasdaq Next Gen 100",  "manager" => "invesco"),
    "CQQQ"       => Dict("name" => "China Tech ETF",       "manager" => "invesco")
)                          

numIndexes = 12

holdingsFile = "holdings-daily-us-en-{index}.xlsx"
stateStreetHoldingsURL  = "https://www.ssga.com/library-content/products/fund-data/etfs/us/";
invescoHoldingsURL      = "https://www.invesco.com/us/financial-products/etfs/holdings/main/holdings/0?audienceType=Investor&action=download&ticker={index}"

"""
```julia
function getIndexOptions()::Vector{Pair{String, String}}
```
Get a list of all supported Index ETFs
These are the ETF symbols for which the getIndexMembersFile function will return values.

See [`getIndexMembersFile`](@ref).


# Example
```julia
getIndexOptions()
12-element Vector{Pair{String, String}}:
 "CQQQ" => "China Tech ETF"
  "DGT" => "DOW Global"
  "DIA" => "DOW 30"
  "MDY" => "S&P 400"
 "ONEK" => "Russell 1000"
  "QQQ" => "Nasdaq 100"
 "QQQJ" => "Nasdaq Next Gen 100"
  "SLY" => "S&P 600"
  "SMD" => "S&P 1000"
  "SPY" => "S&P 500"
 "THRK" => "Russell 3000"
 "TWOK" => "Russell 2000"
```
"""
function getIndexOptions()::Vector{Pair{String, String}}
    v = Vector{Pair{String, String}}()

    for k::String in keys(validIndexes)
        push!(v, Pair(k, validIndexes[k]["name"]))
    end

    return(sort(v))
end


"""
```julia
getIndexMembersFile(index::String)::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}
```
Get all Members of the given Index ETF.  Supported ETFs can be seen by calling the [`getIndexOptions`](@ref) function.
This method used the [State Street Global Advisors](https://www.ssga.com/), and [Invesco](https://www.invesco.com) web pages to look up the ETF Membership information.

The results will be saved in an XSLX file for symbols serviced from State Street, and CSV for those from Invesco.

# Arguments
-- `index::String`: The name of the Index ETF to fetch members for. 

# Example
```julia
i = getIndexMembersFile("DIA")
Getting holdings for DIA ... 
Dict{Symbol, Union{Int16, String, Vector{UInt8}}} with 3 entries:
  :file    => "/tmp/holdings-daily-us-en-dia.xlsx"
  :code    => 200
  :message => "OK"
```
"""
function getIndexMembersFile(index::String)::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}
    @argcheck haskey(validIndexes, strip(index))

    index = strip(index);

    println("Getting holdings for " * index * " ... ");

    indexDef = validIndexes[index];
    index    = lowercase(index)

    indexHoldingsFile = replace(holdingsFile, "{index}" => index);
    if indexDef["manager"] == "ssga"
        indexHoldingsUrl  = stateStreetHoldingsURL * indexHoldingsFile;
    else
        indexHoldingsUrl  = replace(invescoHoldingsURL, "{index}" => index);
    end

    uri = HTTP.URI(indexHoldingsUrl);

    xlsxIO = io = open(tempdir() * Base.Filesystem.path_separator * indexHoldingsFile, "w")
    result = HTTP.request("GET", string(uri), status_exception=false, response_stream=xlsxIO)
    close(xlsxIO)

    res = Dict{Symbol, Union{String, Int16, Vector{UInt8}}}(:code => result.status, 
                                                            :message => HTTP.statustext(result.status), 
                                                            :file => tempdir() * Base.Filesystem.path_separator * indexHoldingsFile)
    
    return(res)
end

"""
```julia
parseIndexMembersFileToDataFrame(httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}, index::String)::DataFrame
```
Parse the file downloaded when calling the [`getIndexMembersFile`](@ref) function.

# Arguments
-- `httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}`: The return from the [`getIndexMembersFile`](@ref) function.
-- `index::String`: The name of the Index ETF members were fetched for. This is used in determining how to parse the data.

# Example
```julia
parseIndexMembersFileToDataFrame(i, "DIA")
31x8 DataFrame
 Row | symbol    name                               Identifier  SEDOL       Weight    Sector                  SharesHeld   Local Currency
     | String    String                             String      String      Float64   String                  Float64      String
 ----------------------------------------------------------------------------------------------------------------------------------------
   1 | UNH       UnitedHealth Group Incorporated    91324P10    2917766     9.47776   Health Care               5.64911e6  USD
   2 | GS        Goldman Sachs Group Inc.           38141G10    2407966     7.03863   Financials                5.64911e6  USD
   3 | HD        Home Depot Inc.                    43707610    2434209     5.8787    Consumer Discretionary    5.64911e6  USD
   4 | MCD       McDonald's Corporation             58013510    2550707     5.33521   Consumer Discretionary    5.64911e6  USD

```
"""
function parseIndexMembersFileToDataFrame(httpRet::Dict{Symbol, Union{String, Int16, Vector{UInt8}}}, index::String)::DataFrame

    if haskey(httpRet, :code) && httpRet[:code] == 200
        holdingsFile = httpRet[:file]

        indexDef = validIndexes[index];

        if length(holdingsFile) > 0 && isfile(holdingsFile)
            df = DataFrame();

            if indexDef["manager"] == "ssga"
                df = DataFrame(XLSX.readtable(holdingsFile, "holdings", stop_in_empty_row=false, first_row=5, header=true, infer_eltypes=true))
            
                dropmissing!(df, :Weight)
                disallowmissing!(df)
                rename!(df, Symbol("Shares Held") => "SharesHeld")

                @transform! df begin
                    :Weight = tryparse.(Float64, :Weight)
                    :SharesHeld = tryparse.(Float64, :SharesHeld)
                end

                @subset! df :Ticker .!= "CASH_USD" 

                @select! df :symbol = String.(strip.(:Ticker)) :name = :Name $(Not([:Ticker, :Name]))
            else
                df = DataFrame(CSV.File(holdingsFile, normalizenames=true, ignoreemptyrows=true, dateformat="mm/dd/yyyy", 
                                        types=[String, String, String, String, String, Float64, String, String, String, Dates.Date]))
               
                @transform! df begin
                    :Shares_Par_Value = tryparse.(Int64, replace.(:Shares_Par_Value, "," => ""))
                    :MarketValue = tryparse.(Float64, replace.(:MarketValue, "," => ""))
                end

                @subset! df :Class_of_Shares .!= "Currency"

                @select! df :symbol = String.(strip.(:Holding_Ticker)) :indexSymbol = :Fund_Ticker :name = :Name $(Not([:Holding_Ticker, :Fund_Ticker, :Name]))
            end
            

            
        else
            df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => "Could not get index members for index: " * index])
        end
    else
        df = DataFrame([:httpCode => httpRet[:code], :httpMessage => httpRet[:message], :results => ""])
    end

    return(df)

end
