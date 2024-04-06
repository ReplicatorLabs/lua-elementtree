-- enable warnings so we can see any relevant messages while running
-- tests or benchmarks through this script
warn("@on")

--[[
Imports
--]]

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
Command Line Interface
--]]

if os.getenv('LUA_ELEMENTTREE_LEAK_INTERNALS') ~= 'TRUE' then
  error("LUA_ELEMENTTREE_LEAK_INTERNALS environment variable must be 'TRUE' in order to run unit tests")
  os.exit(1)
end

-- run tests
os.exit(lu.LuaUnit.run())
