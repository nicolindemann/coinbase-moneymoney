-- Inofficial Coinbase Extension (www.coinbase.com) for MoneyMoney
-- Fetches balances from Coinbase API and returns them as securities
--
-- Username: Coinbase API Key
-- Password: Coinbase API Secret
--
-- Copyright (c) 2020 Martin Wilhelmi
-- Copyright (c) 2017 Nico Lindemann
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking {
  version = 1.8,
  url = "https://api.coinbase.com",
  description = "Fetch balances from Coinbase API and list them as securities",
  services = { "Coinbase Account" },
}

local apiKey
local apiSecret
local currency
local balances
local prices
local apiUrlVersion = "v2"
local apiHeaderVersion = "2021-01-25"
local market = "Coinbase"
local accountNumber = "Main"

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Coinbase Account"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  apiKey = username
  apiSecret = password
  currency = queryPrivate("user")["native_currency"]
end

function ListAccounts (knownAccounts)
  local account = {
    name = market,
    accountNumber = accountNumber,
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  accounts = queryPrivate("accounts?limit=100")
  exchange_rates = queryPublic("exchange-rates", "?currency=" .. currency)

  for key, value in pairs(accounts) do
    
    if exchange_rates["rates"][value["currency"]["code"]] then
      if value["type"] == "fiat" then
        s[#s+1] = {
          name = value["currency"]["name"] .. " (" .. value["name"] .. ")",
          market = market,
          currency = currency,
          amount = value["balance"]["amount"]
        }
      else

        price = (1 / exchange_rates["rates"][value["currency"]["code"]])
        quantity = value["balance"]["amount"]

        if tonumber(quantity) ~= 0 then

          s[#s+1] = {
            name = value["currency"]["name"] .. " (" .. value["name"] .. ")",
            market = market,
            quantity = quantity,
            amount = price * quantity,
            price = price
          }
        end
      end
    end
  end

  return {securities = s}
end

function EndSession ()
end

function bin2hex(s)
 return (s:gsub(".", function (byte)
   return string.format("%02x", string.byte(byte))
 end))
end

function queryPrivate(method)
  local path = string.format("/%s/%s", apiUrlVersion, method)
  local timestamp = string.format("%d", MM.time())
  local apiSign = MM.hmac256(apiSecret, timestamp .. "GET" .. path)
  local headers = {}

  headers["CB-ACCESS-KEY"] = apiKey
  headers["CB-ACCESS-TIMESTAMP"] = timestamp
  headers["CB-ACCESS-SIGN"] = bin2hex(apiSign)
  headers["CB-VERSION"] = apiHeaderVersion

  connection = Connection()
  content = connection:request("GET", url .. path, nil, nil, headers)

  json = JSON(content)

  return json:dictionary()["data"]
end

function queryPublic(method, query)
  local path = string.format("/%s/%s", apiUrlVersion, method)

  connection = Connection()
  content = connection:request("GET", url .. path .. query)
  json = JSON(content)

  return json:dictionary()["data"]
end
