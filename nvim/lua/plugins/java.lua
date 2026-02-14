return {
  {
    'nvim-java/nvim-java',
    ft = { 'java' },
    dependencies = {
      'MunifTanjim/nui.nvim',
      'mfussenegger/nvim-dap',
      {
        'JavaHello/spring-boot.nvim',
        commit = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
      },
    },
    config = function()
      require('java').setup({
        checks = {
          nvim_jdtls_conflict = false,
        },

        jdk = {
          auto_install = false, -- Use system Java
        },

        lombok = {
          enable = true,
        },

        java_test = {
          enable = true,
        },

        java_debug_adapter = {
          enable = true,
        },

        spring_boot_tools = {
          enable = true,
        },
      })

      -- Configure runtimes as per README
      vim.lsp.config('jdtls', {
        settings = {
          java = {
            configuration = {
              runtimes = {
                {
                  name = "JavaSE-1.8",
                  path = vim.fn.expand("~/.sdkman/candidates/java/8.0.462-amzn"),
                  default = true,
                },
                {
                  name = "JavaSE-21",
                  path = vim.fn.expand("~/.sdkman/candidates/java/21.0.9-amzn"),
                },
              }
            }
          }
        }
      })

      -- Enable JDTLS
      vim.lsp.enable('jdtls')

      -- Java keymaps (only loaded when Java files are opened)
      vim.keymap.set("n", "<leader>jt", function()
        require('dapui').open()
        require('java').test.run_current_method()
      end, { desc = "[J]ava: [T]est Method" })

      vim.keymap.set("n", "<leader>jT", function()
        require('dapui').open()
        require('java').test.run_current_class()
      end, { desc = "[J]ava: [T]est Class" })

      vim.keymap.set("n", "<leader>jr", ":JavaTestViewLastReport<CR>", { desc = "[J]ava: Test [R]eport" })
      vim.keymap.set("n", "<leader>jd", ":JavaTestDebugCurrentMethod<CR>", { desc = "[J]ava: [D]ebug Test Method" })
      vim.keymap.set("n", "<leader>jD", ":JavaTestDebugCurrentClass<CR>", { desc = "[J]ava: [D]ebug Test Class" })
      vim.keymap.set("n", "<leader>ja", ":JavaRunnerRunMain<CR>", { desc = "[J]ava: Run [A]pplication" })
      vim.keymap.set("n", "<leader>js", ":JavaRunnerStopMain<CR>", { desc = "[J]ava: [S]top Application" })
      vim.keymap.set("n", "<leader>jl", ":JavaRunnerToggleLogs<CR>", { desc = "[J]ava: Toggle [L]ogs" })
      vim.keymap.set("n", "<leader>jv", ":JavaRefactorExtractVariable<CR>", { desc = "[J]ava: Extract [V]ariable" })
      vim.keymap.set("v", "<leader>jv", ":JavaRefactorExtractVariable<CR>", { desc = "[J]ava: Extract [V]ariable" })
      vim.keymap.set("n", "<leader>jc", ":JavaRefactorExtractConstant<CR>", { desc = "[J]ava: Extract [C]onstant" })
      vim.keymap.set("v", "<leader>jm", ":JavaRefactorExtractMethod<CR>", { desc = "[J]ava: Extract [M]ethod" })
      vim.keymap.set("n", "<leader>jR", ":JavaSettingsChangeRuntime<CR>", { desc = "[J]ava: Change [R]untime" })
      vim.keymap.set("n", "<leader>jb", ":JavaBuildBuildWorkspace<CR>", { desc = "[J]ava: [B]uild Workspace" })
      vim.keymap.set("n", "<leader>jC", ":JavaBuildCleanWorkspace<CR>", { desc = "[J]ava: [C]lean Workspace" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = false,  -- Handled by nvim-java
      },
    },
  },
}
