local M = {}

local go_function_node_types = {
  function_declaration = true,
  method_declaration = true,
}

---@class GoFunctionContext
---@field node TSNode
---@field name string
---@field receiver_type string|nil

---@param bufnr integer
---@return TSNode|nil
local function get_cursor_go_function_node(bufnr)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = bufnr })
  if not ok or not node then return nil end

  while node do
    if go_function_node_types[node:type()] then return node end
    node = node:parent()
  end
end

---@param bufnr integer
---@param node TSNode
---@return string|nil
local function get_receiver_type(bufnr, node)
  local receiver_node = node:field('receiver')[1]
  if not receiver_node then return nil end

  local parameter_declaration = receiver_node:named_child(0)
  if not parameter_declaration then return nil end

  local type_node = parameter_declaration:field('type')[1]
  if not type_node then return nil end

  local receiver_type = vim.treesitter.get_node_text(type_node, bufnr)
  receiver_type = receiver_type:gsub('^%*', '')
  receiver_type = receiver_type:match('([%w_]+)$')
  return receiver_type
end

---@param bufnr integer
---@return GoFunctionContext|nil
local function get_cursor_function_context(bufnr)
  local node = get_cursor_go_function_node(bufnr)
  if not node then return nil end

  local name_node = node:field('name')[1]
  local name = name_node and vim.treesitter.get_node_text(name_node, bufnr) or nil
  if not name then return nil end

  return {
    node = node,
    name = name,
    receiver_type = get_receiver_type(bufnr, node),
  }
end

---@param cmd string[]
---@param cwd string
local function open(cmd, cwd)
  Snacks.terminal.open(cmd, {
    cwd = cwd,
    interactive = false,
    win = { position = 'bottom', height = 0.3 },
  })
end

---@param bufnr integer
local function run_go_test(bufnr)
  local ctx = get_cursor_function_context(bufnr)
  local func_name = ctx and ctx.name or nil
  if not func_name or not vim.startswith(func_name, 'Test') then
    vim.notify('Cursor not in test function', vim.log.levels.WARN)
    return
  end

  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fs.dirname(current_file)
  local escaped = vim.pesc(func_name)
  open({ 'go', 'test', '-v', '-run', '^' .. escaped .. '$' }, cwd)
end

---@param bufnr integer
function M.run_cursor_test(bufnr)
  if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
  local ft = vim.bo[bufnr].filetype
  if ft == 'go' then
    run_go_test(bufnr)
  else
    vim.notify(ft .. 'not supported', vim.log.levels.WARN)
  end
end

---@class GoTestCandidate
---@field file string
---@field line_nr integer
---@field test_name string
---@field score integer
---@field display_path string

---@param text string
---@return string
local function normalize_name(text)
  return (text:gsub('[^%w]', '')):lower()
end

---@param ctx GoFunctionContext
---@return string[]
local function build_test_patterns(ctx)
  local func_name = vim.pesc(ctx.name)
  local patterns = {}

  if ctx.receiver_type then
    local receiver_type = vim.pesc(ctx.receiver_type)
    table.insert(patterns, '^func%s+(Test' .. receiver_type .. '_' .. func_name .. ')%s*%(')
    table.insert(patterns, '^func%s+(Test' .. receiver_type .. '.*' .. func_name .. ')%s*%(')
    table.insert(patterns, '^func%s+(Test.*' .. receiver_type .. '.*' .. func_name .. ')%s*%(')
  end

  table.insert(patterns, '^func%s+(Test' .. func_name .. ')%s*%(')
  table.insert(patterns, '^func%s+(Test.-' .. func_name .. ')%s*%(')
  return patterns
end

---@param ctx GoFunctionContext
---@param test_name string
---@return integer
local function score_test_candidate(ctx, test_name)
  local score = 0
  local normalized_test = normalize_name(test_name)
  local normalized_func = normalize_name(ctx.name)

  if test_name == 'Test' .. ctx.name then score = score + 1000 end
  if normalized_test:find(normalized_func, 1, true) then score = score + 100 end

  if ctx.receiver_type then
    local normalized_receiver = normalize_name(ctx.receiver_type)
    if normalized_test:find(normalized_receiver, 1, true) then score = score + 500 end
    if test_name == ('Test' .. ctx.receiver_type .. '_' .. ctx.name) then score = score + 1000 end
  end

  return score
end

---@param candidate GoTestCandidate
local function jump_to_candidate(candidate)
  vim.cmd "normal! m'"
  vim.cmd('edit ' .. vim.fn.fnameescape(candidate.file))
  vim.api.nvim_win_set_cursor(0, { candidate.line_nr, 0 })
  vim.cmd 'normal! ^'
end

---@param base_dir string
---@param path string
---@return string
local function relative_to(base_dir, path)
  local rel = vim.fs.relpath(base_dir, path)
  if rel and rel ~= '' then return rel end

  local base_with_sep = vim.fs.normalize(base_dir)
  local normalized_path = vim.fs.normalize(path)
  if not base_with_sep:match('/$') then base_with_sep = base_with_sep .. '/' end
  if vim.startswith(normalized_path, base_with_sep) then
    return normalized_path:sub(#base_with_sep + 1)
  end

  return path
end

---@param candidates GoTestCandidate[]
local function pick_test_candidate(candidates)
  table.sort(candidates, function(a, b)
    if a.score == b.score then
      if a.file == b.file then return a.line_nr < b.line_nr end
      return a.file < b.file
    end
    return a.score > b.score
  end)

  if #candidates == 1 then
    jump_to_candidate(candidates[1])
    return
  end

  vim.ui.select(candidates, {
    prompt = 'Select Go test',
    format_item = function(item)
      return ('%s — %s:%d'):format(item.test_name, item.display_path, item.line_nr)
    end,
  }, function(choice)
    if choice then jump_to_candidate(choice) end
  end)
end

function M.jump_to_go_test()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= 'go' then
    vim.notify('Only supported in Go files', vim.log.levels.INFO)
    return
  end

  local ctx = get_cursor_function_context(bufnr)
  if not ctx then
    vim.notify('Current cursor is not inside a function', vim.log.levels.INFO)
    return
  end

  local patterns = build_test_patterns(ctx)
  local current_file = vim.api.nvim_buf_get_name(bufnr)
  local current_dir = vim.fs.dirname(current_file)
  local test_files = vim.fn.globpath(current_dir, '*_test.go', false, true)
  local candidates = {}
  local seen = {}

  for _, file in ipairs(test_files) do
    local lines = vim.fn.readfile(file)
    for line_nr, line in ipairs(lines) do
      for _, pattern in ipairs(patterns) do
        local test_name = line:match(pattern)
        if test_name then
          local key = table.concat({ file, line_nr, test_name }, ':')
          if not seen[key] then
            seen[key] = true
            table.insert(candidates, {
              file = file,
              line_nr = line_nr,
              test_name = test_name,
              score = score_test_candidate(ctx, test_name),
              display_path = relative_to(current_dir, file),
            })
          end
          break
        end
      end
    end
  end

  if #candidates == 0 then
    vim.notify(('No test found for %s'):format(ctx.name), vim.log.levels.INFO)
    return
  end

  pick_test_candidate(candidates)
end

return M
