---@diagnostic disable: missing-fields

---@param f fun(lualine_config: table)
local setup_lualine = function(f)
  local lualine = require 'lualine'
  local lualine_config = lualine.get_config()
  f(lualine_config)
  lualine.setup(lualine_config)
end

return {
  {
    'folke/snacks.nvim',
    lazy = false,
    priority = 1000,
    init = function()
      _G.dd = function(...) Snacks.debug.inspect(...) end
      -- vim.g.snacks_animate = vim.env.SSH_TTY == nil -- disable snack animate
      vim.g.snacks_animate = false -- disable snack animate
    end,
    config = function()
      require('snacks').setup {
        image = { enabled = true, doc = { enabled = false }, math = { enabled = true } },
        scroll = { enabled = true },
        indent = { enabled = true, animate = { enabled = false } },
        input = { enabled = true },
        notifier = { enabled = true },
        scope = { enabled = true },
        bigfile = { enabled = true },
        -- quickfile = { enabled = true },
        terminal = {
          win = {
            style = 'float',
            keys = {
              ['<C-/>'] = { 'hide', mode = { 'n', 't' } },
            },
            border = 'rounded',
          },
        },
        picker = {
          enabled = true,
          debug = {
            -- grep = true,
          },
          actions = {
            trouble_open = function(...) require('trouble.sources.snacks').actions.trouble_open(...) end,
            exclude = function(picker)
              local old = vim.api.nvim_get_current_line()
              local main_buffer = vim.api.nvim_win_get_buf(picker.main)
              local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(main_buffer), ':e')
              local cwd = vim.uv.cwd() or ''
              local is_work = cwd:find '/work/'

              local picker_name = picker.init_opts.source
              if picker_name == 'grep' then
                local rg_args = {}
                if ext ~= '' then table.insert(rg_args, '-g *.' .. ext) end
                if is_work then table.insert(rg_args, '-g !kitex_gen') end
                if #rg_args > 0 then vim.api.nvim_set_current_line(old .. ' -- ' .. table.concat(rg_args, ' ')) end
              elseif picker_name == 'lsp_references' then
                local args = { old }
                if is_work then table.insert(args, 'file:!kitex_gen') end
                table.insert(args, 'file:^' .. cwd)
                vim.api.nvim_set_current_line(table.concat(args, ' '))
              elseif picker_name == 'smart' then
                local args = { old }
                if ext ~= '' then table.insert(args, 'file:' .. ext .. '$') end
                vim.api.nvim_set_current_line(table.concat(args, ' '))
              end
            end,
          },
          previewers = {
            diff = { builtin = false },
          },
          win = {
            input = {
              keys = {
                ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
                ['<PageDown>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
                ['<PageUp>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
                ['<C-i>'] = { 'history_forward', mode = { 'i', 'n' } },
                ['<C-o>'] = { 'history_back', mode = { 'i', 'n' } },
                ['<C-u>'] = false, -- clear input
                ['<C-e>'] = { 'exclude', mode = { 'i' } },
                ['<C-d>'] = { 'delete', mode = { 'i' } },
                ['<C-t>'] = { 'trouble_open', mode = { 'i' } },
              },
            },
            list = {
              keys = {
                ['j'] = { 'list_down', mode = { 'n', 'i' } },
                ['k'] = { 'list_up', mode = { 'n', 'i' } },
                ['<C-j>'] = { 'list_down', mode = { 'n', 'i' } },
                ['<C-k>'] = { 'list_up', mode = { 'n', 'i' } },
              },
            },
          },
        }, -- better vim.ui.select
        -- scroll = { enabled = true },
        statuscolumn = { enabled = false },
        words = { enabled = true },
        dashboard = {
          preset = {
            keys = {
              { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
              { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
              { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
              {
                icon = ' ',
                key = 'r',
                desc = 'Recent Files',
                action = function() Snacks.picker.recent { filter = { paths = { [vim.uv.cwd()] = true } } } end,
              },
              { icon = ' ', key = 'l', desc = 'LeetCode', action = ':Leet' },
              { icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
            },
          },
        },
      }
      Snacks.toggle.zoom():map '<C-w><Enter>'
    end,
  },
  {
    'folke/persistence.nvim',
    event = 'BufReadPre',
    config = function()
      if vim.fn.argc() == 1 then
        local file = vim.fn.argv()[1]
        if vim.fn.filereadable(file) == 1 then
          local abs_path = vim.fn.fnamemodify(file, ':p')
          local cwd = vim.uv.cwd() or vim.env.PWD
          local file_in_cwd = string.sub(abs_path, 1, #cwd) == cwd
          if not file_in_cwd then return end
        end
      end

      require('persistence').setup {}
    end,
  },
  { 'folke/lazy.nvim', version = '*' },
  {
    'folke/which-key.nvim',
    cmd = 'WhichKey',
    config = function() require('which-key').setup {} end,
  },
  {
    'kawre/leetcode.nvim',
    dependencies = { 'nui.nvim' },
    cmd = { 'Leet' },
    keys = {
      { '<leader>lr', 'Leet run', 'Leet run' },
      { '<leader>ls', 'Leet submit', 'Leet submit' },
    },
    lazy = vim.fn.argv()[1] ~= 'leetcode',
    config = function()
      local workdir = vim.fn.expand '~/workspace/leetcode/golang'
      vim.fn.mkdir(workdir, 'p')

      require('leetcode').setup {
        image_support = false,
        arg = 'leetcode',
        lang = 'golang',
        storage = { home = workdir },
        cn = { enabled = true },
        injector = {
          ['golang'] = {
            before = {
              'package main',
            },
            -- after = { 'func main() {', '\tfmt.Println()', '}' },
          },
          ['rust'] = {
            before = {
              '#[allow(dead_code)]',
              'pub struct Solution {}',
            },
          },
        },
        hooks = {
          ['question_enter'] = {
            function(question)
              vim.keymap.set('n', '<leader>r', '<cmd>Leet run<cr>', { buffer = question.bufnr })
              vim.keymap.set('n', '<leader>s', '<cmd>Leet submit<cr>', { buffer = question.bufnr })
              -- require("util.leetcode").on_question_open(prefer_lang, target_dir)
            end,
          },
        },
      }
    end,
  },
  {
    'tpope/vim-dadbod',
    enabled = false,
    cmd = 'DB',
  },
  {
    'kristijanhusak/vim-dadbod-ui',
    cmd = { 'DBUI', 'DBUIToggle', 'DBUIAddConnection', 'DBUIFindBuffer' },
    enabled = false,
    dependencies = { 'vim-dadbod', 'kristijanhusak/vim-dadbod-completion' },
    init = function()
      local data_path = vim.fn.stdpath 'data'

      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. '/dadbod_ui'
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. '/dadbod_ui/tmp'
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true
      vim.g.db_ui_execute_on_save = false
      vim.g.db_ui_disable_mappings = true
    end,
  },
  {
    'kristijanhusak/vim-dadbod-completion',
    lazy = true,
    dependencies = 'vim-dadbod',
    enabled = false,
    config = function()
      require('blink.cmp').add_provider('dadbod', {
        name = 'Dadbod',
        module = 'vim_dadbod_completion.blink',
      })
      require('blink.cmp').add_filetype_source('sql', 'snippets')
      require('blink.cmp').add_filetype_source('sql', 'dadbod')
      require('blink.cmp').add_filetype_source('sql', 'buffer')
    end,
  },
  {
    'mikavilpas/yazi.nvim',
    cmd = 'Yazi',
    keys = {
      { '<D-r>', '<cmd>Yazi <cr>', mode = { 'n' }, desc = 'Open yazi at the current file' },
      { '<D-R>', '<cmd>Yazi cwd<cr>', mode = { 'n' }, desc = "Open the file manager in nvim's working directory" },
      {
        '<D-R>',
        function()
          local visual = require('util.vim').get_visual()
          local file = visual and visual.lines and table.concat(visual.lines, '')
          if file then require('yazi').yazi(nil, file) end
        end,
        mode = { 'x' },
        desc = 'Reveal visual selection directory',
      },
    },
    config = function()
      require('yazi').setup {
        open_for_directories = false,
        floating_window_scaling_factor = 1,
        yazi_floating_window_winblend = 0,
        open_file_function = function(chosen_file)
          if vim.fn.isdirectory(chosen_file) == 1 then
            vim.fn.chdir(chosen_file)
          else
            vim.cmd(string.format('edit %s', vim.fn.fnameescape(chosen_file)))
          end
        end,
        integrations = {
          grep_in_directory = function(directory)
            vim.defer_fn(function()
              -- HACK something seems to exit insert mode when the picker is shown.
              -- Wait a bit to hack around this.
              require('snacks.picker').grep {
                dirs = { directory },
                title = 'Grep in ' .. directory,
              }
            end, 50)
          end,
        },
      }
    end,
  },
  {
    'mistweaverco/kulala.nvim',
    ft = 'http',
    config = function()
      require('kulala').setup {
        default_view = 'body',
        default_env = 'dev',
        debug = false,
        urlencode = 'skipencoded',
      }
      setup_lualine(function(lualine) table.insert(lualine.sections.lualine_x, 1, 'kulala') end)
    end,
  },
  {
    'stevearc/overseer.nvim',
    cmd = { 'OverseerToggle', 'OverseerRun', 'OverseerInfo', 'OverseerQuickAction' },
    keys = {
      { '<leader>ow', '<cmd>OverseerToggle right<cr>', desc = 'Task list' },
      { '<leader>on', '<cmd>OverseerBuild<cr>', desc = 'New Task' },
      {
        '<leader>oo',
        function()
          local overseer = require 'overseer'
          overseer.run_task({}, function(task)
            if task then overseer.open { enter = false, direction = 'right' } end
          end)
        end,
        desc = 'Run task',
      },
      {
        '<leader>ob',
        function()
          local task = require('overseer').new_task {
            cmd = { 'just', 'build' },
            components = {
              { 'on_output_quickfix', open_on_exit = 'failure' },
              'default',
            },
          }
          task:start()
        end,
        desc = 'Run just build',
      },
      { '<leader>or', '<cmd>OverseerQuickAction restart<cr>', desc = 'Restart Last Action' },
      { '<leader>ot', '<cmd>OverseerTaskAction<cr>', desc = 'Task action' },
      { '<leader>oq', '<cmd>OverseerQuickAction open output in quickfix<cr>', desc = 'Open QuickFix' },
    },
    config = function()
      local overseer = require 'overseer'
      overseer.setup {
        task_list = {
          keymaps = {
            ['<C-j>'] = false,
            ['<C-k>'] = false,
            ['<C-l>'] = false,
            ['<C-c>'] = { 'keymap.run_action', opts = { action = 'stop' }, desc = 'Stop task' },
            r = { 'keymap.run_action', opts = { action = 'restart' }, desc = 'Restart task' },
          },
        },
      }
      setup_lualine(function(lualine) table.insert(lualine.sections.lualine_x, 1, 'overseer') end)
    end,
  },
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = 'cd app && npm install',
  },
}
