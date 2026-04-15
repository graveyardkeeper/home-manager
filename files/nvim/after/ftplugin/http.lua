local kulala = require 'kulala'

local function map(mode, key, rhs, opt)
  vim.keymap.set(mode, key, rhs, vim.tbl_extend('force', { buffer = 0, nowait = true, silent = true }, opt))
end

map('n', '<CR>', kulala.run, { desc = 'Execute the request' })
map('n', '<leader>i', kulala.inspect, { desc = 'Inspect the current request' })
map('n', 'jj', kulala.jump_prev, { desc = 'Jump to the previous request' })
map('n', 'll', kulala.jump_next, { desc = 'Jump to the next request' })
map('n', '<leader>co', kulala.copy, { desc = 'Copy as curl' })
map('n', '<leader>ss', kulala.search, { desc = 'Search all named requests' })
map('n', '<leader>se', kulala.set_selected_env, { desc = 'Search environment' })
map('n', '<leader>ci', kulala.from_curl, { desc = 'Jump to the next request' })
