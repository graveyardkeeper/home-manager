---@param s string
---@param sep string|nil
---@return string[]
function string.split(s, sep)
  if sep == nil then
    sep = '%s'
  end
  local t = {}
  for str in s:gmatch('([^' .. sep .. ']+)') do
    table.insert(t, str)
  end
  return t
end

---@param s string
---@return string[]
function string.lines(s)
  return vim.split(s, '\n')
end

---@param s string
---@param prefix string
---@return boolean
function string.startswith(s, prefix)
  return s:sub(1, #prefix) == prefix
end

---@param s string
---@param suffix string
---@return boolean
function string.endswith(s, suffix)
  return #suffix == 0 or s:sub(-#suffix) == suffix
end

---@param s string
---@param prefix string
---@return string
function string.trim_left(s, prefix)
  if #prefix == 0 then
    return s
  end
  return s:startswith(prefix) and s:sub(#prefix + 1) or s
end

---@param s string
---@param suffix string
---@return string
function string.trim_right(s, suffix)
  if #suffix == 0 then
    return s
  end
  return s:endswith(suffix) and s:sub(1, -#suffix - 1) or s
end

function dbg(v)
  print(vim.inspect(v))
end
