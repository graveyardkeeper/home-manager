return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false,
    lazy = false,
    -- enabled=false,
    build = ':TSUpdate',
    config = function()
      local ts = require 'nvim-treesitter'
      local need_install_langs = vim.split(
        'bash,c,cmake,corn,cpp,css,csv,diff,dockerfile,fish,git_config,gitcommit,gitignore,go,gomod,gosum,gotmpl,gowork,graphql,html,http,ini,java,javascript,jq,jsdoc,json,json5,just,latex,lua,luadoc,luap,markdown,markdown_inline,nginx,ninja,nix,nu,printf,proto,python,query,regex,ron,rst,rust,scss,smali,sql,ssh_config,thrift,todotxt,toml,tsx,typescript,vim,vimdoc,vue,xml,yaml',
        ','
      )
      vim.api.nvim_create_autocmd('FileType', {
        pattern = need_install_langs,
        callback = function()
          vim.treesitter.start()
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
      ts.install(need_install_langs)
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = 'VeryLazy',
    keys = function()
      local moves = {}
      local ret = {}
      for method, keymaps in pairs(moves) do
        for key, query in pairs(keymaps) do
          table.insert(ret, {
            key,
            function() require('nvim-treesitter-textobjects.move')[method](query, 'textobjects') end,
            mode = { 'n', 'x', 'o' },
            silent = true,
          })
        end
      end
      return ret
    end,
    config = function()
      local ts = require 'nvim-treesitter-textobjects'
      ts.setup {}
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    keys = {},
    config = function()
      require('treesitter-context').setup {
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
      }
    end,
  },
}
