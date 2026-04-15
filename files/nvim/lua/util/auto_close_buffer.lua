local M = {
  pinned_buffers = {},
  config = {
    threshold = 2,
  },
}

function M.is_pinned(bufnr)
  return M.pinned_buffers[bufnr] == true
end

function M.toggle_pin(bufnr)
  M.pinned_buffers[bufnr] = not M.pinned_buffers[bufnr]
  return M.pinned_buffers[bufnr]
end

local function au_close_buf()
  vim.api.nvim_create_autocmd({ "BufNew" }, {
    -- group = vim.api.nvim_create_augroup(M.autoclose.name, { clear = true }),
    pattern = { "*" },
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = current_buf })
      -- if the buffer is not a file - do nothing
      if buftype ~= "" then
        return
      end

      local unpin_buffers = vim.tbl_filter(function(buf)
        -- Filter out buffers that are not listed
        return vim.api.nvim_get_option_value("buflisted", { buf = buf }) and not M.is_pinned(buf)
      end, vim.api.nvim_list_bufs())

      local num_buffers = #unpin_buffers

      if num_buffers <= M.config.threshold then
        return
      end

      local buffers_to_close = num_buffers - M.config.threshold

      -- Buffer sorted by current > pinned > is_in_window > named > unnamed
      table.sort(unpin_buffers, function(a, b)
        if a == current_buf or b == current_buf then
          return b == current_buf
        end

        local a_windowed = #(vim.fn.win_findbuf(a)) > 0
        local b_windowed = #(vim.fn.win_findbuf(b)) > 0
        if a_windowed ~= b_windowed then
          return b_windowed
        end

        local a_unnamed = vim.api.nvim_buf_get_name(a) == ""
        local b_unnamed = vim.api.nvim_buf_get_name(b) == ""
        if a_unnamed ~= b_unnamed then
          return a_unnamed
        end

        return a < b
      end)

      for i = 1, buffers_to_close, 1 do
        local buffer = unpin_buffers[i]
        vim.api.nvim_buf_delete(buffer, {})
      end
    end,
  })
end

local function au_pin_edited()
  vim.api.nvim_create_autocmd({ "BufRead" }, {
    -- group = id,
    pattern = { "*" },
    callback = function()
      vim.api.nvim_create_autocmd({ "InsertEnter", "BufModifiedSet" }, {
        buffer = 0,
        once = true,
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          if M.is_pinned(bufnr) then
            return
          end
          M.toggle_pin(bufnr)
        end,
      })
    end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  au_pin_edited()
  au_close_buf()
end

return M
