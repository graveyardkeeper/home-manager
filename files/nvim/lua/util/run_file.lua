local M = {}

---@param buf? number
local function close_terminal_win(buf)
  local win = buf and buf > 0 and vim.b[buf].run_file_terminal_win or vim.b.run_file_terminal_win
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, false)
    vim.b.run_file_terminal_win = nil
  end
end

function M.run_file()
  local file_buf = vim.api.nvim_get_current_buf()
  if vim.bo.modified then vim.cmd 'noa write' end
  close_terminal_win()
  local terminal = Snacks.win.new { position = 'bottom', enter = false }
  vim.b[file_buf].run_file_terminal_win = terminal.win
  vim.api.nvim_buf_call(terminal.buf, function()
    local job_id = vim.fn.jobstart({ 'run-file', vim.api.nvim_buf_get_name(file_buf) }, {
      term = true,
      on_stdout = function(_, data, _)
        if data then
          -- 确保光标在最后一行
          local last_line = vim.api.nvim_buf_line_count(terminal.buf)
          vim.api.nvim_win_set_cursor(terminal.win, { last_line, 0 })
        end
      end,
    })

    local ag = vim.api.nvim_create_augroup('run_file_clean_job', { clear = true })
    vim.api.nvim_create_autocmd('WinClosed', {
      group = ag,
      pattern = tostring(terminal.win),
      once = true,
      callback = function()
        if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
          vim.fn.jobstop(job_id)
          vim.b.run_file_job_id = nil
        end
      end,
    })
  end)
end

return M
