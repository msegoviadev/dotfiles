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
            require("telescope.builtin").lsp_implementations({
              show_line = false,
            })
          end, vim.tbl_extend("force", opts, { desc = "[G]oto [I]mplementation" }))
          vim.keymap.set("n", "gy", function()
            require("telescope.builtin").lsp_type_definitions({
              show_line = false,
            })
          end, vim.tbl_extend("force", opts, { desc = "[G]oto T[y]pe Definition" }))
          vim.keymap.set("n", "gr", function()
            require("telescope.builtin").lsp_references({
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
