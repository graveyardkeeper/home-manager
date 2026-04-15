--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

local opt = vim.opt

opt.cmdheight = 0
opt.laststatus = 3 -- global statusline, keep lualine always bottom

opt.confirm = true -- `:qa` confirm to save if edited
opt.jumpoptions = 'view' -- ctrl-o reopen deleted buffer
opt.expandtab = true -- expand tab input with spaces characters
opt.smartindent = true -- Insert indents automatically
opt.tabstop = 2 -- Number of spaces tabs count for
opt.shiftwidth = 2 -- Size of an indent
opt.winborder = 'rounded'
opt.diffopt:append 'iwhiteall' -- Ignore whitespace changes in diff
opt.diffopt:append 'iblank' -- Ignore blank line in diff

-- fold
opt.foldmethod = 'expr'
opt.foldtext = ''
opt.foldlevel = 99 -- disable auto fold

opt.number = true
opt.relativenumber = true
opt.mouse = 'a' -- Enable mouse mode, can be useful for resizing splits for example!
opt.showmode = false -- Don't show the mode, since it's already in the status line
vim.schedule(function()
  -- Schedule the setting after `UiEnter` because it can increase startup-time.
  -- only set clipboard if not in ssh, to make sure the OSC 52
  opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus' -- Sync with system clipboard
  vim.g.clipboard = vim.env.SSH_TTY and 'osc52' or nil
end)
opt.breakindent = true -- Enable break indent
opt.undofile = true -- Save undo history
opt.grepprg = 'rg --vimgrep'
opt.shell = 'fish'

opt.wildmode = 'longest:full,full' -- Command-line completion mode

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = 'yes' -- Keep signcolumn on by default
opt.updatetime = 200 -- Decrease update time
opt.timeoutlen = 1000 -- Decrease mapped sequence wait time

-- Configure how new splits should be opened
opt.splitright = true
opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
opt.inccommand = 'split' -- Preview substitutions live, as you type!
opt.cursorline = true -- Show which line your cursor is on
opt.scrolloff = 10 -- Minimal number of screen lines to keep above and below the cursor.
opt.wrap = true
opt.title = true -- enable neovim change terminal title
opt.conceallevel = 0 -- don't hide my json strings
opt.spelllang = { 'en', 'cjk' }
opt.spelloptions = 'camel'

opt.sessionoptions = { 'buffers', 'curdir', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }

opt.fillchars = {
  foldopen = '',
  foldclose = '',
  fold = ' ',
  foldsep = ' ',
  diff = ' ',
  eob = ' ',
}

-- https://neovim.io/doc/user/lua.html#vim.filetype.add()
vim.filetype.add {
  extension = {
    service = 'systemd',
    d2 = 'd2',
    http = 'http',
    tmpl = 'gotmpl',
  },
  filename = {
    ['.env'] = 'dotenv',
    ['.envrc'] = 'sh',
  },
}
