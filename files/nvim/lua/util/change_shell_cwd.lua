local Path = require("plenary.path")

return {
  change_fish_cwd = function()
    local cwd_file = vim.env.CWD_FILE
    local shell_pid = vim.env.SHELL_PID
    if cwd_file and shell_pid then
      Path:new(cwd_file):write(vim.uv.cwd(), "w")
      vim.system({ "kill", "-s", "USR1", shell_pid })
    end
  end,
}
