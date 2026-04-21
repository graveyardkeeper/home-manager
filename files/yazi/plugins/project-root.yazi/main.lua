--- @sync entry

local emit_cd = ya.sync(function(_, target)
  ya.emit("cd", { target, raw = true })
end)

local function entry()
  local cwd = tostring(cx.active.current.cwd)
  local helper = os.getenv("HOME") .. "/.local/bin/yazi-go-project-root"

  ya.async(function()
    local child, err = Command(helper)
      :arg(cwd)
      :stdout(Command.PIPED)
      :stderr(Command.PIPED)
      :spawn()

    if not child then
      return ya.notify({ title = "project-root", content = "spawn failed: " .. tostring(err), level = "error", timeout = 5 })
    end

    local stdout_lines = {}
    local stderr_lines = {}
    while true do
      local line, event = child:read_line_with { timeout = 300 }
      if event == 2 then
        break
      elseif event == 1 then
        table.insert(stderr_lines, line)
      elseif event == 0 then
        table.insert(stdout_lines, line)
      end
    end

    local status, wait_err = child:wait()
    if not status then
      return ya.notify({ title = "project-root", content = "wait failed: " .. tostring(wait_err), level = "error", timeout = 5 })
    end

    if not status.success then
      return ya.notify({ title = "project-root", content = table.concat(stderr_lines, ""):gsub("%s+$", ""), level = "error", timeout = 5 })
    end

    local target = table.concat(stdout_lines, ""):gsub("%s+$", "")
    if target == "" then
      return ya.notify({ title = "project-root", content = "empty result", level = "warn", timeout = 5 })
    end

    emit_cd(target)
  end)
end

return { entry = entry }
