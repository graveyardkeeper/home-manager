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
  -- {
  --   'p00f/clangd_extensions.nvim',
  --   ft = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
  --   config = function() require('clangd_extensions').setup {} end,
  -- },
}
