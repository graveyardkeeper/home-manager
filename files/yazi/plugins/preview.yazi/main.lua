local M = {}

local preview_script_path = 'preview'

local function split_area(area, arg)
  local x, y, w, h = area.x, area.y, area.w, area.h
  local top = ui.Rect { x = x, y = y, w = w, h = h * arg }
  local bottom = ui.Rect { x = x, y = y + h * arg, w = w, h = h * (1 - arg) }
  return top, bottom
end

local loading_text = (function()
  local i = 1
  local frames = {
    '▱▱▱',
    '▰▱▱',
    '▰▰▱',
    '▰▰▰',
    '▰▰▱',
    '▰▱▱',
    '▱▱▱',
  }
  return function()
    i = (i % #frames) + 1
    return 'Loading' .. frames[i]
  end
end)()

local function loading(job, area)
  local x, y, w, h = area.x, area.y, area.w, area.h
  local loading_area = ui.Rect { x = (x + w / 2 - 4), y = (y + h / 2), w = w, h = 1 }
  ya.preview_widgets(job, { ui.Text.parse(loading_text()):area(loading_area) })
end

function M:peek(job)
  local limit = job.area.h
  local offset = job.skip
  local text_offset = job.skip * (job.area.h / 2)
  local args = {
    '--path',
    tostring(job.file.url),
    '--width',
    tostring(job.area.w),
    '--height',
    tostring(job.area.h),
    '--offset',
    tostring(offset),
  }
  ya.dbg(preview_script_path .. ' ' .. table.concat(args, ' '))
  local child = Command(preview_script_path):arg(args):stdout(Command.PIPED):stderr(Command.PIPED):spawn()

  local text_area = job.area
  local i, stdout_lines, disable_peek = 0, {}, false
  local stderr_lines = {}
  repeat
    local line, event = child:read_line_with { timeout = 300 }
    if event == 3 then
      loading(job, text_area)
    elseif event == 2 then -- There's no data to read from both stdout and stderr
      break
    elseif event == 1 then -- come from stderr
      table.insert(stderr_lines, line)
    elseif event == 0 then
      if i == 0 then
        local image_path = line:match '^__preview__image__path__ (.+)\n'
        if image_path then
          text_offset = 1
          disable_peek = true
          limit = limit / 2
          local top, bottom = split_area(job.area, 0.4)
          text_area = bottom
          ya.image_show(Url(image_path), top)
        elseif line == '__disable_auto_peek__\n' then
          disable_peek = true
          text_offset = 1
        end
      end

      i = i + 1
      if i > text_offset then table.insert(stdout_lines, line) end
    end
  until i >= text_offset + limit

  if i < limit then
    local status = child:wait()
    local code = status and status.code or 0

    if code == 3 then
      -- 3 表示: 预览滚动溢出,需要往上退一下
      ya.manager_emit('peek', { tostring(math.max(0, offset - 1)), only_if = tostring(job.file.url), upper_bound = '' })
      return
    end
  else
    child:start_kill()
  end

  if not disable_peek and text_offset > 0 and i < text_offset + limit / 2 then
    ya.manager_emit('peek', { tostring(math.max(0, offset - 1)), only_if = tostring(job.file.url), upper_bound = '' })
  else
    local stderr = table.concat(stderr_lines, '')
    local stdout = table.concat(stdout_lines, '')
    ya.dbg('stderr:', stderr)
    ya.dbg('stdout:', stdout)
    local lines = (stderr .. stdout):gsub('\t', ' ')
    ya.preview_widgets(job, { ui.Text.parse(lines):area(text_area) })
  end
end

function M:seek(job)
  local h = cx.active.current.hovered
  if h and h.url == job.file.url then
    ya.manager_emit('peek', {
      tostring(math.max(0, cx.active.preview.skip + (job.units > 0 and 1 or -1))),
      only_if = tostring(job.file.url),
    })
  end
end

return M
