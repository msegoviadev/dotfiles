return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false,
  },
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "pyright", "ts_ls", "jsonls", "terraformls", "yamlls", "marksman" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      vim.lsp.config.pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = {
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
          "pyrightconfig.json",
        },
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
            },
          },
        },
      }

      vim.lsp.config.ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json" },
      }

      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".git", ".luarc.json", ".luarc.jsonc", "stylua.toml" },
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (LuaJIT for Neovim)
              version = "LuaJIT",
            },
            diagnostics = {
              -- Recognize 'vim' as a global variable
              globals = { "vim" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = {
                vim.env.VIMRUNTIME,
              },
              -- Don't prompt about third party libraries
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
            hint = {
              enable = true,
              semicolon = "Disable",
            },
            codeLens = {
              enable = true,
            },
          },
        },
      }

      vim.lsp.config.jsonls = {
        cmd = { "vscode-json-language-server", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { ".git" },
        settings = {
          json = {
            format = {
              enable = true,
            },
            validate = { enable = true },
          },
        },
        on_new_config = function(new_config, root_dir)
          new_config.settings.json.schemas = new_config.settings.json.schemas or {}
          vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
        end,
      }

      vim.lsp.config.terraformls = {
        cmd = { "terraform-ls", "serve" },
        filetypes = { "terraform", "terraform-vars" },
        root_markers = { ".terraform", ".git" },
      }

      vim.lsp.config.yamlls = {
        cmd = { "yaml-language-server", "--stdio" },
        filetypes = { "yaml", "yaml.docker-compose" },
        root_markers = { ".git" },
        settings = {
          yaml = {
            schemas = require("schemastore").yaml.schemas(),
            validate = true,
            hover = true,
            completion = true,
            customTags = {
              "!reference sequence",
            },
          },
        },
      }

      vim.lsp.config.marksman = {
        cmd = { "marksman", "server" },
        filetypes = { "markdown", "markdown.mdx" },
        root_markers = { ".git", ".marksman.toml" },
      }

      -- Enable LSP servers
      vim.lsp.enable('pyright')
      vim.lsp.enable('ts_ls')
      vim.lsp.enable('lua_ls')
      vim.lsp.enable('jsonls')
      vim.lsp.enable('terraformls')
      vim.lsp.enable('yamlls')
      vim.lsp.enable('marksman')

      -- Instant-open picker for gr/gi/gy: opens the window after a short debounce
      -- if the response isn't back yet, instead of only mounting it once the full
      -- result list is ready like telescope.builtin's LSP pickers do.
      local function matches_any(str, patterns)
        for _, pattern in ipairs(patterns) do
          if str:find(pattern) then
            return true
          end
        end
        return false
      end

      -- require("telescope.builtin") normally merges telescope.lua's per-picker
      -- overrides (e.g. lsp_references' vertical layout) automatically. Calling
      -- pickers.new() directly skips that, so replicate the merge here.
      local function with_named_picker_defaults(picker_name, picker_opts)
        local pconf = require("telescope.config").pickers[picker_name] or {}
        local defaults = pconf.theme and require("telescope.themes")["get_" .. pconf.theme](pconf) or vim.deepcopy(pconf)
        return vim.tbl_extend("force", defaults, picker_opts)
      end

      local function lsp_picker(method, picker_name, title, picker_opts)
        picker_opts = with_named_picker_defaults(picker_name, picker_opts or {})
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local make_entry = require("telescope.make_entry")
        local actions = require("telescope.actions")

        local bufnr = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()

        local clients = vim.lsp.get_clients({ bufnr = bufnr, method = method })
        if #clients == 0 then
          vim.notify("No LSP client supports " .. method, vim.log.levels.WARN)
          return
        end

        local params = vim.lsp.util.make_position_params(win, clients[1].offset_encoding)
        if method == "textDocument/references" then
          params.context = { includeDeclaration = true }
        end

        local function open_picker(results, entry_maker)
          local p = pickers.new(picker_opts, {
            prompt_title = title,
            finder = finders.new_table({ results = results, entry_maker = entry_maker }),
            sorter = conf.generic_sorter(picker_opts),
            previewer = conf.qflist_previewer(picker_opts),
          })
          p:find()
          return p
        end

        local picker, shown = nil, false
        local timer = vim.defer_fn(function()
          shown = true
          picker = open_picker({})
        end, 80)

        vim.lsp.buf_request_all(bufnr, method, params, function(results_per_client)
          if not timer:is_closing() then
            timer:stop()
            timer:close()
          end

          local items = {}
          for client_id, resp in pairs(results_per_client) do
            local client = vim.lsp.get_client_by_id(client_id)
            local result = resp.result
            if client and result and not vim.tbl_isempty(result) then
              result = vim.tbl_islist(result) and result or { result }
              vim.list_extend(items, vim.lsp.util.locations_to_items(result, client.offset_encoding))
            end
          end

          if picker_opts.file_ignore_patterns then
            items = vim.tbl_filter(function(item)
              return not matches_any(item.filename, picker_opts.file_ignore_patterns)
            end, items)
          end

          if #items == 0 then
            if picker then
              actions.close(picker.prompt_bufnr)
            end
            vim.notify("No " .. title:lower() .. " found", vim.log.levels.INFO)
            return
          end

          if #items == 1 and not shown then
            -- locations_to_items already converted to a byte column, so "utf-8"
            -- here, not the client's negotiated encoding.
            vim.lsp.util.show_document({
              uri = vim.uri_from_fname(items[1].filename),
              range = {
                start = { line = items[1].lnum - 1, character = items[1].col - 1 },
                ["end"] = { line = items[1].lnum - 1, character = items[1].col - 1 },
              },
            }, "utf-8", { reuse_win = true, focus = true })
            return
          end

          local entry_maker = make_entry.gen_from_quickfix(picker_opts)
          if shown then
            picker:refresh(finders.new_table({ results = items, entry_maker = entry_maker }), { reset_prompt = false })
          else
            open_picker(items, entry_maker)
          end
        end)
      end

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf, desc = "" }

          -- Navigation
          vim.keymap.set("n", "gd", vim.lsp.buf.definition,
            vim.tbl_extend("force", opts, { desc = "[G]oto [D]efinition" }))
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration,
            vim.tbl_extend("force", opts, { desc = "[G]oto [D]eclaration" }))
          vim.keymap.set("n", "gi", function()
            lsp_picker("textDocument/implementation", "lsp_implementations", "Implementations", { show_line = false })
          end, vim.tbl_extend("force", opts, { desc = "[G]oto [I]mplementation" }))
          vim.keymap.set("n", "gy", function()
            lsp_picker("textDocument/typeDefinition", "lsp_type_definitions", "Type Definitions", { show_line = false })
          end, vim.tbl_extend("force", opts, { desc = "[G]oto T[y]pe Definition" }))
          vim.keymap.set("n", "gr", function()
            lsp_picker("textDocument/references", "lsp_references", "References", {
              show_line = false,
              -- exclude JDK internals, Maven/Gradle caches, and JDTLS workspace so
              -- results only show references within the current project
              file_ignore_patterns = {
                "^/usr/",
                "^" .. vim.fn.expand("~") .. "/.m2/",
                "^" .. vim.fn.expand("~") .. "/.gradle/",
                "^" .. vim.fn.expand("~") .. "/.jdtls/",
                "^" .. vim.fn.expand("~") .. "/.cache/",
              },
            })
          end, vim.tbl_extend("force", opts, { desc = "[G]oto [R]eferences" }))

          -- Hover and signature help
          vim.keymap.set("n", "<leader>k", vim.lsp.buf.hover,
            vim.tbl_extend("force", opts, { desc = "[K]nowledge / Hover Documentation" }))
          vim.keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help,
            vim.tbl_extend("force", opts, { desc = "Signature Help" }))

          -- Code actions and refactoring
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "[C]ode [A]ction" }))
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,
            vim.tbl_extend("force", opts, { desc = "[R]e[n]ame Symbol" }))

          -- Formatting
          vim.keymap.set("n", "<leader>l", vim.lsp.buf.format,
            vim.tbl_extend("force", opts, { desc = "[L]SP Format" }))

          -- Document and workspace symbols
          vim.keymap.set("n", "<leader>ss", function()
            require("telescope.builtin").lsp_document_symbols({
              show_line = false,
            })
          end, vim.tbl_extend("force", opts, { desc = "[S]earch Document [S]ymbols" }))
          vim.keymap.set("n", "<leader>sS", function()
            require("telescope.builtin").lsp_workspace_symbols({
              show_line = false,
            })
          end, vim.tbl_extend("force", opts, { desc = "[S]earch Workspace [S]ymbols" }))

          -- Call hierarchy
          vim.keymap.set("n", "<leader>ci", function()
            vim.lsp.buf.incoming_calls()
          end, vim.tbl_extend("force", opts, { desc = "[C]all Hierarchy [I]ncoming" }))
          vim.keymap.set("n", "<leader>co", function()
            vim.lsp.buf.outgoing_calls()
          end, vim.tbl_extend("force", opts, { desc = "[C]all Hierarchy [O]utgoing" }))
        end,
      })
    end,
  },
}
