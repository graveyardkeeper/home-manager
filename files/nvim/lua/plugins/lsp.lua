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
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    config = false, -- see ~/.config/nvim/after/ftplugin/java.lua
  },
  {
    'Wansmer/symbol-usage.nvim',
    event = 'LspAttach',
    config = function()
      local SymbolKind = vim.lsp.protocol.SymbolKind

      require('symbol-usage').setup {
        kinds = {
          SymbolKind.Function,
          SymbolKind.Method,
          SymbolKind.Interface,
          SymbolKind.Struct,
          SymbolKind.Class,
          SymbolKind.TypeParameter,
        },
        references = {
          enabled = true,
          include_declaration = false,
        },
        definition = {
          enabled = false,
        },
        implementation = {
          enabled = false,
        },
        vt_position = 'above',
      }
    end,
  },
  -- {
  --   'p00f/clangd_extensions.nvim',
  --   ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  --   config = function() require('clangd_extensions').setup {} end,
  -- },
}
