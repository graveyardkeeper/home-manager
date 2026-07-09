local M = {}

local function command(text)
  local translate = vim.fn.exepath 'translate'
  if translate ~= '' then return { translate, '--format', 'json', text } end

  local fish = vim.fn.expand '~/.nix-profile/bin/fish'
  if vim.fn.executable(fish) == 1 then return { fish, '-lc', 'exec translate --format json "$argv[1]"', text } end

  return { 'translate', '--format', 'json', text }
end

function M.show_popup(text)
  if text == '' then return end

  vim.system(command(text), { text = true, timeout = 20000 }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local message = result.stderr ~= '' and result.stderr or result.stdout
        vim.notify(vim.trim(message), vim.log.levels.ERROR)
        return
      end

      local output = vim.trim(result.stdout)
      if output == '' then return end

      local ok, payload = pcall(vim.json.decode, output)
      if ok and type(payload) == 'table' then
        require('util.ui').show_translate_popup(payload)
      else
        require('util.ui').show_temporary_popup(output)
      end
    end)
  end)
end

return M
