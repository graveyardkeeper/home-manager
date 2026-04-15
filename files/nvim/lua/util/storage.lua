local Path = require 'plenary.path'

local M = {}

---@class util.storage.Item
---@field json table
---@field path any
local Item = {}
Item.__index = Item

local data_dir = Path:new(vim.fn.stdpath 'data')

---@param namespace string
---@param key string
---@return table
function Item.new(namespace, key)
  local path = data_dir:joinpath(namespace, key .. '.json')

  local json_string
  if path:exists() then json_string = path:read() end
  if not json_string or json_string == '' then json_string = '{}' end

  return setmetatable({
    path = path,
    json = vim.json.decode(json_string),
  }, Item)
end

function Item:sync()
  local path = self.path
  if not path:exists() then
    local parent = path:parent()
    if not parent:exists() then parent:mkdir { parents = true } end
  end
  path:write(vim.json.encode(self.json), 'w')
end

---@type table<string, table<string, util.storage.Item>>
local cache = {}

---@param namespace string
---@param key string
function M.get(namespace, key)
  if not cache[namespace] then cache[namespace] = {} end
  if not cache[namespace][key] then cache[namespace][key] = Item.new(namespace, key) end
  return cache[namespace][key]
end

return M
