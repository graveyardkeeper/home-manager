local in_work_dir = (function()
  local start_pos = string.find(vim.uv.cwd() or '', '/work/')
  return vim.g.work and start_pos ~= nil
end)()

local specs = {
  {
    'olimorris/codecompanion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter' },
    cmd = { 'CodeCompanion', 'CodeCompanionActions', 'CodeCompanionToggle', 'CodeCompanionAdd', 'CodeCompanionChat' },
    keys = {
      { '<leader>a', '<cmd>CodeCompanionChat Add<cr><esc>', mode = 'x' },
      { '<leader>a', '<cmd>CodeCompanionChat Toggle<cr>', mode = 'n' },
    },
    init = function() vim.cmd [[cab cc CodeCompanion]] end,
    config = function()
      require('codecompanion').setup {
        prompt_library = { markdown = { dirs = { '~/.config/nvim/prompts' } } },
        opts = { language = 'Chinese' },
        display = {
          action_palette = {
            provider = 'snacks',
            opts = { show_preset_prompts = false },
          },
        },
        interactions = {
          chat = {
            adapter = 'glm',
            tools = {
              opts = {
                default_tools = {
                  'run_command',
                  'insert_edit_into_file',
                  'create_file',
                  'read_file',
                  'ask_questions',
                },
              },
              ['run_command'] = {
                opts = {
                  require_approval_before = false,
                  require_cmd_approval = false,
                },
              },
              ['create_file'] = { opts = { require_approval_before = false } },
              ['read_file'] = { opts = { require_approval_before = false } },
            },
          },
          inline = { adapter = 'glm' },
          cmd = { adapter = 'glm' },
        },
        adapters = {
          acp = { opts = { show_presets = false } },
          http = {
            opts = { show_presets = false, show_model_choices = false },
            moonshot = function()
              return require('codecompanion.adapters').extend('openai_compatible', {
                name = 'moonshot',
                formatted_name = 'Moon Shot',
                schema = { model = { default = 'kimi-k2-turbo-preview' } },
                env = {
                  api_key = 'MOONSHOT_API_KEY',
                  url = 'https://api.moonshot.cn',
                },
              })
            end,
            glm = function()
              return require('codecompanion.adapters').extend('openai_compatible', {
                name = 'glm',
                formatted_name = 'GLM',
                schema = { model = { default = 'GLM-4.7' } },
                env = {
                  api_key = 'GLM_API_KEY',
                  url = 'https://open.bigmodel.cn/api/coding/paas/v4',
                  chat_url = '/chat/completions',
                },
              })
            end,
            deepseek = function()
              return require('codecompanion.adapters').extend('deepseek', {
                schema = { model = { default = 'deepseek-chat' } },
              })
            end,
          },
        },
      }

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('hide_codecompanion', { clear = true }),
        pattern = { 'codecompanion' },
        callback = function(event)
          vim.schedule(function()
            vim.keymap.set('n', 'q', function() vim.cmd 'CodeCompanionChat Toggle' end, {
              buffer = event.buf,
              silent = true,
              desc = 'Hide CodeCompanion',
            })
          end)
        end,
      })
    end,
  },
  {
    'ravitemer/mcphub.nvim',
    enabled = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = 'MCPHub',
    config = function() require('mcphub').setup() end,
  },
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    cond = not in_work_dir,
    enabled = false,
    config = function()
      require('copilot').setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = '<C-Tab>',
            next = '<C-l>',
            prev = '<C-h>',
          },
        },
      }
    end,
  },
  {
    'milanglacier/minuet-ai.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    enabled = false,
    config = function()
      require('minuet').setup {
        virtualtext = {
          auto_trigger_ft = vim.split(
            'sh,go,rust,python,lua,nix,java,c,cpp,javascript,typescript,json,yaml,toml,sql,html,css,markdown',
            ','
          ),
          auto_trigger_ignore_ft = { '*' },
          keymap = {
            accept = '<C-Tab>',
            next = '<C-l>',
            prev = '<C-h>',
          },
        },
        provider = 'openai_compatible',
        n_completions = 1,
        provider_options = {
          -- openai_compatible = {
          --   api_key = 'OPENROUTER_API_KEY',
          --   end_point = 'https://openrouter.ai/api/v1/chat/completions',
          --   model = 'qwen/qwen-2.5-coder-32b-instruct',
          --   name = 'Openrouter',
          --   optional = {
          --     max_tokens = 56,
          --     top_p = 0.9,
          --     provider = {
          --       -- Prioritize throughput for faster completion
          --       sort = 'throughput',
          --     },
          --   },
          -- },
        },
      }
    end,
  },
  {
    'Exafunction/windsurf.nvim',
    cmd = 'Codeium',
    event = 'InsertEnter',
    -- cond = false,
    cond = not in_work_dir,
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local windsurf = require 'codeium'
      local windsurf_config = require 'codeium.config'
      local allow_ft = vim.split(
        'sh,go,rust,python,lua,nix,java,c,cpp,javascript,typescript,json,yaml,toml,sql,html,css,markdown',
        ','
      )
      local ft_table = {}
      for _, ft in ipairs(allow_ft) do
        ft_table[ft] = true
      end

      Snacks.toggle({
        name = 'AI',
        get = function() return windsurf_config.options.virtual_text.manual ~= true end,
        set = function(state)
          if state then
            windsurf_config.options.virtual_text.manual = false
          else
            windsurf_config.options.virtual_text.manual = true
          end
        end,
      }):map '<leader>uA'

      windsurf.setup {
        enable_cmp_source = false,
        virtual_text = {
          enabled = true,
          filetypes = ft_table,
          default_filetype_enabled = false,
          key_bindings = {
            accept = '<C-Tab>',
            next = '<C-l>',
            prev = '<C-h>',
          },
        },
      }
      vim.defer_fn(function() vim.cmd.colorscheme 'tokyonight' end, 100) -- 不然virtualtext是白色的
    end,
  },
  {
    'supermaven-inc/supermaven-nvim',
    event = 'InsertEnter',
    cmd = {
      'SupermavenUseFree',
      'SupermavenUsePro',
    },
    cond = not in_work_dir,
    enabled = false,
    config = function()
      require('supermaven-nvim').setup {
        keymaps = {
          accept_suggestion = '<C-Tab>', -- handled by nvim-cmp / blink.cmp
        },
        ignore_filetypes = { 'bigfile', 'snacks_input', 'snacks_notif' },
      }
    end,
  },
}

if os.getenv 'WORK_ENV' then
  table.insert(specs, {
    'https://code.byted.org/chenjiaqi.cposture/codeverse.vim.git',
    cmd = 'Marscode',
    event = 'InsertEnter',
    cond = in_work_dir,
    init = function()
      vim.g.marscode_no_map_tab = true
      vim.g.marscode_disable_bindings = true
    end,
    config = function()
      vim.cmd 'inoremap <script><silent><nowait><expr> <C-Tab> trae#Accept()'
      vim.cmd 'imap <C-Enter> <Plug>(marscode-next-or-complete)'
      vim.defer_fn(function() vim.cmd.colorscheme 'tokyonight' end, 100) -- 不然virtualtext是白色的
    end,
  })
end

return specs
