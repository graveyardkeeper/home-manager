local Path = require("plenary.path")

local function on_rust_open(target_dir)
  local lines = {}

  local rs_files = vim.fn.globpath(target_dir, "*.rs", false, true)
  for _, f in ipairs(rs_files) do
    local filename = vim.fs.basename(f)
    local mod = filename:match([[%d+%.(.+)%.rs]])
    if mod then
      mod = mod:gsub("-", "_")
      table.insert(lines, string.format('#[path = "%s"]\n', filename))
      table.insert(lines, "mod " .. mod .. ";\n")
    end
  end

  if not next(lines) then
    vim.notify("No .rs files found in directory: " .. target_dir)
    return
  end
  table.insert(lines, "\nfn main() {}\n")

  Path:new(target_dir .. "/main.rs"):write(lines, "w")
end

return {
  on_question_open = function(lang, target_dir)
    if vim.fn.isdirectory(target_dir) ~= 1 then
      vim.notify("Directory " .. target_dir .. " does not exist.")
      return
    end

    if lang == "rust" then
      on_rust_open(target_dir)
    end
  end,
}
