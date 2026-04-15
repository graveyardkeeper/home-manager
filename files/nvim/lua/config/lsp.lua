local function root_pattern(glob)
  local files = vim.fs.find(
    function(name, path) return name:match '.*%.[ch]pp$' and path:match '[/\\]lib$' end,
    { limit = math.huge, type = 'file' }
  )
end

local function setup_lspconfig()
  ---@type table<string,vim.lsp.Config>
  local configs = {
    jinja_lsp = {
      cmd = { 'jinja-lsp' },
      filetypes = { 'jinja' },
      root_markers = { '.git' },
    },
    docker_compose_language_service = {
      cmd = { 'docker-compose-langserver', '--stdio' },
      filetypes = { 'yaml.docker-compose' },
      root_markers = { 'docker-compose.yaml', 'docker-compose.yml', 'compose.yaml', 'compose.yml' },
    },
    kulala_ls = {
      cmd = { 'kulala-ls', '--stdio' },
      filetypes = { 'http' },
    },
    biome = {
      cmd = { 'biome', 'lsp-proxy' },
      filetypes = {
        'astro',
        'css',
        'graphql',
        'javascript',
        'javascriptreact',
        'json',
        'jsonc',
        'svelte',
        'typescript',
        'typescript.tsx',
        'typescriptreact',
        'vue',
      },
      root_markers = { 'biome.json', 'biome.jsonc', 'package.json' },
    },
    gopls = {
      cmd = { 'gopls', '-remote=auto', '-logfile=auto' },
      -- cmd = { 'gopls' },
      filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
      root_markers = { 'go.work', 'go.mod' },
      settings = {
        gopls = {
          gofumpt = true,
          hints = {
            parameterNames = false,
            compositeLiteralFields = true,
            constantValues = true,
            assignVariableTypes = false,
            compositeLiteralTypes = false,
            functionTypeParameters = false,
            rangeVariableTypes = false,
          },
          usePlaceholders = false,
          completeUnimported = true,
          staticcheck = false,
          analyses = {
            fieldalignment = false,
          },
          semanticTokens = true,
        },
      },
    },
    marksman = {
      cmd = { 'marksman', 'server' },
      filetypes = { 'markdown', 'markdown.mdx' },
      root_markers = { '.marksman.toml' },
    },
    lua_ls = {
      cmd = { 'lua-language-server' },
      filetypes = { 'lua' },
      root_markers = {
        '.luarc.json',
        '.luarc.jsonc',
        '.luacheckrc',
        '.stylua.toml',
        'stylua.toml',
        'selene.toml',
        'selene.yml',
      },
      settings = {
        Lua = {
          doc = { privateName = { '^_' } },
          codeLens = { enable = false },
          workspace = {
            checkThirdParty = false,
            ignoreDir = { '.vscode', '.direnv', 'node_modules' },
          },
        },
      },
    },
    nil_ls = {
      cmd = { 'nil' },
      filetypes = { 'nix' },
      root_markers = { 'flake.nix' },
    },
    nushell = {
      cmd = { 'nu', '--lsp' },
      filetypes = { 'nu' },
    },
    ruff = {
      cmd = { 'ruff', 'server' },
      filetypes = { 'python' },
      root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml' },
      settings = {},
    },
    taplo = {
      cmd = { 'taplo', 'lsp', 'stdio' },
      filetypes = { 'toml' },
    },
    ts_ls = {
      init_options = { hostInfo = 'neovim' },
      cmd = { 'typescript-language-server', '--stdio' },
      filetypes = {
        'javascript',
        'javascriptreact',
        'javascript.jsx',
        'typescript',
        'typescriptreact',
        'typescript.tsx',
      },
      root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json' },
    },
    typos_lsp = {
      cmd = { 'typos-lsp' },
      root_markers = { 'typos.toml', '_typos.toml', '.typos.toml' },
      init_options = {
        diagnosticSeverity = 'Hint',
      },
    },
    dockerls = {
      cmd = { 'docker-langserver', '--stdio' },
      filetypes = { 'dockerfile' },
      root_markers = { 'Dockerfile' },
    },
    thriftls = {
      cmd = { 'thriftls' },
      filetypes = { 'thrift' },
      root_markers = { '.thrift' },
    },
    jsonls = {
      cmd = { 'vscode-json-language-server', '--stdio' },
      filetypes = { 'json', 'jsonc' },
    },
    bashls = {
      cmd = { 'bash-language-server', 'start' },
      settings = {
        bashIde = {
          globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command)',
        },
      },
      filetypes = { 'bash', 'sh' },
    },
    yamlls = {
      cmd = { 'yaml-language-server', '--stdio' },
      filetypes = { 'yaml', 'yaml.docker-compose', 'yaml.gitlab' },
      settings = {
        -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
        redhat = { telemetry = { enabled = false } },
        yaml = {
          schemas = {
            ['https://json.schemastore.org/github-workflow.json'] = '/.github/workflows/*',
          },
        },
      },
    },
    just = {
      cmd = { 'just-lsp' },
      filetypes = { 'just' },
    },
    clangd = {
      cmd = (os.getenv 'IDF_PATH') and { 'clangd', '--background-index', '--query-driver=**' }
        or { 'clangd', '--background-index', '--clang-tidy' },
      filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
      root_markers = {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        'configure.ac', -- AutoTools
      },
      capabilities = {
        textDocument = {
          completion = {
            editsNearCursor = true,
          },
        },
        offsetEncoding = { 'utf-16' }, -- refer to https://www.lazyvim.org/configuration/recipes#fix-clangd-offset-encoding
      },
      on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'ClangdSwitchSourceHeader', function()
          local method_name = 'textDocument/switchSourceHeader'
          if not client then
            return vim.notify(
              ('method %s is not supported by any servers active on the current buffer'):format(method_name)
            )
          end
          local params = vim.lsp.util.make_text_document_params(bufnr)
          client:request(method_name, params, function(err, result)
            if err then error(tostring(err)) end
            if not result then
              vim.notify 'corresponding file cannot be determined'
              return
            end
            vim.cmd.edit(vim.uri_to_fname(result))
          end, bufnr)
        end, { desc = 'Switch between source/header' })

        vim.api.nvim_buf_create_user_command(bufnr, 'ClangdShowSymbolInfo', function()
          if not client or not client:supports_method('textDocument/symbolInfo', bufnr) then
            return vim.notify('Clangd client not found', vim.log.levels.ERROR)
          end
          local win = vim.api.nvim_get_current_win()
          local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
          client:request('textDocument/symbolInfo', params, function(err, res)
            if err or #res == 0 then
              -- Clangd always returns an error, there is not reason to parse it
              return
            end
            local container = string.format('container: %s', res[1].containerName) ---@type string
            local name = string.format('name: %s', res[1].name) ---@type string
            vim.lsp.util.open_floating_preview({ name, container }, '', {
              height = 2,
              width = math.max(string.len(name), string.len(container)),
              focusable = false,
              focus = false,
              border = 'single',
              title = 'Symbol Info',
            })
          end, bufnr)
        end, { desc = 'Show symbol info' })
      end,
    },
    pyright = {
      cmd = { 'pyright-langserver', '--stdio' },
      filetypes = { 'python' },
      root_markers = {
        'pyproject.toml',
        'setup.py',
        'setup.cfg',
        'requirements.txt',
        'Pipfile',
        'pyrightconfig.json',
      },
      settings = {
        python = {
          analysis = {
            autoSearchPaths = true,
            useLibraryCodeForTypes = true,
            diagnosticMode = 'openFilesOnly',
          },
        },
      },
      on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, 'PyrightOrganizeImports', function()
          local params = {
            command = 'pyright.organizeimports',
            arguments = { vim.uri_from_bufnr(bufnr) },
          }
          client:request('workspace/executeCommand', params, nil, bufnr)
        end, { desc = 'Organize Imports' })

        vim.api.nvim_buf_create_user_command(bufnr, 'ClangdShowSymbolInfo', function(path)
          if client.settings then
            ---@type table
            ---@diagnostic disable-next-line: assign-type-mismatch
            local orig = client.settings.python
            client.settings.python = vim.tbl_deep_extend('force', orig, { pythonPath = path })
          else
            client.config.settings =
              vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
          end
          client:notify('workspace/didChangeConfiguration', { settings = nil })
        end, { desc = 'Reconfigure pyright with the provided python path', nargs = 1, complete = 'file' })
      end,
    },
    buf_ls = {
      cmd = { 'buf', 'lsp', 'serve', '--timeout=0', '--log-format=text' },
      filetypes = { 'proto' },
      root_markers = { 'buf.yaml', '.git' },
    },
    arduino_language_server = {
      filetypes = { 'arduino' },
      cmd = (function()
        local cmd = {
          'arduino-language-server',
        }
        if vim.env.ARDUINO_CLI_CONFIG then
          table.insert(cmd, '--cli-config')
          table.insert(cmd, vim.env.ARDUINO_CLI_CONFIG)
        end
        return cmd
      end)(),
      root_markers = {
        'sketch.yaml',
        '.envrc',
      },
      capabilities = {
        textDocument = {
          semanticTokens = vim.NIL,
        },
        workspace = {
          semanticTokens = vim.NIL,
        },
      },
    },
  }

  local function validate(config)
    if type(config.cmd) == 'function' then
      return true
    elseif type(config.cmd) == 'table' then
      return vim.fn.executable(config.cmd[1]) ~= 0
    end
    return false
  end

  local can_enable = {}
  for name, config in pairs(configs) do
    if validate(config) then
      table.insert(can_enable, name)
      config.root_markers = vim.list_extend(config.root_markers or {}, { '.git' })
      vim.lsp.config(name, config)
    end
  end

  ---@type vim.lsp.Config
  local attachCodeLens = {
    on_attach = function(client, bufnr)
      if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_codeLens, bufnr) then
        vim.lsp.codelens.refresh()
        vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave' }, {
          buffer = bufnr,
          callback = vim.lsp.codelens.refresh,
        })
      end
    end,
  }

  vim.lsp.config('*', attachCodeLens)
  vim.lsp.enable(can_enable)

  vim.diagnostic.config {
    underline = true,
    virtual_text = true,
    update_in_insert = false,
    severity_sort = true,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = ' ',
        [vim.diagnostic.severity.WARN] = ' ',
        [vim.diagnostic.severity.HINT] = ' ',
        [vim.diagnostic.severity.INFO] = ' ',
      },
    },
  }
end

setup_lspconfig()
