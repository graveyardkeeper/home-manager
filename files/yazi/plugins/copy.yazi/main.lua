--- @sync entry

return {
  entry = function(_, job)
    local action = job.args[1]
    if action == nil then return end

    local hovered = cx.active.current.hovered
    if hovered == nil then return end

    local helper = os.getenv('HOME') .. '/.local/bin/yazi-copy-relative-path'
    local path = tostring(hovered.url)

    ya.async(function()
      local child, err = Command(helper)
        :arg(action)
        :arg(path)
        :stdout(Command.PIPED)
        :stderr(Command.PIPED)
        :spawn()

      if not child then
        return ya.notify({ title = 'copy', content = 'spawn failed: ' .. tostring(err), level = 'error', timeout = 5 })
      end

      local stderr_lines = {}
      while true do
        local line, event = child:read_line_with { timeout = 300 }
        if event == 2 then
          break
        elseif event == 1 then
          table.insert(stderr_lines, line)
        end
      end

      local status, wait_err = child:wait()
      if not status then
        return ya.notify({ title = 'copy', content = 'wait failed: ' .. tostring(wait_err), level = 'error', timeout = 5 })
      end

      if not status.success then
        return ya.notify({ title = 'copy', content = table.concat(stderr_lines, ''):gsub('%s+$', ''), level = 'error', timeout = 5 })
      end

      local content = action == 'repo-relative-dir' and 'Copied relative dir: ' or 'Copied relative path: '
      local copied, read_err = Command('pbpaste'):output()
      if not copied then
        return ya.notify({ title = 'copy', content = 'pbpaste failed: ' .. tostring(read_err), level = 'error', timeout = 5 })
      end

      local text = copied.stdout:gsub('%s+$', '')
      ya.notify({ title = 'copy', content = content .. text, level = 'info', timeout = 3 })
    end)
  end,
}
