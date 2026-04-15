local au = vim.api.nvim_create_autocmd
local function ag(name) return vim.api.nvim_create_augroup('my_' .. name, { clear = true }) end

vim.g.is_edit_dir = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv()[1]) == 1
vim.g.is_edit_file = vim.fn.argc() == 1 and vim.fn.filereadable(vim.fn.argv()[1]) == 1
vim.g.is_bare_enter = vim.fn.argc() == 0
vim.g.is_read_stdin = false
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local set_main_window = ag 'set_main_window'
au({ 'UIEnter', 'TabNew' }, {
  group = set_main_window,
  callback = function() vim.w.is_main = true end,
})

au('StdinReadPre', {
  group = ag 'vim_enter_set_var',
  once = true,
  callback = function()
    vim.g.is_read_stdin = true
    vim.g.is_bare_enter = false
  end,
})

-- close some filetypes with <q>
au('FileType', {
  group = ag 'close_with_q',
  pattern = {
    'sqls_output',
    'PlenaryTestPopup',
    'checkhealth',
    'dbout',
    'gitsigns-blame',
    'grug-far',
    'help',
    'lspinfo',
    'neotest-output',
    'neotest-output-panel',
    'neotest-summary',
    '*.kulala_ui',
    'notify',
    'qf',
    'spectre_panel',
    'startuptime',
    'tsplayground',
    'snacks_picker_input',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.b[event.buf].completion = false
    vim.schedule(function()
      vim.keymap.set('n', 'q', function()
        vim.cmd 'close'
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = 'Quit buffer',
      })
    end)
  end,
})

local write_osc52_on_yank
if vim.env.SSH_TTY then write_osc52_on_yank = require('vim.ui.clipboard.osc52').copy '+' end

au('TextYankPost', {
  group = ag 'highlight-yank',
  callback = function()
    vim.hl.on_yank()
    if write_osc52_on_yank then write_osc52_on_yank(vim.v.event.regcontents) end
  end,
})

-- au('User', {
--   group = ag 'disable-animate-for-blink',
--   pattern = 'BlinkCmpMenuOpen',
--   callback = function() vim.g.snacks_animate = false end,
-- })
--
-- au('User', {
--   group = ag 'restore-animate-for-blink',
--   pattern = 'BlinkCmpMenuClose',
--   callback = function() vim.g.snacks_animate = true end,
-- })

local function reset_terminal_title() vim.opt.titlestring = 'nvim: ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':~') end

reset_terminal_title()

au({ 'DirChanged', 'VimResume', 'TermClose' }, {
  group = ag 'reset_terminal_title',
  callback = reset_terminal_title,
})

au('FileType', {
  group = ag 'disable_spell',
  pattern = 'markdown',
  callback = function() vim.opt_local.spell = false end,
})

local jupytext = ag 'jupytext'
au('BufReadCmd', {
  pattern = { '*.ipynb' },
  group = jupytext,
  callback = function(ev) require('util.jupytext').read_from_ipynb(ev.buf) end,
})
au({ 'BufWriteCmd', 'FileWriteCmd' }, {
  pattern = { '*.ipynb' },
  group = jupytext,
  callback = function(ev) require('util.jupytext').write_to_ipynb(ev.buf) end,
})

-- go to last loc when opening a buffer
au('BufReadPost', {
  group = ag 'last_loc',
  callback = function(event)
    local exclude = { 'gitcommit' }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then return end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then pcall(vim.api.nvim_win_set_cursor, 0, mark) end
  end,
})

-- au('UIEnter', {
--   group = ag 'set_main_window',
--   callback = function()
--     vim.api.nvim_tabpage_list_wins(0)
--     vim.api.nvim_win_get_buf(1000)
--     vim.api.nvim_get_current_buf()
--     _G.ttt = 'sdfsdf'
--   end,
-- })

-- au('LspAttach', {
--   callback = function(args)
--     -- local buffer = args.buf ---@type number
--     local client = vim.lsp.get_client_by_id(args.data.client_id)
--     if not client then
--       return
--     end
--     if client.name == 'gopls' then
--       if not client.server_capabilities.semanticTokensProvider then
--         local semantic = client.config.capabilities.textDocument.semanticTokens
--         client.server_capabilities.semanticTokensProvider = {
--           full = true,
--           legend = {
--             tokenTypes = semantic.tokenTypes,
--             tokenModifiers = semantic.tokenModifiers,
--           },
--           range = true,
--         }
--       end
--     end
--   end,
-- })

local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
au({ 'User' }, {
  pattern = 'CodeCompanionRequest*',
  group = ag 'CodeCompanionFidgetHooks',
  callback = function(request)
    local model_name = request.data.adapter.formatted_name
    local msg

    if request.match == 'CodeCompanionRequestStarted' then
      msg = string.format('[CodeCompanion](%s) starting...', model_name)
    elseif request.match == 'CodeCompanionRequestStreaming' then
      msg = string.format('[CodeCompanion](%s) streaming...', model_name)
    else
      msg = string.format('[CodeCompanion](%s) finished', model_name)
    end

    vim.notify(msg, 'info', {
      id = 'code_companion_status',
      title = 'Code Companion Status',
      opts = function(notif)
        notif.icon = request.match == 'CodeCompanionRequestFinished' and ' '
          or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

au({ 'BufWritePre' }, {
  desc = 'Format on save',
  pattern = '*',
  group = ag 'format_on_save',
  callback = function(args) require('util.formatter').format_buf(args.buf, { code_action = true }) end,
})
