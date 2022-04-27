# MarketLists

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://aprueser.github.io/MarketLists.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://aprueser.github.io/MarketLists.jl/dev)
[![Coverage](https://codecov.io/gh/aprueser/MarketLists.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/aprueser/MarketLists.jl)

> Inspired by the tq_index, and tq_exchange methods of R's tidyquant

## Introduction

MarketLists provides a convinience package to download set of stock symbols.  
There are 6 basic functions provided by MarketLists.

The two get**Options functions list the valid enchanges, and indexes handled by the other frunctions in the package
```Julia
getExchangeOptions()
3-element Vector{String}:
 "NASDAQ"
 "NYSE"
 "AMEX"

getIndexOptions()
12-element Vector{Pair{String, String}}:
 "CQQQ" => "China Tech ETF"
  "DGT" => "DOW Global"
  "DIA" => "DOW 30"
  "MDY" => "S&P 400"
 "ONEK" => "Russell 1000"
  "QQQ" => "Nasdaq 100"
  ...
```

The getExchangeMembers function downloads the current members of the given exchange in JSON format.
```Julia
  getExchangeMembers("NASDAQ")
  Dict{Symbol, Union{Int16, String, Vector{UInt8}}} with 3 entries:
    :code    => 200
    :message => "OK"
    :body    => "{\"data\":{\"headers\":{\"symbol ...
```

The getIndexMembersFile function downloads the current index ETF holdings as a file, which is stored in the system temp directory
```Julia
getIndexMembersFile("SPY")
Dict{Symbol, Union{Int16, String, Vector{UInt8}}} with 3 entries:
  :file    => "/tmp/holdings-daily-us-en-spy.xlsx"
  :code    => 200
  :message => "OK"
```

Finally there are 2 additional convienence functions to convert the Exchange JSON, and the Index ETF data to DataFrames.
- parseExchangeResponseToDataFrame
- parseIndexMembersFileToDataFrame