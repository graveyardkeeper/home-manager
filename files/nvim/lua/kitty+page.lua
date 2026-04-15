local M = {}

local INPUT_LINE_NUMBER, CURSOR_LINE, CURSOR_COLUMN = 0, 0, 0

function M.set_color()
  local color = {
    Substitute = { bg = '#f7768e', fg = '#15161e' },
    Comment = { fg = '#565f89', italic = true },
    Search = { bg = '#3d59a1', fg = '#c0caf5' },
    IncSearch = { bg = '#ff9e64', fg = '#15161e' },
    MsgArea = { fg = '#a9b1d6' },
  }
  for k, v in pairs(color) do
    vim.api.nvim_set_hl(0, k, v)
  end
end

function M.load_plugin(name)
  local plugin_path = (vim.fn.stdpath 'data') .. '/lazy/' .. name
  local runtime_paths = vim.api.nvim_list_runtime_paths()
  for _, path in ipairs(runtime_paths) do
    if path == plugin_path then return true end
  end
  if not vim.fn.isdirectory(plugin_path) then return false end
  vim.opt.runtimepath:append(plugin_path)
  -- vim.cmd.packadd name
  return true
end

function M.setup_flash()
  if not M.load_plugin 'flash.nvim' then return false end
  -- vim.cmd.packadd 'flash.nvim'
  if package.loaded['flash'] then return true end
  local flash = require 'flash'
  flash.setup {
    modes = {
      char = {
        highlight = { backdrop = false },
        multi_line = false,
      },
    },
  }
  vim.api.nvim_set_hl(0, 'Substitute', { bg = '#ff757f', fg = '#1b1d2b' })
  vim.keymap.set({ 'n', 'x' }, 's', function() flash.jump() end)
  return true
end

function M.setup_mini_ai()
  if not M.load_plugin 'mini.ai' then return false end
  require('mini.ai').setup { search_method = 'cover' }
  return true
end

function M.set_keymap(buf)
  require 'config.keymaps'
  local map = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, { buffer = buf }) end
  map('x', 'q', 'y<Cmd>qa!<CR>')
  map('n', 'q', '<Cmd>qa!<CR>')
  map('n', '<C-q>', '<Cmd>qa!<CR>')
  map('n', 's', function()
    vim.keymap.del('n', 's', { buffer = buf })
    if not M.setup_flash() then return end
    require('flash').jump()
  end)
  map('n', 'v', function()
    vim.keymap.del('n', 'v', { buffer = buf })
    M.setup_mini_ai()
    vim.cmd 'normal! v'
  end)
end

function M.set_options()
  vim.opt.encoding = 'utf-8'
  -- Prevent auto-centering on click
  vim.opt.scrolloff = 0
  vim.opt.compatible = false
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.termguicolors = true
  vim.opt.showmode = false
  vim.opt.ruler = false
  vim.opt.signcolumn = 'no'
  vim.opt.showtabline = 0
  vim.opt.laststatus = 0
  vim.o.cmdheight = 0
  vim.o.ignorecase = true
  vim.opt.showcmd = false
  vim.opt.scrollback = 100000
  vim.opt.clipboard:append 'unnamedplus'
end

---@param num number
---@param min number
---@param max number
---@return number
local function bounded_number(num, min, max)
  if num < min then return min end
  if num > max then return max end
  return num
end

local function remove_trailing()
  vim.opt_local.modifiable = true
  vim.cmd [[%s/\s\+$//e]]
  vim.opt_local.modifiable = false
end

function M.set_autocmd(term_buf)
  require 'config.autocmds'

  local set_cursor = function()
    local max_line_nr = vim.api.nvim_buf_line_count(term_buf)
    local input_line_nr = bounded_number(INPUT_LINE_NUMBER > 0 and INPUT_LINE_NUMBER or max_line_nr, 1, max_line_nr)
    local cursor_line_nr = bounded_number(CURSOR_LINE + input_line_nr, 0, max_line_nr)

    vim.fn.winrestview { topline = input_line_nr }
    vim.api.nvim_win_set_cursor(0, { cursor_line_nr, CURSOR_COLUMN })
  end

  local group = vim.api.nvim_create_augroup('kitty+page', { clear = true })
  vim.api.nvim_create_autocmd('ModeChanged', {
    group = group,
    buffer = term_buf,
    callback = function()
      local mode = vim.fn.mode()
      if mode == 't' then
        vim.cmd.stopinsert()
        vim.schedule(set_cursor)
      end
    end,
  })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    pattern = '*',
    callback = function()
      -- Use vim.defer_fn to make sure the terminal has time to process the content and the buffer is ready.

      vim.defer_fn(function()
        set_cursor()
        vim.defer_fn(function() -- 不然会蓝屏
          remove_trailing()
          set_cursor()
        end, 10)
      end, 10)
    end,
  })
end

function M.set_term_buf()
  local term_buf = vim.api.nvim_create_buf(true, false)
  local term_io = vim.api.nvim_open_term(term_buf, {})
  local group = vim.api.nvim_create_augroup('kitty+page_set_term_buf', { clear = true })

  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    once = true,
    pattern = '*',
    callback = function(ev)
      local current_win = vim.fn.win_getid()
      -- Instead of sending lines individually, concatenate them.
      local main_lines = vim.api.nvim_buf_get_lines(ev.buf, 0, -2, false)
      local content = table.concat(main_lines, '\r\n')
      vim.api.nvim_chan_send(term_io, content .. '\r\n')

      -- Process the last line separately (without trailing \r\n)
      local last_line = vim.api.nvim_buf_get_lines(ev.buf, -2, -1, false)[1]
      if last_line then vim.api.nvim_chan_send(term_io, last_line) end
      vim.api.nvim_win_set_buf(current_win, term_buf)
      vim.api.nvim_buf_delete(ev.buf, { force = true })
    end,
  })

  return term_buf
end

---@param input_line_number string
---@param cursor_line string
---@param cursor_column string
function M.entry(input_line_number, cursor_line, cursor_column)
  INPUT_LINE_NUMBER = tonumber(input_line_number) or 0
  CURSOR_LINE = tonumber(cursor_line) or 0
  CURSOR_COLUMN = tonumber(cursor_column) or 0

  local term_buf = M.set_term_buf()

  M.set_color()
  M.set_keymap(term_buf)
  M.set_options()
  M.set_autocmd(term_buf)
end

return M
