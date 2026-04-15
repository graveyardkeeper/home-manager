local get_color = (function()
  local colors = { 'Constant', 'Statement', 'Keyword', 'String', 'Directory' }
  local i = 0
  local last_key = ''
  return function(key)
    if key ~= last_key then
      last_key = key
      i = i % #colors + 1
    end
    return colors[i]
  end
end)()

local function git_file_finder(opts, ctx)
  local git_root = vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true }):wait().stdout
  if not git_root then
    vim.notify('not in git repo', vim.log.levels.ERROR)
    return {}
  else
    git_root = git_root:gsub('\n$', '')
  end
  opts = vim.tbl_extend('force', opts, {
    cmd = 'git-file',
    ---@param item snacks.picker.finder.Item
    transform = function(item)
      local sha, mod, file = item.text:match '^(%w+)%s+([A-Z?]+)%s+(.+)$'
      if not mod then return nil end
      if mod == 'D' or mod == 'AD' then return false end -- hide delete
      if file:sub(-1) == '/' then return false end -- hide directory
      file = git_root .. '/' .. file
      item.text = file
      item.file = file
      item.mod = mod
      item.sha = sha
    end,
  })
  return require('snacks.picker.source.proc').proc(opts, ctx)
end

local commit_info_cache = require('util.cache').new()
local function relative_date_desc(sha)
  return commit_info_cache:ensure(sha, function()
    local proc = vim.system({ 'git', 'show', sha, '--quiet', '--pretty=format:%at' }, { text = true }):wait()
    return proc and proc.code == 0 and proc.stdout and Util.relative_date_desc(tonumber(proc.stdout) or 0)
  end)
end

local function git_file_formatter(item, picker)
  local base = require('snacks.picker.format').file(item, picker)

  local color = get_color(item.sha)
  local a = Snacks.picker.util.align
  local desc = item.sha and item.sha ~= 'uncommit' and relative_date_desc(item.sha) or '-'
  local ret = {
    { a(desc, 10), color },
    { a(item.mod, 3), color },
  }
  return vim.list_extend(ret, base)
end

local function git_file_previewer(ctx)
  local item = ctx.item
  local cmd
  local git_diff_cmd = function(cmds)
    return vim.list_extend(
      -- { 'git', '--no-pager', '-c', 'diff.external=difft --display=inline --syntax-highlight=off' },
      { 'git', '-c', 'core.pager=delta --pager=never', 'diff', '-w', '--ignore-blank-lines', '-U10' },
      cmds
    )
  end
  if item.mod == '??' then
    return require('snacks.picker.preview').file(ctx)
  elseif item.sha == 'uncommit' then
    cmd = git_diff_cmd { 'HEAD', '--', item.file }
  else
    cmd = git_diff_cmd { item.sha .. '^', item.sha, '--', item.file }
  end
  return require('snacks.picker.preview').cmd(cmd, ctx)
end

local function confirm(picker, _, action)
  local items = picker:selected { fallback = true }
  require('snacks.picker.actions').jump(picker, _, action)
  if #items == 0 then return end

  local item = items[1]
  if item.mod == '??' then return end

  local cmd = {}
  if item.sha == 'uncommit' then
    cmd = { 'git', '--no-pager', 'diff', '-U0', 'HEAD', '--', item.file }
  else
    cmd = { 'git', '--no-pager', 'diff', '-U0', item.sha .. '^', item.sha, '--', item.file }
  end

  local jump_rows = {}
  for _, line in ipairs(vim.fn.systemlist(cmd)) do
    local num = line:match '^@@ %-(%d+)'
    if num and num ~= '' then table.insert(jump_rows, tonumber(num)) end
  end
  if not jump_rows or #jump_rows == 0 then
    vim.notify('No change', vim.log.levels.WARN)
    return
  end

  vim.defer_fn(function()
    local win = picker.main
    local buf = vim.api.nvim_win_get_buf(win) -- TODO: check path

    local jump_pos = function(forward)
      local line = vim.api.nvim_win_get_cursor(win)[1]
      if forward then
        for i = 1, #jump_rows do
          if line < jump_rows[i] then
            vim.api.nvim_win_set_cursor(win, { jump_rows[i], 0 })
            return
          end
        end
        vim.notify('No more changes', vim.log.levels.WARN)
      else
        for i = #jump_rows, 1, -1 do
          if line > jump_rows[i] then
            vim.api.nvim_win_set_cursor(win, { jump_rows[i], 0 })
            return
          end
        end
        vim.notify('No more changes', vim.log.levels.WARN)
      end
    end

    vim.api.nvim_create_autocmd('BufHidden', {
      group = vim.api.nvim_create_augroup('delete_git_picker_keymap', { clear = true }),
      buffer = buf,
      once = true,
      callback = function() end,
    })
  end, 100)
end

return function()
  Snacks.picker { finder = git_file_finder, format = git_file_formatter, preview = git_file_previewer, confirm = confirm }
end
