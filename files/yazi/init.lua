require('session'):setup {
  sync_yanked = true,
}

function Linemode:mime() return ui.Line(self._file:mime() or '') end


-- top bar add host@name
Header:children_add(function()
  if ya.target_family() ~= 'unix' then return ui.Line {} end
  return ui.Span(ya.user_name() .. '@' .. ya.host_name() .. ':'):fg('green'):bold()
end, 500, Header.LEFT)

-- bottom bar add owner:group
Status:children_add(function()
  local h = cx.active.current.hovered
  if h == nil or ya.target_family() ~= 'unix' then return ui.Line {} end

  return ui.Line {
    ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg 'magenta',
    ui.Span ':',
    ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg 'magenta',
    ui.Span ' ',
  }
end, 500, Status.RIGHT)

-- plugin setup
require('git'):setup { order = 1500 }

require('mime-ext.local'):setup {
  with_files = {
    makefile = 'text/makefile',
    ['uv.lock'] = 'text/toml',
    ['go.mod'] = 'text/plain',
    ['go.sum'] = 'text/plain',
    ['.clangd'] = 'text/yaml',
    justfile = 'text/x-makefile',
  },
  with_exts = {
    mk = 'text/makefile',
    raf = 'image/fuji-raf',
    http = 'text/http',
    jsonl = 'application/json',
  },
  fallback_file1 = true,
}

require('full-border'):setup { type = ui.Border.ROUNDED }

require('yamb'):setup {}

require('folder-rules'):setup()
