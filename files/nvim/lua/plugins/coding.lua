return {
  {
    'saghen/blink.cmp',
    version = '*',
    event = { 'InsertEnter', 'CmdlineEnter' },
    config = function()
      local snippets_dir = { vim.fn.stdpath 'config' .. '/snippets' }
      local cwd = vim.uv.cwd() or vim.env.PWD
      local vscode_dir = cwd ~= vim.env.HOME
        and vim.fs.find('.vscode', { upward = true, stop = vim.env.HOME, limit = 1, path = cwd })
      if vscode_dir and #vscode_dir > 0 then
        vim.notify(string.format("Snippets in '%s' will be loaded", vscode_dir[1]))
        table.insert(snippets_dir, 1, vscode_dir[1])
      end

      require('blink.cmp').setup {
        sources = {
          default = { 'lsp', 'path', 'snippets', 'buffer' },
          providers = {
            lsp = {
              transform_items = function(ctx, items)
                local item_kind = require('blink.cmp.types').CompletionItemKind
                local ft = vim.bo[ctx.bufnr].filetype

                local out = vim.tbl_filter(function(item)
                  if item.kind == item_kind.Text then return false end
                  if ft == 'go' and item.kind == item_kind.Snippet then return false end
                  return true
                end, items)

                for _, item in ipairs(out) do
                  if item.kind == item_kind.Snippet then
                    item.score_offset = item.score_offset - 3 -- demote
                  elseif ft == 'go' and (item.kind == item_kind.Module or item.kind == item_kind.Keyword) then
                    item.score_offset = item.score_offset - 3
                  end
                end
                return out
              end,
            },
            snippets = { opts = { search_paths = snippets_dir } },
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100, -- show at a higher priority than lsp
            },
          },
          per_filetype = { lua = { inherit_defaults = true, 'lazydev' } },
        },
        keymap = {
          preset = 'none',
          ['<C-j>'] = { 'select_next', 'fallback' },
          ['<C-k>'] = { 'select_prev', 'fallback' },
          ['<CR>'] = { 'select_and_accept', 'fallback' },
          ['<Tab>'] = { 'fallback' },
          ['<S-Tab>'] = { 'fallback' },
          ['<Up>'] = { 'select_prev', 'fallback' },
          ['<Down>'] = { 'select_next', 'fallback' },
          ['<PageUp>'] = { 'scroll_documentation_up', 'fallback' },
          ['<PageDown>'] = { 'scroll_documentation_down', 'fallback' },
          ['<C-l>'] = { 'snippet_forward', 'fallback' },
          ['<C-h>'] = { 'snippet_backward', 'fallback' },
        },
        -- keymap = {
        --   preset = 'none',
        --   ['<Tab>'] = {
        --     'select_and_accept',
        --     function(cmp)
        --       local col = vim.api.nvim_win_get_cursor(0)[2]
        --       if vim.api.nvim_get_current_line():sub(1, col):match '^%s*$' == nil then return cmp.show() end
        --     end,
        --     'fallback',
        --   },
        --   ['<Up>'] = { 'select_prev', 'fallback' },
        --   ['<Down>'] = { 'select_next', 'fallback' },
        --   ['<PageUp>'] = { 'scroll_documentation_up', 'fallback' },
        --   ['<PageDown>'] = { 'scroll_documentation_down', 'fallback' },
        --   ['<C-l>'] = { 'snippet_forward', 'fallback' },
        --   ['<C-h>'] = { 'snippet_backward', 'fallback' },
        -- },
        completion = {
          keyword = { range = 'prefix' },
          menu = { draw = { treesitter = { 'lsp' } } },
          documentation = { auto_show = true, auto_show_delay_ms = 200 },
        },
        cmdline = {
          keymap = {
            preset = 'none',
            ['<Tab>'] = { 'select_and_accept', 'fallback' },
            ['<Up>'] = { 'select_prev', 'fallback' },
            ['<Down>'] = { 'select_next', 'fallback' },
          },
          completion = {
            menu = { auto_show = function(ctx) return vim.fn.getcmdtype() == ':' end },
          },
        },
      }
    end,
  },
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash' },
      { 'S', mode = { 'n', 'o', 'x' }, function() require('flash').treesitter() end, desc = 'Flash Treesitter' },
    },
    config = function()
      require('flash').setup {
        modes = {
          char = {
            highlight = { backdrop = false },
            multi_line = false,
          },
        },
      }
    end,
  },
  {
    'nvim-mini/mini.ai',
    event = 'VeryLazy',
    config = function()
      local ai = require 'mini.ai'
      ai.setup {
        n_lines = 500,
        search_method = 'cover',
        custom_textobjects = {
          o = ai.gen_spec.treesitter { -- code block
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          },
          f = ai.gen_spec.treesitter { a = '@function.outer', i = '@function.inner' }, -- function
          c = ai.gen_spec.treesitter { a = '@class.outer', i = '@class.inner' }, -- class
          u = ai.gen_spec.function_call(), -- u for "Usage"
        },
      }
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    event = 'VeryLazy',
    enabled = false,
    config = function()
      require('nvim-ts-autotag').setup {
        opts = {
          enable_close_on_slash = true,
        },
      }
    end,
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      local npairs = require 'nvim-autopairs'
      local ts_conds = require 'nvim-autopairs.ts-conds'
      local cond = require 'nvim-autopairs.conds'

      npairs.setup {
        fast_wrap = {
          map = '<C-w>',
          cursor_pos_before = false,
        },
      }
      -- ~/.local/share/nvim/lazy/nvim-autopairs/lua/nvim-autopairs/rules/basic.lua
      npairs
        .get_rules("''")[1]
        :with_pair(ts_conds.is_not_ts_node { 'indented_string_expression', 'string_fragment' })
        :with_pair(cond.not_after_regex '[%w$]')
    end,
  },
  {
    'nvim-mini/mini.pairs',
    event = 'InsertEnter',
    enabled = false,
    config = function()
      require('mini.pairs').setup {
        mappings = {
          ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].', register = { bs = false } },
          ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].', register = { bs = false } },
          ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].', register = { bs = false } },

          -- [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].', register = { bs = false } },
          -- [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].', register = { bs = false } },
          -- ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].', register = { bs = false } },

          ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false, bs = false } },
          ["'"] = {
            action = 'closeopen',
            pair = "''",
            neigh_pattern = '[^%a\\].',
            register = { cr = false, bs = false },
          },
          ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false, bs = false } },
        },
      }
    end,
  },
  {
    'nvim-mini/mini.surround',
    keys = {
      { '()', 'gza(', mode = 'x', remap = true },
      { '[]', 'gza[', mode = 'x', remap = true },
      { '{}', 'gza{', mode = 'x', remap = true },
      { '"', 'gza"', mode = 'x', remap = true },
      { "'", "gza'", mode = 'x', remap = true },
      { 'gz', '', desc = '+surround' },
    },
    config = function()
      require('mini.surround').setup {
        custom_surroundings = {
          -- default insert spaces, custom to remove spaces
          ['('] = { output = { left = '(', right = ')' } },
          ['['] = { output = { left = '[', right = ']' } },
          ['{'] = { output = { left = '{', right = '}' } },
        },
        mappings = {
          add = 'gza', -- Add surrounding in Normal and Visual modes
          delete = 'gzd', -- Delete surrounding
          find = 'gzf', -- Find surrounding (to the right)
          find_left = 'gzF', -- Find surrounding (to the left)
          highlight = 'gzh', -- Highlight surrounding
          replace = 'gzr', -- Replace surrounding
          update_n_lines = 'gzn', -- Update `n_lines`
        },
      }
    end,
  },
  -- {
  --   'nvim-mini/mini.splitjoin',
  --   keys = 'gs',
  --   config = function() require('mini.splitjoin').setup { mappings = { toggle = 'gs' } } end,
  -- },
  {
    'Wansmer/treesj',
    keys = {
      { 'gs', function() require('treesj').toggle() end },
    },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function() require('treesj').setup { use_default_keymaps = false, max_join_length = 500 } end,
  },
  {
    'danymat/neogen',
    cmd = 'Neogen',
    keys = {
      { '<leader>cg', function() require('neogen').generate() end, desc = 'Generate Annotations (Neogen)' },
    },
    config = function() require('neogen').setup { snippet_engine = 'nvim' } end,
  },
  {
    'nvim-mini/mini.align',
    version = false,
    keys = {
      { 'ga', mode = 'x' },
    },
    config = function() require('mini.align').setup {} end,
  },
}
