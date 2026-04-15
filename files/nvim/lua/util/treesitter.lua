local M = {}

--- Check if cursor is in treesitter capture
---@param capture string | []string
---@return boolean
function M.cursor_in_capture(capture)
  local captures_at_cursor = vim.treesitter.get_captures_at_cursor()
  if vim.tbl_isempty(captures_at_cursor) then
    return false
  elseif type(capture) == 'string' and vim.tbl_contains(captures_at_cursor, capture) then
    return true
  elseif type(capture) == 'table' then
    for _, v in ipairs(capture) do
      if vim.tbl_contains(captures_at_cursor, v) then return true end
    end
  end
  return false
end

local node_list = {}

function M.start_select()
  node_list = {}
  vim.cmd 'normal! v'
end

---@param node TSNode
---@return TSNode?
local function find_expand_node(node)
  local start_row, start_col, end_row, end_col = node:range()
  local parent = node:parent()
  if parent == nil then return nil end
  local parent_start_row, parent_start_col, parent_end_row, parent_end_col = parent:range()
  if
    start_row == parent_start_row
    and start_col == parent_start_col
    and end_row == parent_end_row
    and end_col == parent_end_col
  then
    return find_expand_node(parent)
  end
  return parent
end

local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)

---@param node TSNode?
local function set_visual(node)
  if not node then return end
  local start_row, start_col, end_row, end_col = node:range()
  if end_col == 0 then
    local last_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1]
    end_row = end_row - 1
    end_col = #last_line
  else
    end_col = end_col - 1
  end
  vim.api.nvim_feedkeys(esc, 'x', false)
  vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
  vim.cmd 'normal! v'
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

function M.select_parent_node()
  local node = node_list[#node_list]
  if node then
    node = find_expand_node(node)
  else
    local ok
    ok, node = pcall(vim.treesitter.get_node)
    if not ok then return {} end
  end
  table.insert(node_list, node)
  set_visual(node)
end

function M.restore_last_selection()
  if #node_list > 1 then
    table.remove(node_list)
    set_visual(node_list[#node_list])
  end
end

function M.jump_parent_node_edge()
  local node = vim.treesitter.get_node()
  if not node then return end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = node:start()
  if cursor[1] ~= row + 1 or cursor[2] ~= col then
    vim.api.nvim_win_set_cursor(0, { row + 1, col })
  else
    row, col = node:end_()
    vim.api.nvim_win_set_cursor(0, { row + 1, col - 1 })
  end
  return true
end

local jump_function_name_config = {
  common = {
    method_declaration = 'name',
    function_declaration = 'name',
    function_definition = 'name',
  },
  go = {
    func_literal = 'parameters',
  },
  lua = {
    function_definition = 'parameters',
  },
  nu = {
    decl_def = 'unquoted_name',
  },
  rust = {
    function_item = 'name',
  },
}

--- @param node TSNode
--- @param to_end? boolean
function M.goto_node(node, to_end)
  local start_row, start_col, end_row, end_col = node:range()
  local dest_row = (to_end and end_row or start_row) + 1
  local dest_col = to_end and (end_col - 1) or start_col
  vim.cmd "normal! m'" -- set jump list so I can jump back
  vim.api.nvim_win_set_cursor(0, { dest_row, dest_col })
end

function M.jump_function_name()
  local node = vim.treesitter.get_node()
  local config =
    vim.tbl_deep_extend('force', jump_function_name_config.common, jump_function_name_config[vim.bo.filetype] or {})

  if not config then config = {} end

  while node do
    local name = config[node:type()]

    if name then
      local name_node = node:field(name)[1]
      if name_node then
        M.goto_node(name_node)
        return
      end
    end

    node = node:parent()
  end
end

local function_node_types = {
  -- common
  function_declaration = true,
  function_definition = true,
  method_declaration = true,
  method_definition = true,
  constructor_declaration = true,
  constructor_definition = true,
  -- go
  func_literal = true,
  -- rust
  function_item = true,
  -- js/ts
  ['function'] = true,
  function_expression = true,
  arrow_function = true,
}

--- Jump to current function's definition line (start row)
function M.jump_function_start()
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then
    vim.notify('Tree-sitter 未启用或无法获取语法节点', vim.log.levels.WARN)
    return
  end

  local config =
    vim.tbl_deep_extend('force', jump_function_name_config.common, jump_function_name_config[vim.bo.filetype] or {})

  ---@param fn_node TSNode
  ---@return TSNode?
  local function get_function_name_node(fn_node)
    local field = config[fn_node:type()]
    if field then
      local n = fn_node:field(field)[1]
      if n then return n end
    end

    -- fallback for common grammars
    for _, f in ipairs { 'name', 'identifier' } do
      local n = fn_node:field(f)[1]
      if n then return n end
    end
    return nil
  end

  while node do
    if function_node_types[node:type()] then
      local name_node = get_function_name_node(node)
      if name_node then
        M.goto_node(name_node)
        return
      end

      local row = node:start()
      vim.cmd "normal! m'" -- set jump list so I can jump back
      vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
      vim.cmd 'normal! ^'
      return
    end
    node = node:parent()
  end

  vim.notify('当前光标不在函数体内（未找到包裹的函数节点）', vim.log.levels.INFO)
end

return M
