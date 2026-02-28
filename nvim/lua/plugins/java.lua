return {
  {
    'nvim-java/nvim-java',
    ft = { 'java' },
    dependencies = {
      'MunifTanjim/nui.nvim',
      {
        'JavaHello/spring-boot.nvim',
        commit = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
      },
    },
    config = function()
      -- Configure nvim-java with optimized settings
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
          enable = false, -- Disabled: user doesn't need debugging
        },

        spring_boot_tools = {
          enable = true,
        },
      })

      -- Track import progress for notifications
      local import_in_progress = false

      -- LSP Progress handler for Maven import notifications
      vim.lsp.handlers['$/progress'] = function(_, result, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if not client or client.name ~= 'jdtls' then
          return
        end

        local value = result.value
        if not value then
          return
        end

        if value.kind == 'begin' and value.title then
          -- Check if this is a Maven import operation
          if value.title:match('Importing') or value.title:match('Building') then
            import_in_progress = true
            vim.notify('📦 ' .. value.title, vim.log.levels.INFO)
          end
        elseif value.kind == 'end' and import_in_progress then
          import_in_progress = false
          vim.notify('✅ Import complete', vim.log.levels.INFO)
          -- Auto-dismiss after 3 seconds
          vim.defer_fn(function()
            vim.notify('') -- Clear notification
          end, 3000)
        end
      end

      -- Configure JDTLS with Maven auto-import settings
      vim.lsp.config('jdtls', {
        settings = {
          java = {
            configuration = {
              runtimes = {
                {
                  name = 'JavaSE-1.8',
                  path = vim.fn.expand('~/.sdkman/candidates/java/8.0.462-amzn'),
                  default = true,
                },
                {
                  name = 'JavaSE-21',
                  path = vim.fn.expand('~/.sdkman/candidates/java/21.0.9-amzn'),
                },
              },
            },
            import = {
              maven = {
                enabled = true,
              },
              gradle = {
                enabled = true,
              },
            },
            project = {
              importOnFirstTimeStartup = 'automatic',
              importHint = true,
            },
            maven = {
              downloadSources = true,
              updateSnapshots = true,
            },
            -- Improve performance for large projects
            maxConcurrentBuilds = 2,
          },
        },
      })

      -- Enable JDTLS
      vim.lsp.enable('jdtls')

      -- Helper function to get JDTLS status
      local function get_jdtls_status()
        local clients = vim.lsp.get_clients({ name = 'jdtls' })
        if #clients == 0 then
          return 'JDTLS: Not running'
        end

        local client = clients[1]
        local status = 'JDTLS: Running'

        if import_in_progress then
          status = status .. ' (importing...)'
        else
          status = status .. ' (ready)'
        end

        -- Show workspace info
        if client.config and client.config.root_dir then
          status = status .. ' | Project: ' .. vim.fn.fnamemodify(client.config.root_dir, ':t')
        end

        return status
      end

      -- Force reindex current project
      local function force_reindex()
        vim.notify('🔄 Force reindexing project...', vim.log.levels.INFO)
        vim.cmd('JavaBuildBuildWorkspace')
      end

      -- Clear JDTLS workspace and restart
      local function clear_workspace_and_restart()
        local workspace_path = vim.fn.expand('~/.cache/jdtls/')
        vim.notify('🧹 Clearing JDTLS workspace...', vim.log.levels.WARN)

        -- Stop JDTLS
        local clients = vim.lsp.get_clients({ name = 'jdtls' })
        for _, client in ipairs(clients) do
          vim.lsp.stop_client(client.id, true)
        end

        -- Clear workspace and restart in background
        vim.defer_fn(function()
          vim.fn.system('rm -rf ' .. workspace_path .. '/*')
          vim.notify('✅ Workspace cleared. Restarting JDTLS...', vim.log.levels.INFO)
          -- Re-enable JDTLS with fresh workspace
          vim.lsp.enable('jdtls')
        end, 500)
      end

      -- Java keymaps (only loaded when Java files are opened)
      -- Test keymaps (kept)
      vim.keymap.set('n', '<leader>jt', function()
        require('java').test.run_current_method()
      end, { desc = '[J]ava: [T]est Method' })

      vim.keymap.set('n', '<leader>jT', function()
        require('java').test.run_current_class()
      end, { desc = '[J]ava: [T]est Class' })

      vim.keymap.set('n', '<leader>jr', ':JavaTestViewLastReport<CR>', { desc = '[J]ava: Test [R]eport' })

      -- Utility keymaps
      vim.keymap.set('n', '<leader>jR', force_reindex, { desc = '[J]ava: Force [R]eindex' })
      vim.keymap.set('n', '<leader>j?', function()
        vim.notify(get_jdtls_status(), vim.log.levels.INFO)
      end, { desc = '[J]ava: Show [?] Status' })
      vim.keymap.set('n', '<leader>jX', clear_workspace_and_restart, { desc = '[J]ava: Clear Workspace and Restart' })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        jdtls = false, -- Handled by nvim-java
      },
    },
  },
}
