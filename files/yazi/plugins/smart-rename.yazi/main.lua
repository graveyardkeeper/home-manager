--- @sync entry

local function notify_error(content)
  ya.notify({ title = "smart-rename", content = content, level = "error", timeout = 5 })
end

local function basename(path)
  return path:match("([^/]+)/*$") or path
end

local function dirname(path)
  local dir = path:match("^(.*)/[^/]+/*$")
  if dir == "" then return "/" end
  return dir or "."
end

local reveal = ya.sync(function(_, path)
  ya.emit("reveal", { path, no_dummy = true, raw = true })
end)

local function run_helper(helper, mode, dir, old_name, new_name)
  local output, err = Command(helper)
    :arg(mode)
    :arg(dir)
    :arg(old_name)
    :arg(new_name)
    :output()

  if not output then
    return nil, "helper failed: " .. tostring(err)
  end
  if not output.status.success then
    return nil, output.stderr:gsub("%s+$", "")
  end

  local result = ya.json_decode(output.stdout or "")
  if not result then
    return nil, "invalid helper output"
  end

  return result, nil
end

local function maybe_sync_go_package(new_path, old_name, new_name)
  if os.getenv("NVIM_CWD") == nil then return end

  local helper = os.getenv("HOME") .. "/.local/bin/yazi-sync-go-package"
  local result, err = run_helper(helper, "--check", new_path, old_name, new_name)
  if err then return notify_error(err) end

  local files = result.files or {}
  if #files == 0 then return end

  local answer = ya.confirm({
    title = "Update Go package name?",
    body = string.format(
      "Directory renamed:\n  %s -> %s\n\nChange Go package:\n  package %s -> package %s\n\nFiles to update: %d",
      old_name,
      new_name,
      result.oldPackage,
      result.newPackage,
      #files
    ),
    pos = { "center", w = 60, h = 12 },
  })
  if not answer then return end

  local applied, apply_err = run_helper(helper, "--apply", new_path, old_name, new_name)
  if apply_err then return notify_error(apply_err) end

  ya.notify({
    title = "smart-rename",
    content = string.format("Updated Go package in %d file(s)", #(applied.files or {})),
    level = "info",
    timeout = 3,
  })
end

local function entry()
  local hovered = cx.active.current.hovered
  if hovered == nil then return end

  local old_url = hovered.url
  local old_path = tostring(old_url)
  local old_name = old_url.name or basename(old_path)
  local old_parent = old_url.parent and tostring(old_url.parent) or dirname(old_path)
  local is_dir = hovered.cha.is_dir

  ya.async(function()
    local new_name, event = ya.input({
      title = "Rename:",
      value = old_name,
      pos = { "top-center", y = 3, w = 50 },
    })
    if event ~= 1 or new_name == nil or new_name == "" or new_name == old_name then return end
    if new_name:find("/", 1, true) then
      return notify_error("new name must not contain /")
    end

    local new_path = old_parent .. "/" .. new_name
    local new_url = Url(new_path)
    local existing = fs.cha(new_url)
    if existing then
      return notify_error("target already exists: " .. new_name)
    end

    local ok, err = fs.rename(old_url, new_url)
    if not ok then
      return notify_error("rename failed: " .. tostring(err))
    end

    reveal(new_path)

    if is_dir then
      maybe_sync_go_package(new_path, old_name, new_name)
    end
  end)
end

return { entry = entry }
