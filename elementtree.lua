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
local comment_freeze <const> = function (self)
  local private <const> = assert(comment_private[self], "Comment instance not recognized: " .. tostring(self))
  private.frozen = true

  return self
end

local comment_instance_methods <const> = {
  ['freeze'] = comment_freeze
}

local comment_internal_metatable <const> = {
  __name = 'Comment',
  __metatable = comment_metatable,
  __index = function (self, key)
    local private <const> = assert(comment_private[self], "Comment instance not recognized: " .. tostring(self))

    -- content
    if key == 'content' then
      return private.content
    -- frozen
    elseif key == 'frozen' then
      return private.frozen
    -- instance methods
    elseif comment_instance_methods[key] then
      return comment_instance_methods[key]
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

      assert(not private.frozen, "Comment instance is frozen")
      private.content = value
    -- frozen
    elseif key == 'frozen' then
      error("Comment instance cannot be frozen directly")
    -- instance methods
    elseif comment_instance_methods[key] then
      error("Comment instance methods cannot be modified")
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
    if type(content) ~= 'string' then
      error("Comment content must be a string")
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
local node_set_attribute <const> = function (self, name, value)
  local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))
  assert(not private.frozen, "Node instance is frozen")

  assert(type(name) == 'string' and #name > 0, "Node attribute name must be a non-empty string")
  assert(type(value) == 'string', "Node attribute value must be a string")
  private.attributes[name] = value

  return self
end

local node_remove_attribute <const> = function (self, name)
  local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))
  assert(not private.frozen, "Node instance is frozen")

  assert(type(name) == 'string' and #name > 0, "Node attribute name must be a non-empty string")
  private.attributes[name] = nil

  return self
end

local node_insert_child <const> = function (self, child, position)
  local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))

  assert(
    (type(child) == 'string' and #child > 0) or
    getmetatable(child) == node_metatable or
    Comment.is(child),
    "Node children must be a Node instance, Comment instance, or non-empty string"
  )

  assert(
    position == nil or math.type(position) == 'integer',
    "Node children position must be nil or an integer"
  )

  if position ~= nil then
    table.insert(private.children, position, child)
  else
    table.insert(private.children, child)
  end
    
  return self
end

local node_remove_child <const> = function (self, position_or_child)
  local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))
  assert(not private.frozen, "Node instance is frozen")

  removed_child = nil -- track if we successfully remove the requested child
  if math.type(position_or_child) == 'integer' then
    removed_child = table.remove(private.children, position)
  elseif (
    type(position_or_child) == 'string' or
    getmetatable(position_or_child) == node_metatable or
    Comment.is(position_or_child)
  ) then
    for index, child in ipairs(private.children) do
      if child == position_or_child then
        removed_child = table.remove(private.children, index)
        break
      end
    end
  else
    error("Node:remove_child() expects a position or child instance")
  end

  assert(removed_child ~= nil, "Node child not found: " .. tostring(position_or_child))
  return self
end

local node_freeze <const> = function (self)
  local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))

  -- use breadth-first search to recursively freeze this node and it's children
  local nodes <const> = {self}
  while #nodes > 0 do
    local node <const> = table.remove(nodes, 1)
    local private <const> = assert(node_private[node], "Node instance not recognized: " .. tostring(node))
    private.frozen = true

    for _, child in ipairs(node.children) do
      if getmetatable(child) == node_metatable then
        table.insert(nodes, child)
      elseif Comment.is(child) then
        child:freeze()
      end
    end
  end

  return self
end

local node_instance_methods <const> = {
  ['set_attribute'] = node_set_attribute,
  ['remove_attribute'] = node_remove_attribute,
  ['insert_child'] = node_insert_child,
  ['remove_child'] = node_remove_child,
  ['freeze'] = node_freeze
}

local node_internal_metatable <const> = {
  __name = 'Node',
  __metatable = node_metatable,
  __index = function (self, key)
    local private <const> = assert(node_private[self], "Node instance not recognized: " .. tostring(self))

    -- tag
    if key == 'tag' then
      return private.tag
    -- shallow copy of attributes
    elseif key == 'attributes' then
      local attributes <const> = {}
      for name, value in pairs(private.attributes) do
        attributes[name] = value
      end

      return attributes
    -- shallow copy of children
    elseif key == 'children' then
      local children <const> = {}
      for _, child in ipairs(private.children) do
        table.insert(children, child)
      end

      return children
    -- frozen
    elseif key == 'frozen' then
      return private.frozen
    -- instance methods
    elseif node_instance_methods[key] then
      return node_instance_methods[key]
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

      assert(not private.frozen, "Node instance is frozen")
      private.tag = value
    -- attributes
    elseif key == 'attributes' then
      error("Node attributes cannot be modified directly")
    -- children
    elseif key == 'children' then
      error("Node children cannot be modified directly")
    -- frozen
    elseif key == 'frozen' then
      error("Node cannot be frozen directly")
    -- instance methods
    elseif node_instance_methods[key] then
      error("Node instance methods cannot be modified")
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

      if #name == 0 then
        error("Node attribute key must be a non-empty string")
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
      children=children,
      frozen=false
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

--[[
Generic Load
--]]

-- https://www.w3.org/TR/2011/WD-html5-20110525/syntax.html#attributes-0
local function node_parse_attributes(value)
  -- corner case: empty value
  if string.len(value) == 0 then
    return {}
  end

  -- parse attribute value
  local value_offset = 1
  local attributes <const> = {}

  while value_offset <= string.len(value) do
    -- optional whitespace
    local start_index, end_index = string.find(value, '^%s+', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      value_offset = end_index + 1
    end

    -- required attribute name
    -- https://stackoverflow.com/a/53563849
    local start_index, end_index = string.find(value, '^[a-zA-Z-_]+', value_offset)
    if not start_index or not end_index then
      return nil, "invalid attribute data"
    end

    local name <const> = string.sub(value, start_index, end_index)
    value_offset = end_index + 1

    -- optional attribute value
    -- note: you can have spaces between the name and equal sign (XXX but we may not want to support this)
    local start_index, end_index = string.find(value, '^=%s*[\'"]', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      value_offset = end_index + 1

      local outer_quote <const> = string.sub(value, end_index, end_index)
      assert(outer_quote == '"' or outer_quote == "'")

      local value_pattern <const> = '^[^' .. outer_quote .. ']*' .. outer_quote

      start_index, end_index = string.find(value, value_pattern, value_offset)
      if not start_index or not end_index then
        return nil, "attribute value with mis-matched quotes"
      end

      assert(start_index == value_offset)
      value_offset = end_index + 1

      local value <const> = string.sub(value, start_index, end_index - 1)
      attributes[name] = value
      goto next_attribute
    else
      attributes[name] = ''
      goto next_attribute
    end

    -- unexpected characters
    do
      return nil, "unexpected character"
    end

    ::next_attribute::
  end

  return attributes
end

local function document_load_string(value, settings)
  assert(type(value) == 'string', "document_dump_string value must be a string")
  assert(type(settings) == 'table', "document_dump_string settings must be a table")
  local header_lines <const> = settings['header_lines'] or {}
  local indent <const> = settings['indent'] or ' '
  local tags <const> = settings['tags'] or {}

  assert(type(header_lines) == 'table', "header_lines setting must be a table")
  assert(type(indent) == 'string', "indent setting must be a string")
  assert(type(tags) == 'table', "tags setting must be a table")

  -- XXX: refactor all of this
  local value_offset = 1
  local stack <const> = {}
  local root_nodes <const> = {}

  while value_offset <= string.len(value) do
    -- whitespace
    local start_index, end_index = string.find(value, '^%s+', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      value_offset = end_index + 1

      goto next_token
    end

    -- text
    local start_index, end_index = string.find(value, '^[^<>]+', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      value_offset = end_index + 1

      local next_text_data <const> = assert(string.match(
        string.sub(value, start_index, end_index),
        '^%s*(.-)%s*$'
      ))

      -- corner case: we only captured whitespace
      -- XXX: we never hit this when explicitly skipping leading whitespace above
      if string.len(next_text_data) == 0 then
        goto next_token
      end

      if #stack > 0 then
        local current_node <const> = stack[#stack]
        current_node:insert_child(next_text_data)
      else
        table.insert(root_nodes, next_text_data)
      end

      goto next_token
    end

    -- comment
    local start_index, end_index = string.find(value, '^<!%-%-', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      local comment_start_index <const> = end_index + 1
      value_offset = end_index + 1

      local start_index, end_index = string.find(value, '%-%->', value_offset)
      if start_index and end_index then
        local comment_end_index <const> = start_index - 1
        value_offset = end_index + 1

        local comment_data <const> = string.sub(value, comment_start_index, comment_end_index)
        local comment_data_trimmed <const> = assert(string.match(
          comment_data,
          '^%s*(.-)%s*$'
        ))

        local comment <const> = Comment(comment_data_trimmed)
        if #stack > 0 then
          local current_node <const> = stack[#stack]
          current_node:insert_child(comment)
        else
          table.insert(root_nodes, comment)
        end
      else
        return nil, "failed to find closing comment tag at offset: " .. tostring(value_offset)
      end

      goto next_token
    end

    -- next element (document type, comment, tag)
    local start_index, end_index = string.find(value, '^<[^>]*>', value_offset)
    if start_index and end_index then
      assert(start_index == value_offset)
      value_offset = end_index + 1

      local next_tag_data <const> = string.sub(value, start_index, end_index)

      -- XXX: special tag
      local special_data <const> = string.match(next_tag_data, '^<!(.-)>$')
      if special_data then
        -- print("SPECIAL TAG:", special_data) -- DEBUG
        goto next_token
      end

      -- XXX: another special tag
      local extra_data <const> = string.match(next_tag_data, '^<%?(.-)%?>$')
      if extra_data then
        -- print("EXTRA TAG:", extra_data) -- DEBUG
        goto next_token
      end

      -- closing tag
      local closing_tag <const> = string.match(next_tag_data, '^</(.-)>$')
      if closing_tag then
        if #stack == 0 then
          return nil, "found naked closing tag at offset: " .. tostring(value_offset)
        end

        if string.len(closing_tag) == 0 then
          return nil, "found empty closing tag at offset: " .. tostring(value_offset)
        end

        local current_node <const> = stack[#stack]
        if current_node.tag ~= closing_tag then
          return nil, "found mis-matched closing tag at offset: " .. tostring(value_offset)
        end

        local current_node <const> = table.remove(stack)
        if #stack == 0 then
          table.insert(root_nodes, current_node)
        end

        goto next_token
      end

      -- opening tag
      local opening_tag <const>, opening_attributes <const> = string.match(next_tag_data, '^<(%S+)(.-)>$')
      if opening_tag then
        local attributes <const>, message = node_parse_attributes(opening_attributes)
        if message then
          return nil, "invalid tag attributes: " .. message
        end

        local node <const> = Node(opening_tag, attributes, {})

        if #stack > 0 then
          local current_node <const> = stack[#stack]
          current_node:insert_child(node)
        end

        local tag_settings = tags[node.tag] or {}
        local tag_is_leaf = tag_settings['leaf'] or false
        local tag_is_text = tag_settings['text'] or false

        -- text tags contain arbitrary text and we should look for the next
        -- matching closing tag without parsing anything in between
        if tag_is_text then
          local start_index, end_index = string.find(value, '</' .. node.tag .. '>', value_offset)
          if not start_index or not end_index then
            return nil, "missing closing tag for text element: " .. node.tag
          end

          -- extract text content
          -- XXX: note that we should detect how much leading whitespace to strip
          -- from the beginning of every line of text content and remove it so
          -- when we dump the node the output will match the original content
          local text_content <const> = string.sub(value, value_offset, start_index - 1)
          value_offset = end_index + 1

          if string.len(text_content) > 0 then
            node:insert_child(text_content)
          end

          -- text elements are always leaves so continue processing the next token
          goto next_token
        end

        if not tag_is_leaf then
          table.insert(stack, node)
        end

        goto next_token
      end

      return nil, "invalid tag at offset: " .. tostring(value_offset)
    end

    -- unexpected character in value
    -- note: we need to create a scope here to avoid leaking locals into the
    -- parent block which would prevent us from jumping to the next_token label
    do
      return nil, "unexpected character at offset: " .. tostring(value_offset)
    end

    ::next_token::
  end

  -- DEBUG DEBUG
  -- for index, node in ipairs(stack) do
  --   print("STACK[", index, "]:", node.tag)
  -- end

  -- for _, node in ipairs(root_nodes) do
  --   print("ROOT NODE:", node.tag)
  -- end

  -- XXX
  if #stack > 0 then
    return nil, "mis-matched opening and closing tags"
  end

  if #root_nodes == 0 then
    return nil, "no top-level elements found"
  end

  -- taking last node from root nodes if there is more than one
  local root_node <const> = root_nodes[#root_nodes]
  return Document{root=root_node}
end

--[[
Generic Dump
--]]

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
  local tags <const> = settings['tags'] or {}

  assert(type(header_lines) == 'table', "header_lines setting must be a table")
  assert(type(indent) == 'string', "indent setting must be a string")
  assert(type(tags) == 'table', "tags setting must be a table")

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

    local tag_settings <const> = tags[node.tag] or {}
    local tag_is_leaf <const> = tag_settings['leaf'] or false

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

      if tag_is_leaf then
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
  tags={
    ['area']={leaf=true},
    ['base']={leaf=true},
    ['br']={leaf=true},
    ['col']={leaf=true},
    ['embed']={leaf=true},
    ['hr']={leaf=true},
    ['img']={leaf=true},
    ['input']={leaf=true},
    ['link']={leaf=true},
    ['meta']={leaf=true},
    ['source']={leaf=true},
    ['track']={leaf=true},
    ['wbr']={leaf=true},

    -- raw text elements
    ['script']={text=true},
    ['style']={text=true},

    -- escapable raw text elements
    -- TODO: handle the escapable part of these?
    ['textarea']={text=true},
    ['title']={text=true},
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
  tags={}
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
