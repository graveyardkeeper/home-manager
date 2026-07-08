---@diagnostic disable: missing-fields

-- https://neovim.io/doc/user/lua.html#map()
-- echo keyname: first press ctrl+v in insert mode, then press your key
local n, i, x, c, t = 'n', 'i', 'x', 'c', 't'
local map = function(arg)
  local mode = arg.mode or n
  local lhs = arg[1]
  local rhs = arg[2]
  arg.mode = nil
  arg[1] = nil
  arg[2] = nil
  vim.keymap.set(mode, lhs, rhs, arg)
end

local unmap = function(arg)
  if type(arg) == 'string' then vim.keymap.del(n, arg) end
  local mode = arg.mode or n
  for _, lhs in ipairs(arg) do
    vim.keymap.del(mode, lhs)
  end
end
map { '<D-Left>', '<Home>', remap = true }
map { '<D-Right>', '<End>', remap = true }
map { '<D-BS>', '<C-u>', mode = i, remap = true }
map { '<Esc>', '<cmd>nohlsearch<CR>', desc = 'Clear Highlights On Search' }
map { '<Down>', 'gj', mode = { n, x }, desc = 'Down' } -- adapt wrap line
map { '<Up>', 'gk', mode = { n, x }, desc = 'Up' } -- adapt wrap line

-- local map = vim.keymap.set
local function termcodes(str)
  -- Adjust boolean arguments as needed
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

map { '<PageDown>', '<C-d>' }
map { '<PageUp>', '<C-u>' }

-- copy to clipboard ( use osc52 if ssh )
map { '<leader>y', '"+y', mode = { x, n }, desc = 'Copy Using OSC52' }
map { '<leader>Y', '^"+y$', desc = 'Copy Line Using OSC52' }

map { '<C-p>', '"0p', mode = { x, n } }
map { '<C-p>', '<c-r>0', mode = i }
map { 'Y', '^y$', desc = 'Copy Line Without Newline' }
-- map('<C-l>', '<cmd>bnext<cr>', 'Switch to Right Buffer')
-- map('<C-j>', '<cmd>bprevious<cr>', 'Switch to Left Buffer')
map { 'g:', 'g;', mode = { n, x }, desc = 'Jump older change list' }
map { '<M-BS>', '<C-w>', mode = { i, c }, desc = 'Delete Word' }
map { '<M-Left>', '<C-Left>', mode = i, desc = 'Jump Backward Word' }
map { '<M-Right>', '<C-Right>', mode = i, desc = 'Jump Forward Word' }

map {
  '<C-S-O>',
  function()
    local buf = vim.api.nvim_get_current_buf()
    vim.cmd.normal(termcodes '<C-o>')
    vim.api.nvim_buf_delete(buf, {})
  end,
  desc = 'Close Buffer And Jump Back',
}

map {
  '<D-S-s>',
  function()
    vim.notify 'Save as which file:'
    require('yazi').yazi {
      open_file_function = function(chosen_file)
        if type(chosen_file) == 'string' and chosen_file ~= '' then vim.cmd('w! ' .. chosen_file) end
      end,
    }
  end,
  mode = { n, i },
  desc = 'Save As',
}
map { '<D-s>', '<cmd>w!<cr>', mode = { n, i }, desc = 'Save File' }

map {
  '<C-q>',
  function()
    -- if vim.w.is_main then
    local bufs = vim.fn.getbufinfo { buflisted = 1 }
    if #bufs > 1 then
      Snacks.bufdelete()
      return
    end
    -- end
    vim.cmd 'q'
  end,
  mode = { n, i },
  desc = 'Close Buffer',
}
map {
  '<leader>bf',
  function()
    local cwd = vim.uv.cwd() or vim.env.PWD
    Snacks.bufdelete {
      filter = function(buf)
        local buf_name = vim.api.nvim_buf_get_name(buf)
        return buf_name ~= '' and not vim.startswith(buf_name, cwd)
      end,
    }
  end,
  desc = 'Delete buffers not in cwd',
}
map { '<leader>bo', function() Snacks.bufdelete.other() end, desc = 'Delete Other Buffers' }
map { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files' }
map { '<S-C-q>', '<cmd>qa<cr>', desc = 'Quit All' }
map { '<D-k>s', '<cmd>noa w<cr><esc>', mode = { n, i }, desc = 'Save Without Format' }
map {
  '<D-k>f',
  function() require('util.formatter').format_buf(0, { async = true }) end,
  mode = { n, i },
  desc = 'Format',
}
map { '<D-k>m', function() require('util.vim').set_filetype() end, mode = { n, i }, desc = 'Set File Type' }
map { '<D-z>', 'u', desc = 'Undo' }
map { '<D-z>', '<C-O>u', mode = i, desc = 'Undo' }
map { '<S-D-z>', '<C-R>', desc = 'Redo' }
map { '<S-D-z>', '<C-O><C-R>', mode = i, desc = 'Redo' }
map { '<D-a>', 'ggVG', desc = 'Select All' }
map { '<D-x>', '<C-O>dd', mode = i, desc = 'Delete Current Line' }
map { '<D-x>', 'dd', desc = 'Delete Current Line' }
map { '<D-up>', '<C-Home>', mode = { n, i, x }, desc = 'Jump to First Line' }
map { '<D-down>', '<C-End>', mode = { n, i, x }, desc = 'Jump to Last Line' }
map { '<Home>', '^', mode = { n, x }, desc = 'Jump to Line First Char' }
map { '<Home>', '<C-o>I', mode = i, desc = 'Jump to Line First Char' }
-- windows
map { '<C-w>j', '<cmd>wincmd h<cr>', desc = 'Focus Left Window' }
map { '<C-w>i', '<cmd>wincmd k<cr>', desc = 'Focus Above Window' }
map { '<C-w>k', '<cmd>wincmd j<cr>', desc = 'Focus Below Window' }
local function cycle_window()
  vim.cmd 'wincmd w'
  if vim.tbl_contains({ 'snacks_notif' }, vim.bo.filetype) then cycle_window() end
end
map { '<C-k>', cycle_window, mode = { n, t }, desc = 'Cycle Windows' }
map {
  '<C-w>n',
  function() vim.api.nvim_open_win(0, false, { split = 'right', win = 0 }) end,
  desc = 'New Window',
}
map {
  '<C-w>o',
  function()
    vim.cmd 'wincmd t'
    local this_window = vim.api.nvim_win_get_config(0)
    if this_window.split == 'left' or this_window.split == 'right' then
      vim.cmd 'wincmd K'
    else
      vim.cmd 'wincmd H'
    end
  end,
  desc = 'Rotato Window',
}
-- buffers
map { '<leader>bn', function() require('util.scratch').select() end, desc = 'Scratch Buffer' }
-- tabs
map { '<C-tab>n', '<cmd>tab split<cr>', desc = 'New Tab' }
map { '<C-tab><C-tab>', '<cmd>tabnext<cr>', desc = 'Next Tab' }
map { '<C-tab>q', '<cmd>tabclose<cr>', desc = 'Close Tab' }

-- pickers
-- map { '<D-p>', function() Snacks.picker.files() end, desc = 'Find Files' }
map { '<D-p>', function() Snacks.picker.smart { filter = { cwd = true } } end, desc = 'Find Files' }
map {
  '<leader>lg',
  function() Snacks.lazygit.open { cwd = vim.fn.expand '%:h', count = vim.uv.hrtime() } end,
  desc = 'Lazygit',
}
map { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Current File Git History' }
map { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Workspace diagnostics' }
map { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines' }
map {
  '<leader>fb',
  function() Snacks.picker.buffers { actions = { delete = Snacks.picker.actions.bufdelete } } end,
  desc = 'Buffers',
}
map {
  '<leader>ss',
  function()
    Snacks.picker.lsp_symbols {
      layout = { preset = 'vscode', preview = 'main' },
      filter = {
        lua = { 'Method', 'Function' },
      },
    }
  end,
}
map {
  '<leader>td',
  function() Snacks.picker.todo_comments { keywords = { 'TODO', 'FIX', 'FIXME' } } end,
  desc = 'Todo/Fix/Fixme',
}
map { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files' }
map { '<leader>n', function() Snacks.picker.notifications() end, desc = 'Notification History' }
map { '<leader>gg', function() Util.pick_git_files() end, desc = 'My Git Files' }
map { '<leader>ex', function() Snacks.picker.explorer() end, desc = 'Explorer' }
map { 'ma', function() require('util.marker').add() end, desc = 'Add Marker' }
map { 'mm', function() require('util.marker').pick() end, desc = 'List Markers' }
-- map { 'mm', function() Snacks.picker.marks() end, desc = 'List Marks' }
map { '<D-S-F>', function() Snacks.picker.grep() end, desc = 'Grep' }
map { '<D-S-F>', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = x }
map { '<C-S-O>', function() Snacks.picker.resume() end, desc = 'Resumes Last Picker' }
-- lsp
map { 'gd', function() Snacks.picker.lsp_definitions { jump = { reuse_win = false } } end, desc = '[G]oto [D]efinition' }
map { 'gr', function() Snacks.picker.lsp_references() end, desc = '[G]oto [R]eferences' }
unmap { 'grr', 'gri', 'gra', 'grn', 'grt' }
unmap { '<tab>', mode = i } -- remove smart tab: https://github.com/neovim/neovim/commit/123f8d229eef05869ee4c98dfd4934c22a03b1f6
map { 'gI', function() Snacks.picker.lsp_implementations() end, desc = '[G]oto [I]mplementation' }
map {
  '<leader>jf',
  function() require('util.treesitter').jump_function_start() end,
  desc = '跳到当前函数定义行 (Tree-sitter)',
}
map {
  '<leader>jt',
  function() require('util.run_test').jump_to_go_test() end,
  desc = '跳到当前 Go 函数单测',
}
map { '<F2>', vim.lsp.buf.rename, desc = 'Rename Symbol' }
map { '<D-.>', vim.lsp.buf.code_action, mode = { n, i, x }, desc = 'Code Action' }
map { '<leader>cc', vim.lsp.codelens.run, desc = 'Run Codelens' }
map {
  '<leader>co',
  function() vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true } end,
  desc = 'Organize Imports',
}
map {
  '<leader><cr>',
  function() require('util.run_file').run_file() end,
  desc = 'Run File',
}

-- terminal
map {
  '<C-/>',
  function() Snacks.terminal() end,
  mode = { n, i },
  desc = 'Terminal (Root Dir)',
}

map {
  '<C-S-/>',
  function()
    local file_dir = vim.fn.expand '%:h'
    if file_dir and file_dir ~= '' then Snacks.terminal(nil, { cwd = file_dir }) end
  end,
  mode = { n, i },
  desc = 'Terminal (File Dir)',
}

-- Add undo break-points
map { '<space>', '<space><c-g>u', mode = i }
map { ',', ',<c-g>u', mode = i }
map { '.', '.<c-g>u', mode = i }
map { ';', ';<c-g>u', mode = i }

-- better indenting
map { '<', '<gv', mode = x }
map { '>', '>gv', mode = x }

-- marks
-- auto increase mark
-- local mark_index = 0
-- map('n', 'mA', function()
--   if mark_index == 0 then
--     vim.cmd 'delmarks A-Z0-9'
--     -- vim.cmd("delmarks!")
--   end
--   local mark = string.char(65 + mark_index % 26)
--   vim.cmd.normal('m' .. mark)
--   mark_index = mark_index + 1
-- end)

map {
  'yp',
  function()
    local path = vim.fn.expand '%:~:.' .. ':' .. vim.fn.line '.'
    vim.fn.setreg('+', path)
    vim.notify('Copied: ' .. path)
  end,
  desc = 'Copy CurrentFile:LineNumber',
}

-- comment like vs code
map { '<D-/>', 'gcc', remap = true }
map { '<D-/>', '<C-o>gcc', mode = i, remap = true }
map { '<D-/>', 'gc', mode = x, remap = true }
map { '<C-Space>', function() end, mode = i } -- disable this keymap as it's for toggle system input method

map {
  '<D-k><D-k>',
  function()
    local current_word = vim.fn.expand '<cword>'
    if current_word:match '^%d+$' and (#current_word == 10 or #current_word == 13) then
      local timestamp = tonumber(current_word) or 0
      if #current_word == 13 then timestamp = timestamp / 1000 end
      local time_format = require('util.formatter').format_timestamp(timestamp)
      require('util.ui').show_temporary_popup(time_format)
    elseif vim.startswith(vim.fn.expand '<cfile>', 'http') then
      require('util.image').show_hover_image()
    elseif require('util.treesitter').cursor_in_capture 'comment' then
      vim.cmd 'Translate zh -comment'
    else
      vim.lsp.buf.hover()
    end
  end,
  desc = 'Smart Hover',
}
map { 'v', function() require('util.treesitter').start_select() end, mode = n, desc = 'Visual mode' }
map { 'v', function() require('util.treesitter').select_parent_node() end, mode = x, desc = 'Select parent node' }
map {
  '<bs>',
  function() require('util.treesitter').restore_last_selection() end,
  mode = x,
  desc = 'Restore last selection',
}

map { '<D-k><D-k>', vim.lsp.buf.signature_help, mode = i, desc = 'Signature Help' }
map { '<leader>tt', '<cmd>Translate zh<cr>', mode = x, desc = 'Translate' }

-- diagnostic
local diagnostic_goto = function(next, severity)
  local count = next and 1 or -1
  severity = severity and vim.diagnostic.severity[severity] or nil
  return function() vim.diagnostic.jump { count = count, severity = severity } end
end
map { '<leader>q', vim.diagnostic.setloclist, desc = 'Open diagnostic [Q]uickfix list' }
map { '<leader>cd', vim.diagnostic.open_float, desc = 'Line Diagnostics' }
map { '<leader>lz', '<cmd>Lazy<cr>', desc = 'Lazy' }

map {
  '<leader>r',
  function() require('util.repl').smart_new() end,
  desc = 'New Repl',
}

map {
  '<D-S-p>',
  function() require('util.command_picker').pick() end,
  desc = 'My Command Picker',
  mode = { n, x, i },
}

vim.defer_fn(function() -- 避免%被重新映射
  map {
    '%',
    function() return require('util.treesitter').jump_parent_node_edge() or '%' end,
    mode = { n, x },
    remap = true,
  }
end, 1000)
