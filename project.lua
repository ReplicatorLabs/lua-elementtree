#!/usr/bin/env lua

-- enable warnings so we can see any relevant messages while running
-- tests or benchmarks through this script
warn("@on")

-- luaunit captures the value of the interpreter arguments on import which
-- makes it hard to implement a custom command line interface so store the
-- argument in a separate local table before importing it
local LUA_INTERPRETER_ARGS <const> = assert(arg, "interpreter arguments are missing")
arg = nil

--[[
Imports
--]]

local lu <const> = require('luaunit/luaunit')
local et <const> = require('elementtree')
local tests <const> = require('elementtree_tests')

--[[
Command Line Interface
--]]

-- run unit and integration tests
local function cli_test(...)
  if os.getenv('LUA_ELEMENTTREE_LEAK_INTERNALS') ~= 'TRUE' then
    error("LUA_ELEMENTTREE_LEAK_INTERNALS environment variable must be 'TRUE' in order to run tests")
    os.exit(1)
  end

  os.exit(lu.LuaUnit.run(...))
end

-- load and dump a local file to verify the library can interpret it correctly
local function cli_check(filename)
  if not filename or string.len(filename) == 0 then
    print("filename required")
    os.exit(1)
  end

  local extension <const> = string.match(filename, '%.([^%.]+)$')
  if not extension then
    print("failed to detect file extension")
    os.exit(1)
  end

  local extension_handlers <const> = {
    ['html']=et.HTML5,
    ['svg']=et.SVG,
  }

  local handler <const> = extension_handlers[extension]
  if not handler then
    print("unsupported document extension: " .. extension)
    os.exit(1)
  end

  local input_file <close> = assert(io.open(filename, 'r'))
  local input_data <const> = assert(input_file:read('a'))
  assert(input_file:close())

  local document <const> = handler.load_string(input_data)
  document.root:freeze()

  local output_data <const> = handler.dump_string(document)
  print(output_data)
end

-- minimal command line interface
local CLI_USAGE_HELP <const> = [[
<command> [args]

commands:
  test [LuaUnit args]     run unit and integration tests
  check <filename>        parse and display a file using the library
]]

if #LUA_INTERPRETER_ARGS == 0 then
  print(LUA_INTERPRETER_ARGS[0] .. " " .. CLI_USAGE_HELP)
  os.exit(0)
end

local COMMANDS <const> = {
  ['test']=cli_test,
  ['check']=cli_check,
}

local command <const> = LUA_INTERPRETER_ARGS[1]
local command_handler <const> = COMMANDS[command]
if not command_handler then
  print("invalid command: " .. command)
  os.exit(1)
end

local command_arguments <const> = {}
for index, argument in ipairs(LUA_INTERPRETER_ARGS) do
  if index > 1 then
    table.insert(command_arguments, argument)
  end
end

command_handler(table.unpack(command_arguments))
