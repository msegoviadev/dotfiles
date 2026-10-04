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
      -- jdtls asks the client to run commands after a completion, for example
      -- editor.action.triggerParameterHints. Neovim 0.12 requires a server
      -- request to get a result or an error, but the upstream handler may return
      -- nil, which raises "either a result or an error must be sent". Answer
      -- with vim.NIL so the request is always satisfied.
      vim.lsp.handlers['workspace/executeClientCommand'] = function(_, params, ctx)
        local client = vim.lsp.get_client_by_id(ctx.client_id) or {}
        local fn = (client.commands or {})[params.command] or vim.lsp.commands[params.command]
        if not fn then
          return vim.NIL
        end
        local ok, result = pcall(fn, params.arguments, ctx)
        if not ok then
          return vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InternalError, result)
        end
        return result == nil and vim.NIL or result
      end

      -- ~/.cache/nvim has com.apple.provenance (macOS Sequoia) which makes it
      -- non-writable for child processes like jdtls. Redirect to stdpath('data').
      local lsp_utils = require('java-core.utils.lsp')
      local jdtls_data_root = vim.fn.stdpath('data') .. '/jdtls'
      lsp_utils.get_jdtls_cache_root_path = function()
        return jdtls_data_root
      end

      -- Local-only workaround for an m2e/JDT quirk: quarkus-maven-plugin's
      -- generate-code-tests goal duplicates generate-code's output into a second
      -- source folder, which JDT flags as "already defined". Tells m2e to skip
      -- that goal during IDE builds only; doesn't touch the shared repo's pom.xml.
      -- Verified 2026-07-17: 446 "already defined" errors -> 0 after <leader>jX.
      local function write_m2e_lifecycle_mapping_override()
        local cache_data_path = lsp_utils.get_jdtls_cache_data_path(vim.fn.getcwd())
        local m2e_dir = cache_data_path .. '/.metadata/.plugins/org.eclipse.m2e.core'
        vim.fn.mkdir(m2e_dir, 'p')
        local xml = table.concat({
          '<?xml version="1.0" encoding="UTF-8"?>',
          '<lifecycleMappingMetadata>',
          '  <pluginExecutions>',
          '    <pluginExecution>',
          '      <pluginExecutionFilter>',
          '        <groupId>io.quarkus.platform</groupId>',
          '        <artifactId>quarkus-maven-plugin</artifactId>',
          '        <versionRange>[0,)</versionRange>',
          '        <goals>',
          '          <goal>generate-code-tests</goal>',
          '        </goals>',
          '      </pluginExecutionFilter>',
          '      <action>',
          '        <ignore/>',
          '      </action>',
          '    </pluginExecution>',
          '  </pluginExecutions>',
          '</lifecycleMappingMetadata>',
        }, '\n')
        vim.fn.writefile(vim.split(xml, '\n'), m2e_dir .. '/lifecycle-mapping-metadata.xml')
      end
      write_m2e_lifecycle_mapping_override()

      -- nvim-java hardcodes jdtls's JVM args (-Xms1G, no -Xmx/GC tuning) with no
      -- config knob to override them, so wrap get_jvm_args instead of forking it.
      -- Tune -Xmx based on available RAM.
      local ok, jdtls_cmd = pcall(require, 'java-core.ls.servers.jdtls.cmd')
      if ok and jdtls_cmd.get_jvm_args then
        local base_get_jvm_args = jdtls_cmd.get_jvm_args
        jdtls_cmd.get_jvm_args = function(config)
          local args = base_get_jvm_args(config)
          args:push('-Xmx6G')
          args:push('-XX:+UseG1GC')
          args:push('-XX:+UseStringDeduplication')
          return args
        end
      else
        vim.notify(
          'jdtls JVM heap patch skipped: nvim-java internals changed, gd/gr may be slow',
          vim.log.levels.WARN
        )
      end

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
            -- jdtls defaults signatureHelp to off, so Ctrl-k shows "No signature
            -- help available" until the client enables it explicitly.
            signatureHelp = {
              enabled = true,
            },
            -- No runtimes block: let jdtls auto-detect the JVM it runs under
            -- (the sdkman "current" java), so nothing is hardcoded to JavaSE-25.
            import = {
              -- Shrink the imported workspace to cut memory pressure and
              -- reference-search space in the multi-module reactor.
              exclusions = {
                '**/target/**',
                '**/.git/**',
                '**/node_modules/**',
              },
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
              -- Disabled: forced network calls on every import stalled jdtls.
              -- Fetch sources on demand; snapshots via <leader>jR when needed.
              downloadSources = false,
              updateSnapshots = false,
            },
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
        local workspace_path = vim.fn.stdpath('data') .. '/jdtls/'
        vim.notify('🧹 Clearing JDTLS workspace...', vim.log.levels.WARN)

        -- Stop JDTLS
        local clients = vim.lsp.get_clients({ name = 'jdtls' })
        for _, client in ipairs(clients) do
          vim.lsp.stop_client(client.id, true)
        end

        -- Clear workspace and restart in background
        vim.defer_fn(function()
          vim.fn.system('rm -rf ' .. workspace_path .. '/*')
          -- Workspace wipe deletes the m2e lifecycle mapping override too - recreate it
          -- before the fresh import runs.
          write_m2e_lifecycle_mapping_override()
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

      -- Derive the Java package from the file's directory under a source root,
      -- so a new file matches its path without typing the package by hand.
      local function java_package_for(bufnr)
        local file = vim.api.nvim_buf_get_name(bufnr)
        for _, marker in ipairs({ '/src/main/java/', '/src/test/java/' }) do
          local i = file:find(marker, 1, true)
          if i then
            local dir = vim.fn.fnamemodify(file:sub(i + #marker), ':h')
            local pkg = dir:gsub('/', '.')
            if pkg ~= '.' and pkg ~= '' then
              return pkg
            end
          end
        end
        return nil
      end

      -- True when the buffer already has a package declaration.
      local function java_has_package(bufnr)
        for _, l in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
          if l:match('^%s*package%s') then
            return true
          end
        end
        return false
      end

      -- Expose the path-derived package as snippet variables, so `pclass` and
      -- friends insert the package header only when the file lacks one.
      local ok_blink, blink_builtin = pcall(require, 'blink.cmp.sources.snippets.default.builtin')
      if ok_blink then
        blink_builtin.lazy.JAVA_PACKAGE = function()
          return java_package_for(vim.api.nvim_get_current_buf()) or ''
        end
        blink_builtin.lazy.JAVA_PACKAGE_HEADER = function()
          local bufnr = vim.api.nvim_get_current_buf()
          if java_has_package(bufnr) then
            return ''
          end
          local pkg = java_package_for(bufnr)
          if not pkg then
            return ''
          end
          return 'package ' .. pkg .. ';\n\n'
        end
      end

      local function put_package(bufnr)
        local pkg = java_package_for(bufnr)
        if not pkg then
          vim.notify('Not under src/main/java or src/test/java', vim.log.levels.WARN)
          return
        end
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        for i, l in ipairs(lines) do
          if l:match('^%s*package%s') then
            lines[i] = 'package ' .. pkg .. ';'
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            vim.notify('Package set to ' .. pkg, vim.log.levels.INFO)
            return
          end
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, { 'package ' .. pkg .. ';', '' })
        vim.notify('Package ' .. pkg .. ' added', vim.log.levels.INFO)
      end

      vim.keymap.set('n', '<leader>jp', function()
        put_package(vim.api.nvim_get_current_buf())
      end, { desc = '[J]ava: Set [P]ackage from path' })

      -- Map a class to its test path (and the reverse) under the source roots.
      local function java_test_counterpart(file)
        if file:find('/src/main/java/', 1, true) then
          return file:gsub('/src/main/java/', '/src/test/java/', 1):gsub('%.java$', 'Test.java')
        end
        if file:find('/src/test/java/', 1, true) then
          return file:gsub('/src/test/java/', '/src/main/java/', 1):gsub('Test%.java$', '.java')
        end
        return nil
      end

      -- Jump to the counterpart test, creating it from a skeleton when missing.
      local function goto_test()
        local bufnr = vim.api.nvim_get_current_buf()
        local from = vim.api.nvim_buf_get_name(bufnr)
        local target = java_test_counterpart(from)
        if not target then
          vim.notify('Not under src/main/java or src/test/java', vim.log.levels.WARN)
          return
        end
        if target == from then
          vim.notify('No test counterpart for ' .. vim.fn.fnamemodify(from, ':t'), vim.log.levels.WARN)
          return
        end

        local exists = vim.uv.fs_stat(target) ~= nil
        if not exists then
          vim.fn.mkdir(vim.fn.fnamemodify(target, ':h'), 'p')
        end
        vim.cmd.edit(vim.fn.fnameescape(target))
        if not exists then
          local pkg = java_package_for(vim.api.nvim_get_current_buf())
          local name = vim.fn.fnamemodify(target, ':t:r')
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {
            'package ' .. (pkg or '') .. ';',
            '',
            'import org.junit.jupiter.api.Test;',
            '',
            'class ' .. name .. ' {',
            '',
            '\t@Test',
            '\tvoid todo() {',
            '\t}',
            '}',
          })
          vim.bo.filetype = 'java'
        end
      end

      vim.keymap.set('n', '<leader>jg', goto_test, { desc = '[J]ava: [G]o to or create test' })

      -- jdtls can miss a Java file that was created after the workspace import.
      -- On the first save, report it as created so completion and diagnostics
      -- start working without a manual reindex.
      local new_java_file = {}
      vim.api.nvim_create_autocmd('BufNewFile', {
        pattern = '*.java',
        callback = function(ev)
          new_java_file[ev.buf] = true
        end,
      })
      vim.api.nvim_create_autocmd('BufWritePost', {
        pattern = '*.java',
        callback = function(ev)
          if not new_java_file[ev.buf] then
            return
          end
          new_java_file[ev.buf] = nil
          local changes = { { uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(ev.buf)), type = 1 } }
          for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf, name = 'jdtls' })) do
            client.notify('workspace/didChangeWatchedFiles', { changes = changes })
          end
        end,
      })
    end,
  },
}
