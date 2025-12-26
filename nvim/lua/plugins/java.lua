return {
  {
    'nvim-java/nvim-java',
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
