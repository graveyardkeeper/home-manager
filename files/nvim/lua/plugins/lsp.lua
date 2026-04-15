---@diagnostic disable: missing-fields

return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    cmd = 'LazyDev',
    config = function()
      require('lazydev').setup {
        library = {
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          { path = 'snacks.nvim', words = { 'Snacks' } },
        },
      }
    end,
  },
  {
    'mrcjkb/rustaceanvim',
    version = '^5', -- Recommended
    ft = 'rust',
    init = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        tools = {},
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr) vim.lsp.inlay_hint.enable(true, { bufnr = bufnr }) end,
          default_settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
              },
              checkOnSave = {
                enable = true,
              },
              diagnostics = {
                enable = true,
              },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                  ['async-recursion'] = { 'async_recursion' },
                },
              },
              files = {
                excludeDirs = {
                  '.direnv', -- IMPORTANT: https://github.com/rust-lang/rust-analyzer/issues/12613
                  '.git',
                  '.github',
                  '.gitlab',
                  'bin',
                  'node_modules',
                  'target',
                  'venv',
                  '.venv',
                },
              },
            },
          },
        },
        -- DAP configuration
        dap = {},
      }
    end,
  },
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    config = false, -- see ~/.config/nvim/after/ftplugin/java.lua
  },
  -- {
  --   'p00f/clangd_extensions.nvim',
  --   ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  --   config = function() require('clangd_extensions').setup {} end,
  -- },
}
