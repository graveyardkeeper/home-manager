return {
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufReadPost',
    config = function()
      require('gitsigns').setup {
        -- 启用当前行 blame
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = 'eol', -- 在行尾显示
          delay = 300,
          ignore_whitespace = false,
        },
        -- 自定义显示格式: 作者, 日期 - commit信息
        current_line_blame_formatter = '<author> • <author_time:%R> • <summary>',
        -- 快捷键
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          vim.keymap.set('n', '<leader>gb', gs.toggle_current_line_blame, { buffer = bufnr, desc = 'Toggle Git Blame' })
        end,
      }
    end,
  },
  {
    'folke/trouble.nvim',
    cmd = { 'Trouble' },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics (Trouble)' },
      -- { '<leader>ss', '<cmd>Trouble symbols toggle<cr>', desc = 'Symbols (Trouble)' },
    },
    config = function()
      require('trouble').setup {
        modes = {
          symbols = {
            auto_open = false,
            focus = true,
            win = { size = 50 },
            filter = function(items)
              local ft = items[1] and items[1].buf and vim.bo[items[1].buf].filetype
              if vim.tbl_contains({ 'help', 'markdown' }, ft) then return items end
              return vim.tbl_filter(function(item)
                if ft == 'help' or ft == 'markdown' then return true end
                if vim.tbl_contains({ 'go', 'lua' }, ft) then
                  return vim.tbl_contains({ 'Method', 'Function', 'Interface' }, item.kind)
                end
                -- stylua: ignore
                return vim.tbl_contains({'Class', 'Constructor', 'Enum', 'Field', 'Function', 'Interface', 'Method', 'Module', 'Namespace', 'Package', 'Property', 'Struct', 'Trait',}, item.kind)
              end, items)
            end,
          },
        },
      }
    end,
  },
  {
    'MagicDuck/grug-far.nvim',
    cmd = 'GrugFar',
    keys = {
      {
        '<leader>sr',
        function()
          local grug = require 'grug-far'
          local ext = vim.bo.buftype == '' and vim.fn.expand '%:e'
          grug.open {
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= '' and '*.' .. ext or nil,
              paths = vim.fn.expand '%',
            },
          }
        end,
        mode = { 'n' },
        desc = 'Search and Replace',
      },
    },
    config = function()
      require('grug-far').setup {
        minSearchChars = 1,
        normalModeSearch = true,
        resultsHighlight = false,
        inputsHighlight = false,
        keymaps = {
          help = { n = '?' },
          historyOpen = { n = '<c-o>' },
        },
        resultLocation = {
          showNumberLabel = false,
        },
      }
    end,
  },
  {
    'chrisgrieser/nvim-rip-substitute',
    cmd = 'RipSubstitute',
    keys = {
      { '<leader>sr', function() require('rip-substitute').sub() end, mode = { 'x' }, desc = ' rip substitute' },
    },
    config = function() require('rip-substitute').setup {} end,
  },
  {
    'uga-rosa/translate.nvim',
    cmd = { 'Translate' },
    config = function()
      require('translate').setup {
        default = { command = 'translate_home_server', parse_after = 'remove_newline' },
        command = {
          translate_home_server = {
            cmd = function(lines)
              local text = table.concat(lines, '\n')
              return 'translate', { text }
            end,
          },
        },
        parse_after = {
          remove_newline = {
            cmd = function(text) return vim.split(table.concat(text, ''), '\n') end,
          },
        },
        -- replace_symbols = {
        --   translate_home_server = {
        --     ['='] = '{@E@}',
        --     ['#'] = '{@S@}',
        --     ['/'] = '{@C@}',
        --     ['\\n'] = '{@N@}',
        --   },
        -- },
      }
    end,
  },
  {
    'lambdalisue/suda.vim',
    cmd = 'SudaWrite',
    config = false,
  },
  {
    'nvim-mini/mini.diff',
    event = 'VeryLazy',
    keys = {
      {
        '<leader>go',
        function() require('mini.diff').toggle_overlay(0) end,
        desc = 'Toggle mini.diff overlay',
      },
    },
    opts = {
      view = {
        style = 'sign',
        signs = {
          add = '▎',
          change = '▎',
          delete = '',
        },
      },
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gh', '<cmd>DiffviewFileHistory<cr>', { desc = 'Repo history' } },
      { '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Repo diff' } },
      { '<leader>cr', '<cmd>DiffviewOpen origin/HEAD...HEAD<cr>', { desc = 'Code review' } },
    },
    config = function()
      require('diffview').setup {
        hooks = {
          -- diff_buf_read = function(bufnr) vim.opt_local.foldenable = false end, -- disable folding
        },
      }
    end,
  },
  {
    'folke/todo-comments.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'BufReadPost',
    keys = {},
    config = function() require('todo-comments').setup {} end,
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'fredrikaverpil/neotest-golang',
    },
    keys = {
      { '<leader>tr', function() require('neotest').run.run() end, desc = 'Run Nearest (Neotest)' },
      {
        '<leader>to',
        function() require('neotest').output.open { enter = true, auto_close = true } end,
        desc = 'Show Output (Neotest)',
      },
      { '<leader>tO', function() require('neotest').output_panel.toggle() end, desc = 'Toggle Output Panel (Neotest)' },
    },
    config = function()
      local neotest_ns = vim.api.nvim_create_namespace 'neotest'
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            -- Replace newline and tab characters with space for more compact diagnostics
            local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
            return message
          end,
        },
      }, neotest_ns)

      ---@diagnostic disable-next-line: missing-fields
      require('neotest').setup {
        adapters = {
          require 'neotest-golang',
        },
      }
    end,
  },
  {
    'nanotee/sqls.nvim',
    ft = { 'sql', 'mysql' },
    config = function()
      vim.lsp.config('sqls', {
        settings = {
          sqls = {
            connections = {
              -- {
              --   driver = 'sqlite3',
              --   dataSourceName = 'file:/Users/bytedance/.local/share/newsboat/cache.db',
              -- },
            },
          },
        },
      })
      vim.lsp.enable 'sqls'
    end,
  },
}
