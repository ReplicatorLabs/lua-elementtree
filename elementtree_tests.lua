local lu <const> = require('luaunit/luaunit')
local et <const> = require('elementtree')

--[[
Utilities
--]]

local function countTableKeys(value)
  local keys = {}
  for key, _ in pairs(value) do
    table.insert(keys, key)
  end

  return #keys
end

--[[
Unit Tests
--]]

-- TODO

--[[
Integration Tests
--]]

-- TODO

--[[
Module Interface
--]]

return {}
