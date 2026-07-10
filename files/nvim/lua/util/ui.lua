local M = {}

local function set_popup_highlights()
  local groups = {
    TempPopupBorder = { fg = '#7aa2f7' },
    TempPopupHeadword = { fg = '#ff9e64', bold = true },
    TempPopupIpa = { fg = '#7dcfff', italic = true },
    TempPopupPos = { fg = '#1a1b26', bg = '#bb9af7', bold = true },
    TempPopupMeaning = { fg = '#c0caf5' },
    TempPopupExample = { fg = '#a9b1d6', italic = true },
    TempPopupTranslation = { fg = '#9ece6a' },
    TempPopupKeyword = { fg = '#1a1b26', bg = '#e0af68', bold = true },
    TempPopupBullet = { fg = '#f7768e', bold = true },
  }
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

local highlight_map = {
  headword = 'TempPopupHeadword',
  ipa = 'TempPopupIpa',
  pos = 'TempPopupPos',
  meaning = 'TempPopupMeaning',
  example = 'TempPopupExample',
  translation = 'TempPopupTranslation',
  keyword = 'TempPopupKeyword',
  bullet = 'TempPopupBullet',
}

local function byteidx(line, char_index)
  if char_index == 0 then return 0 end
  local index = vim.fn.byteidx(line, char_index)
  if index < 0 then return #line end
  return index
end

local function wrap_plain_line(line, max_width)
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

local function wrap_rich_line(line, source_line, source_highlights, max_width)
  if vim.fn.strdisplaywidth(line) <= max_width then
    return { { text = line, start_byte = 0, end_byte = #line, source_line = source_line } }
  end

  local chunks = {}
  local chunk_text = ''
  local chunk_start_byte = 0
  local char_count = vim.fn.strchars(line)

  for i = 0, char_count - 1 do
    local char = vim.fn.strcharpart(line, i, 1)
    local char_start = byteidx(line, i)
    local char_end = byteidx(line, i + 1)
    if chunk_text ~= '' and vim.fn.strdisplaywidth(chunk_text .. char) > max_width then
      table.insert(chunks, { text = chunk_text, start_byte = chunk_start_byte, end_byte = char_start, source_line = source_line })
      chunk_text = char
      chunk_start_byte = char_start
    else
      if chunk_text == '' then chunk_start_byte = char_start end
      chunk_text = chunk_text .. char
    end
    if i == char_count - 1 then
      table.insert(chunks, { text = chunk_text, start_byte = chunk_start_byte, end_byte = char_end, source_line = source_line })
    end
  end

  if #chunks == 0 then return { { text = line, start_byte = 0, end_byte = #line, source_line = source_line } } end
  return chunks
end

local function normalize_highlights(highlights)
  local by_line = {}
  for _, item in ipairs(highlights or {}) do
    local line = item.line
    local start_col = item.start_col
    local end_col = item.end_col
    local group = highlight_map[item.group] or item.group
    if type(line) == 'number' and type(start_col) == 'number' and type(end_col) == 'number' and type(group) == 'string' then
      by_line[line] = by_line[line] or {}
      table.insert(by_line[line], {
        start_col = start_col,
        end_col = end_col,
        group = group,
        priority = item.priority or 100,
      })
    end
  end
  return by_line
end

local function build_popup(text, opts)
  local max_width = math.max(20, vim.o.columns - 4)
  local source_highlights = normalize_highlights(opts.highlights)
  local lines = {}
  local highlights = {}

  for source_line, line in ipairs(vim.split(text, '\n')) do
    local line_index = source_line - 1
    local rich_chunks = wrap_rich_line(line, line_index, source_highlights[line_index] or {}, max_width)
    for _, chunk in ipairs(rich_chunks) do
      local target_line = #lines
      table.insert(lines, chunk.text)
      for _, highlight in ipairs(source_highlights[line_index] or {}) do
        local start_col = math.max(highlight.start_col, chunk.start_byte)
        local end_col = math.min(highlight.end_col, chunk.end_byte)
        if start_col < end_col then
          table.insert(highlights, {
            line = target_line,
            start_col = start_col - chunk.start_byte,
            end_col = end_col - chunk.start_byte,
            group = highlight.group,
            priority = highlight.priority,
          })
        end
      end
    end
  end

  if #lines == 0 then lines = { '' } end
  return lines, highlights, max_width
end

function M.show_temporary_popup(text, opts)
  opts = opts or {}
  set_popup_highlights()

  local lines, highlights, max_width
  if opts.highlights then
    lines, highlights, max_width = build_popup(text, opts)
  else
    max_width = math.max(20, vim.o.columns - 4)
    lines = {}
    for _, line in ipairs(vim.split(text, '\n')) do
      vim.list_extend(lines, wrap_plain_line(line, max_width))
    end
    highlights = {}
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
    width = math.max(width, 1),
    height = height,
    style = 'minimal',
    border = 'rounded',
    title = opts.title,
    title_pos = opts.title and 'center' or nil,
    focusable = false, -- 重要：窗口不可聚焦
    noautocmd = true, -- 不触发自动命令
  }

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, win_opts)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('winhl', 'FloatBorder:TempPopupBorder', { win = win })

  local namespace = vim.api.nvim_create_namespace 'TempPopupRichText'
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, namespace, highlight.line, highlight.start_col, {
      end_col = highlight.end_col,
      hl_group = highlight.group,
      priority = highlight.priority,
    })
  end

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

function M.show_loading_popup(title)
  set_popup_highlights()

  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local index = 1
  local text = title or 'Loading'
  local line = text .. ' ' .. frames[index]
  local width = math.max(vim.fn.strdisplaywidth(line), 1)

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = 1,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    noautocmd = true,
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('winhl', 'FloatBorder:TempPopupBorder', { win = win })

  local namespace = vim.api.nvim_create_namespace 'TempPopupLoading'
  local function render()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    index = index % #frames + 1
    line = text .. ' ' .. frames[index]
    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
    local text_width = #text
    vim.api.nvim_buf_set_extmark(buf, namespace, 0, 0, {
      end_col = text_width,
      hl_group = 'TempPopupTranslation',
      priority = 100,
    })
    vim.api.nvim_buf_set_extmark(buf, namespace, 0, text_width + 1, {
      end_col = #line,
      hl_group = 'TempPopupBullet',
      priority = 120,
    })
  end

  render()

  local timer = vim.uv.new_timer()
  timer:start(80, 80, function() vim.schedule(render) end)

  local closed = false
  local function close()
    if closed then return end
    closed = true
    if timer then
      timer:stop()
      timer:close()
    end
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  return close
end

function M.show_translate_popup(payload)
  if type(payload) ~= 'table' or type(payload.lines) ~= 'table' then return end
  M.show_temporary_popup(table.concat(payload.lines, '\n'), {
    title = ' 󰊿 Translate ',
    highlights = payload.highlights or {},
  })
end

return M
