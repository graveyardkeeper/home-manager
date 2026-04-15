local M = {}

setmetatable(M, {
  __index = function(t, k)
    ---@diagnostic disable-next-line: no-unknown
    t[k] = require('util.' .. k)
    return rawget(t, k)
  end,
})

_G.Util = M

local function start_profile()
  -- example for lazy.nvim
  -- change this to the correct path for your plugin manager
  local snacks = vim.fn.stdpath 'data' .. '/lazy/snacks.nvim'
  vim.opt.rtp:append(snacks)
  require('snacks.profiler').startup {
    startup = {
      -- event = 'VimEnter', -- stop profiler on this event. Defaults to `VimEnter`
      -- event = "UIEnter",
      event = 'VeryLazy',
    },
  }
end

---@param url string
local function kitty_open_url(url)
  local kitty_cmd_string = vim.json.encode {
    cmd = 'action',
    version = { 0, 26, 0 },
    payload = { action = 'open_url ' .. url },
    no_response = true,
  }
  local tty_string = '\x1bP@kitty-cmd' .. kitty_cmd_string .. '\x1b\\'
  vim.fn.chansend(vim.v.stderr, tty_string)
end

local function file_opener()
  local orig_open = vim.ui.open
  if vim.env.SSH_TTY == nil then return orig_open end
  return function(path, opts)
    if opts ~= nil and #opts.cmd > 0 then orig_open(path, opts) end
    kitty_open_url(path)
  end
end

function M.setup()
  if vim.env.PROF then start_profile() end

  vim.ui.open = file_opener()

  require 'util.stdlib_extend'
end

---@param key any
---@return number
function M.hash_to_int(key)
  if type(key) == 'table' then key = table.concat(key, ':') end
  local h = 5381
  for c in tostring(key):gmatch '.' do
    h = (bit.lshift(h, 5) + h) + string.byte(c)
  end
  return h
end

---@param unix number
---@return string
function M.relative_date_desc(unix)
  if not unix then return '-' end
  local secs = os.time() - unix
  if secs < 60 then
    return string.format('%d秒前', secs)
  elseif secs / 60 < 60 then
    return string.format('%d分钟前', secs / 60)
  elseif secs / 3600 < 24 then
    return string.format('%d小时前', secs / 3600)
  elseif secs / 3600 / 24 < 7 then
    return string.format('%d天前', secs / 3600 / 24)
  elseif secs / 3600 / 24 < 30 then
    return string.format('%d周前', secs / 3600 / 24 / 7)
  elseif secs / 3600 / 24 < 365 then
    return string.format('%d月前', secs / 3600 / 24 / 30)
  else
    return string.format('%d年前', secs / 3600 / 24 / 365)
  end
end

return M
