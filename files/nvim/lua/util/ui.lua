local M = {}

function M.show_temporary_popup(text)
  local max_width = math.max(20, vim.o.columns - 4)

  local function wrap_line(line)
    if vim.fn.strdisplaywidth(line) <= max_width then return { line } end

    local wrapped = {}
    local current = ''
    for i = 0, vim.fn.strchars(line) - 1 do
      local char = vim.fn.strcharpart(line, i, 1)
      if current ~= '' and vim.fn.strdisplaywidth(current .. char) > max_width then
        table.insert(wrapped, current)
        current = char
      else
        current = current .. char
      end
    end
    table.insert(wrapped, current)
    return wrapped
  end

  -- 计算窗口大小
  local lines = {}
  for _, line in ipairs(vim.split(text, '\n')) do
    vim.list_extend(lines, wrap_line(line))
  end

  local max_line_length = 0
  for _, line in ipairs(lines) do
    max_line_length = math.max(max_line_length, vim.fn.strdisplaywidth(line))
  end
  local width = math.min(max_line_length, max_width)
  local height = math.min(#lines, math.max(1, vim.o.lines - 4))

  -- 创建浮动窗口配置
  local win_opts = {
    relative = 'cursor',
    row = 1, -- 在光标下方显示
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = false, -- 重要：窗口不可聚焦
    noautocmd = true, -- 不触发自动命令
  }

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, win_opts)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })

  -- 自动关闭逻辑
  local close_events = { 'CursorMoved', 'CursorMovedI', 'InsertEnter', 'BufLeave', 'ModeChanged' }

  local autoclose = vim.api.nvim_create_augroup('TempPopupAutoclose', { clear = true })
  vim.api.nvim_create_autocmd(close_events, {
    group = autoclose,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      vim.api.nvim_del_augroup_by_id(autoclose)
    end,
    once = true,
  })
end

return M
