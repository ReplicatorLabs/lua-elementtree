--[[
Lua Version Check
--]]

local supported_lua_versions <const> = {['Lua 5.4']=true}
if not supported_lua_versions[_VERSION] then
  warn("lua-elementtree: detected unsupported lua version: " .. tostring(_VERSION))
end

--[[
Comment
--]]

local comment_metatable <const> = {}
local comment_private <const> = setmetatable({}, {__mode='k'})

-- implementation
local comment_internal_metatable <const> = {
  __name = 'Comment',
  __metatable = comment_metatable,
  __index = function (self, key)
    local private <const> = assert(comment_private[self], "Comment instance not recognized: " .. tostring(self))

    -- content
    if key == 'content' then
      return private.content
    -- invalid key
    else
      error("Comment invalid key: " .. key)
    end
  end,
  __newindex = function (self, key, value)
    local private <const> = assert(comment_private[self], "Comment instance not recognized: " .. tostring(self))

    -- content
    if key == 'content' then
      if type(value) ~= 'string' or string.len(value) == 0 then
        error("Comment content must be a non-empty string")
      end

      private.content = value
    -- invalid key
    else
      error("Comment invalid key: " .. key)
    end
  end,
  __gc = function (self)
    comment_private[self] = nil
  end
}

-- public interface
local Comment <const> = setmetatable({
  create = function (content)
    if type(content) ~= 'string' or string.len(content) == 0 then
      error("Comment content must be a non-empty string")
    end

    local instance <const> = {}
    comment_private[instance] = {content=content}

    return setmetatable(instance, comment_internal_metatable)
  end,
  is = function (value)
    return (getmetatable(value) == comment_metatable)
  end
}, {
  __call = function (self, ...)
    return self.create(...)
  end
})

--[[
Node
--]]

local node_metatable <const> = {}
local node_private <const> = setmetatable({}, {__mode='k'})

-- implementation
local node_internal_metatable <const> = {
  __name = 'Node',
  __metatable = node_metatable,
  __index = function (self, key)
    local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))

    -- tag
    if key == 'tag' then
      return private.tag
    -- shallow copy of attribute table
    elseif key == 'attributes' then
      local attributes <const> = {}
      for name, value in pairs(private.attributes) do
        attributes[name] = value
      end

      return attributes
    -- shallow copy of children array
    elseif key == 'children' then
      local children <const> = {}
      for _, child in ipairs(private.children) do
        table.insert(children, child)
      end

      return children
    -- emulate an array to expose children
    elseif math.type(key) == 'integer' then
      return private.children[key]
    -- invalid key
    else
      error("Node invalid key: " .. key)
    end
  end,
  __newindex = function (self, key, value)
    local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))

    -- tag
    if key == 'tag' then
      if type(value) ~= 'string' or string.len(value) then
        error("Node tag must be a non-empty string")
      end

      private.tag = value
    -- attribute table
    elseif key == 'attributes' then
      -- TODO: implement wrapper functions
      error("Node attributes cannot be modified directly")
    -- children table
    elseif key == 'children' then
      -- TODO: implement wrapper functions
      error("Node children cannot be modified directly")
    -- invalid key
    else
      error("Node invalid key: " .. key)
    end
  end,
  __len = function (self)
    -- emulate an array to expose children
    return #private.children
  end,
  __gc = function (self)
    node_private[self] = nil
  end
}

-- public interface
local Node <const> = setmetatable({
  create = function (tag, attributes, children)
    -- XXX: consider validating tag more strictly?
    if type(tag) ~= 'string' or string.len(tag) == 0 then
      error("Node tag must be a non-empty string")
    end

    if type(attributes) ~= 'table' then
      error("Node attributes must be a table")
    end

    for name, value in pairs(attributes) do
      if type(name) ~= 'string' or type(value) ~= 'string' then
        error("Node attribute names and values must be strings")
      end
    end

    local children <const> = children or {}
    if type(children) ~= 'table' then
      error("Node children must be nil or a table")
    end

    for _, child in ipairs(children) do
      if type(child) == 'string' then
        if string.len(child) == 0 then
          error("Node child is an empty string")
        end
      -- XXX: can't use Node.is() here since it hasn't been defined yet
      elseif getmetatable(child) == node_metatable then
        -- nothing to check
      elseif Comment.is(child) then
        -- nothing to check
      else
        error("Node children must be Comment instances, Node instances, or non-empty strings")
      end
    end

    local instance <const> = {}
    node_private[instance] = {
      tag=tag,
      attributes=attributes,
      children=children
    }

    return setmetatable(instance, node_internal_metatable)
  end,
  is = function (value)
    return (getmetatable(value) == node_metatable)
  end
}, {
  __call = function (self, ...)
    return self.create(...)
  end
})

--[[
Document
--]]

local document_metatable <const> = {}
local document_private <const> = setmetatable({}, {__mode='k'})

-- implementation
local document_internal_metatable <const> = {
  __name = 'Document',
  __metatable = document_metatable,
  __index = function (self, key)
    local private <const> = assert(document_private[self], "Document instance not recognized: " .. tostring(self))

    -- root node
    if key == 'root' then
      return private.root
    -- invalid key
    else
      error("Document invalid key: " .. key)
    end
  end,
  __newindex = function (self, key, value)
    local private <const> = assert(document_private[self], "Document instance not recognized: " .. tostring(self))

    -- root node
    if key == 'root' then
      if not Node.is(value) then
        error("Document root must be a Node instance")
      end

      private.root = value
    -- invalid key
    else
      error("Document invalid key: " .. key)
    end
  end,
  __gc = function (self)
    document_private[self] = nil
  end
}

-- public interface
local Document <const> = setmetatable({
  create = function (data)
    local root <const> = data['root']

    if not Node.is(root) then
      error("Document root must be a Node instance")
    end

    local instance <const> = {}
    document_private[instance] = {
      root=root
    }

    return setmetatable(instance, document_internal_metatable)
  end,
  is = function (value)
    return (getmetatable(value) == document_metatable)
  end
}, {
  __call = function (self, ...)
    return self.create(...)
  end
})

local function document_load_string(value, settings)
  if type(value) ~= 'string' or string.len(value) == 0 then
    return nil, "value must be a non-empty string"
  end

  if type(settings) ~= 'table' then
    error("document_load_string settings must be a table")
  end

  -- TODO: implement this
  error("loading documents is not yet implemented")
end

local function node_dump_attributes(node)
  assert(Node.is(node), "value must be a Node instance")

  local names <const> = {}
  for name, _ in pairs(node.attributes) do
    assert(type(name) == 'string', "node attribute name must be a string")
    table.insert(names, name)
  end

  -- serialize attributes in a consistent order
  table.sort(names)

  local parts <const> = {}
  for _, name in ipairs(names) do
    local value <const> = node.attributes[name]
    assert(type(value) == 'string', "node attribute value must be a string")

    -- TODO: handle naked attributes with no value
    table.insert(parts, name .. '="' .. value .. '"')
  end

  return table.concat(parts, ' ')
end

local function document_dump_string(document, settings)
  if not Document.is(document) then
    return nil, "value must be a Document instance"
  end

  assert(type(settings) == 'table', "document_dump_string settings must be a table")
  local header_lines <const> = settings['header_lines'] or {}
  local indent <const> = settings['indent'] or ' '
  local leaf_tags <const> = settings['leaf_tags'] or {}

  assert(type(header_lines) == 'table', "header_lines setting must be a table")
  assert(type(indent) == 'string', "indent setting must be a string")
  assert(type(leaf_tags) == 'table', "leaf_tags setting must be a table")

  -- XXX: serialize by lines for performance
  local lines <const> = {}
  for _, line in ipairs(header_lines) do
    table.insert(lines, line)
  end

  -- XXX: initial stack used as FIFO with current node on top
  local stack <const> = {{level=0, node=document.root, children=nil}}

  -- XXX: serialization loop
  while #stack > 0 do
    local entry <const> = stack[#stack]
    local node <const> = entry.node

    if type(node) == 'string' then
      -- XXX: refactor this out somewhere
      -- split text content by newlines and indent each newline to the appropriate level
      for line in string.gmatch(node, "([^\n]+)") do
        table.insert(lines, string.rep(indent, entry.level) .. line)
      end

      table.remove(stack)
      goto next_node
    end

    if Comment.is(node) then
      table.insert(lines, string.rep(indent, entry.level) ..  '<!--')

      -- XXX: refactor this out somewhere
      -- split text content by newlines and indent each newline to the appropriate level
      for line in string.gmatch(node.content, "([^\n]+)") do
        table.insert(lines, string.rep(indent, entry.level) .. line)
      end

      table.insert(lines, string.rep(indent, entry.level) .. '-->')
      table.remove(stack)
      goto next_node
    end

    if not entry.children then
      local parts <const> = {
        string.rep(indent, entry.level),
        '<',
        node.tag,
        '>'
      }

      local attributes <const> = node_dump_attributes(node)
      if #attributes > 0 then
        table.insert(parts, #parts, ' ' .. attributes)
      end

      table.insert(lines, table.concat(parts, ''))

      if leaf_tags[node.tag] then
        if #node.children > 0 then
          return nil, "leaf element '" .. node.tag .. "' has children"
        end

        table.remove(stack)
      else
        entry.children = node.children
      end

      goto next_node
    end

    if #entry.children == 0 then
      table.insert(lines, string.rep(indent, entry.level) .. '</' .. node.tag .. '>')
      table.remove(stack)
      goto next_node
    end

    -- retrieve the next child to serialize in array order
    local child <const> = table.remove(entry.children, 1)
    table.insert(stack, {level=(entry.level + 1), node=child})

    ::next_node::
  end

  return table.concat(lines, '\n')
end

--[[
HTML5
--]]

local HTML5 <const> = {}
local HTML5_SETTINGS <const> = {
  header_lines={'<!DOCTYPE html>'},
  indent='  ',
  -- https://html.spec.whatwg.org/multipage/syntax.html#elements-2
  -- TODO: handle raw text elements (script, style)
  -- TODO: handle escapable raw text elements (textarea, title)
  leaf_tags={
    ['area']=true,
    ['base']=true,
    ['br']=true,
    ['col']=true,
    ['embed']=true,
    ['hr']=true,
    ['img']=true,
    ['input']=true,
    ['link']=true,
    ['meta']=true,
    ['source']=true,
    ['track']=true,
    ['wbr']=true
  }
}

function HTML5.load_string(value)
  return assert(document_load_string(value, HTML5_SETTINGS))
end

function HTML5.dump_string(document)
  return assert(document_dump_string(document, HTML5_SETTINGS))
end

--[[
SVG
--]]

local SVG <const> = {}
local SVG_SETTINGS <const> = {
  header_lines={
    '<?xml version="1.0" encoding="UTF-8"?>'
    -- XXX: does SVG need a doctype?
    -- '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">'
  },
  indent='  ',
  leaf_tags={}
}

function SVG.load_string(value)
  return assert(document_load_string(value, SVG_SETTINGS))
end

function SVG.dump_string(document)
  return assert(document_dump_string(document, SVG_SETTINGS))
end

--[[
Module Interface
--]]

local module = {
  Comment=Comment,
  Node=Node,
  Document=Document,

  HTML5=HTML5,
  SVG=SVG
}

if os.getenv('LUA_ELEMENTTREE_LEAK_INTERNALS') == "TRUE" then
  -- leak internal variables and methods in order to unit test them from outside
  -- of this module but at least we can use an obvious environment variable
  -- and issue a warning to prevent someone from relying on this
  warn("lua-elementtree: LUA_ELEMENTTREE_LEAK_INTERNALS is set so module internals are available")

  -- stating the obvious but these are not part of the public interface
  module['foo'] = 'bar'
end

return module
