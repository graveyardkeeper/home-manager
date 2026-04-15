---@diagnostic disable: missing-fields

return {
  {
    'nvim-mini/mini.icons',
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
    config = function()
      require('mini.icons').setup {
        file = {
          ['.keep'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
          ['devcontainer.json'] = { glyph = '', hl = 'MiniIconsAzure' },
        },
        filetype = {
          dotenv = { glyph = '', hl = 'MiniIconsYellow' },
        },
      }
    end,
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    -- enabled = false,
    dependencies = { 'MunifTanjim/nui.nvim' },
    keys = {
      {
        '<PageDown>',
        function()
          if not require('noice.lsp').scroll(6) then return '<c-d>' end
        end,
        silent = true,
        expr = true,
        desc = 'Scroll Forward',
        mode = { 'n' },
      },
      {
        '<PageUp>',
        function()
          if not require('noice.lsp').scroll(-6) then return '<c-u>' end
        end,
        silent = true,
        expr = true,
        desc = 'Scroll Backward',
        mode = { 'n' },
      },
    },
    config = function() require('noice').setup {} end,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    config = function()
      local lualine = require 'lualine'

      local rec_msg = '' -- TODO: wait PR merged: https://github.com/nvim-lualine/lualine.nvim/pull/1227
      vim.api.nvim_create_autocmd({ 'RecordingEnter', 'RecordingLeave' }, {
        group = vim.api.nvim_create_augroup('LualineRecordingSection', { clear = true }),
        callback = function(e)
          if e.event == 'RecordingLeave' then
            rec_msg = ''
          else
            rec_msg = 'Recording @' .. vim.fn.reg_recording()
          end
          lualine.refresh()
        end,
      })

      lualine.setup {
        sections = {
          lualine_c = {
            { 'filename', path = 1 },
            {
              function() return rec_msg end,
              color = { fg = '#ff9e64' },
            },
          },
        },
      }
    end,
  },
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    -- event = 'BufEnter', -- 避免闪屏
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle Pin' },
      { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete Non-Pinned Buffers' },
      { '<C-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
      { '<C-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
      { '<C-S-j>', '<cmd>BufferLineMovePrev<cr>', desc = 'Move buffer prev' },
      { '<C-S-l>', '<cmd>BufferLineMoveNext<cr>', desc = 'Move buffer next' },
    },
    config = function()
      require('bufferline').setup {
        options = {
          close_command = function(n) Snacks.bufdelete(n) end,
        },
      }
    end,
  },
  {
    'folke/tokyonight.nvim',
    -- lazy = true,
    -- event = 'VeryLazy',
    priority = 1000,
    config = function()
      require('tokyonight').setup {
        style = 'night',
        on_colors = function(colors)
          colors.border = '#565f89' -- make windows gap noticeable
        end,
      }
      require('tokyonight').load()
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion' },
    config = function() require('render-markdown').setup {} end,
  },
}
