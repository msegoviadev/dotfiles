return {
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    cmd = { "Telescope" },
    keys = {
      { "<leader>fp", desc = "[F]ind [P]rojects" },
      { "<leader>ff", desc = "[F]ind [F]iles" },
      { "<leader>fg", desc = "[F]ind by [G]rep", mode = { "n", "v" } },
      { "<leader>fb", desc = "[F]ind Existing [B]uffers" },
      { "<leader>fd", desc = "[F]ind [D]iff" },
    },
    dependencies = {
      {
        -- general purpose plugin used to build user interfaces in neovim plugins
        'nvim-lua/plenary.nvim'
      },
      {
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make", lazy = true },
      },
    },
    config = function()
      -- get access to telescopes built in functions
      local builtin = require('telescope.builtin')

      -- Function to find and switch to projects in ~/workspace/
      local function find_projects()
        local pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')

        -- Get list of directories using fd
        local workspace = vim.fn.expand("~/workspace/")
        local fd_command = { 'fd', '--type', 'd', '--max-depth', '2', '--exclude', 'node_modules', '--exclude', '.git',
          '--exclude', '.venv', '--exclude', 'target', '--exclude', 'dist', '--exclude', 'build', '.', workspace }

        pickers.new({}, {
          prompt_title = "󰉋 Find Projects",
          finder = finders.new_oneshot_job(fd_command, {}),
          sorter = conf.generic_sorter({}),
          previewer = false,
          layout_config = { width = 0.5, height = 0.6 },
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)

              -- Get the full path from selection
              local project_path = selection[1]

              -- Check if nvim-tree is currently open
              local nvim_tree_was_open = false
              local ok, nvim_tree_api = pcall(require, 'nvim-tree.api')
              if ok then
                nvim_tree_was_open = nvim_tree_api.tree.is_visible()
              end

              -- Close all buffers with confirmation for unsaved changes
              local close_success, close_error = pcall(vim.cmd, 'confirm %bdelete')
              if not close_success then
                -- User cancelled or there was an error
                print("❌ Project switch cancelled")
                return
              end

              -- Change to the selected directory
              vim.cmd('cd ' .. vim.fn.fnameescape(project_path))

              -- Update nvim-tree to show the new project root
              if ok and nvim_tree_was_open then
                vim.schedule(function()
                  nvim_tree_api.tree.open()
                  nvim_tree_api.tree.change_root(project_path)
                end)
              end

              print("📁 Switched to: " .. vim.fn.fnamemodify(project_path, ':t'))
            end)
            return true
          end,
        }):find()
      end

      -- Function to get visual selection and search with live_grep
      local function grep_visual_selection()
        -- Yank the visual selection to the v register
        vim.cmd('noautocmd normal! "vy')

        -- Get the yanked text and remove newlines (join without spaces)
        local search_term = vim.fn.getreg('v'):gsub('\n', '')

        -- Call live_grep with the selected text as default
        builtin.live_grep({ default_text = search_term })
      end

      -- Custom git diff picker with clear status labels and aligned stats
      -- Supports both single repo (cwd is the project root) and multi-repo
      -- (cwd is a parent with git repos underneath, up to depth 2)
      local function find_git_diff()
        local tele_pickers = require('telescope.pickers')
        local finders = require('telescope.finders')
        local previewers = require('telescope.previewers')
        local conf = require('telescope.config').values
        local actions = require('telescope.actions')
        local action_state = require('telescope.actions.state')
        local entry_display = require('telescope.pickers.entry_display')

        local cwd = vim.fn.getcwd()

        -- Discover git repos: try cwd first, then scan for nested repos
        local repos = {}
        local toplevel = vim.fn.systemlist({ 'git', 'rev-parse', '--show-toplevel' })
        if vim.v.shell_error == 0 and #toplevel > 0 then
          repos = { toplevel[1] }
        else
          local git_dirs = vim.fn.systemlist({
            'fd', '-H', '--glob', '.git', '-t', 'd', '--max-depth', '2',
            '--exclude', 'node_modules', '--exclude', '.venv',
            '--exclude', 'target', '--exclude', 'dist', '--exclude', 'build',
            cwd,
          })
          if vim.v.shell_error == 0 then
            for _, git_dir in ipairs(git_dirs) do
              if git_dir ~= "" then
                local repo_root = git_dir:gsub("/.git/?$", "")
                table.insert(repos, repo_root)
              end
            end
          end
        end

        if #repos == 0 then
          vim.notify("No git repositories found", vim.log.levels.WARN)
          return
        end

        local multi_repo = #repos > 1

        local status_labels = {
          M = "[modified]",
          A = "[added]",
          D = "[deleted]",
          R = "[renamed]",
          C = "[copied]",
          T = "[typechange]",
        }
        local status_hl = {
          M = "DiagnosticWarn",
          A = "DiagnosticOk",
          D = "DiagnosticError",
          R = "DiagnosticInfo",
          C = "DiagnosticInfo",
          T = "DiagnosticWarn",
          ["?"] = "DiagnosticOk",
        }

        local changes = {}

        for _, repo_root in ipairs(repos) do
          -- Check if this repo has any commits
          vim.fn.system({ 'git', '-C', repo_root, 'rev-parse', 'HEAD' })
          local diff_ref = vim.v.shell_error == 0 and 'HEAD' or nil

          -- Compute repo display prefix for multi-repo scenario
          local repo_prefix = ""
          if multi_repo then
            local rel = repo_root
            if rel:sub(1, #cwd) == cwd then
              rel = rel:sub(#cwd + 1)
              if rel:sub(1, 1) == "/" then rel = rel:sub(2) end
            end
            repo_prefix = rel .. "/"
          end

          if diff_ref then
            local name_status = vim.fn.systemlist({ 'git', '-C', repo_root, 'diff', diff_ref, '--name-status' })
            local numstat = vim.fn.systemlist({ 'git', '-C', repo_root, 'diff', diff_ref, '--numstat' })

            local stats = {}
            for _, line in ipairs(numstat) do
              local ins, del, path = line:match("^(%d+)%s+(%d+)%s+(.+)$")
              if path then
                stats[path] = { insertions = tonumber(ins) or 0, deletions = tonumber(del) or 0 }
              end
            end

            for _, line in ipairs(name_status) do
              local status, path = line:match("^(%a)%s+(.+)$")
              if not status then
                local s, _, new_path = line:match("^(%a)%d*%s+(.+)%s+(.+)$")
                if s then
                  status = s
                  path = new_path
                end
              end
              if status and path then
                local file_stats = stats[path] or { insertions = 0, deletions = 0 }
                table.insert(changes, {
                  path = path,
                  display_path = repo_prefix .. path,
                  repo_root = repo_root,
                  status = status,
                  label = status_labels[status] or "[" .. status .. "]",
                  hl = status_hl[status] or "Normal",
                  insertions = file_stats.insertions,
                  deletions = file_stats.deletions,
                })
              end
            end
          end

          -- Get untracked files for this repo
          local untracked = vim.fn.systemlist({
            'git', '-C', repo_root, 'ls-files', '--others', '--exclude-standard',
          })
          for _, path in ipairs(untracked) do
            if path ~= "" then
              table.insert(changes, {
                path = path,
                display_path = repo_prefix .. path,
                repo_root = repo_root,
                status = "?",
                label = "[untracked]",
                hl = status_hl["?"],
                insertions = 0,
                deletions = 0,
              })
            end
          end
        end

        if #changes == 0 then
          vim.notify("No git changes found", vim.log.levels.INFO)
          return
        end

        -- Sort: modified first, then added, then untracked, then deleted
        local status_order = { M = 1, A = 2, ["?"] = 3, D = 4, R = 5, C = 6, T = 7 }
        table.sort(changes, function(a, b)
          local oa = status_order[a.status] or 9
          local ob = status_order[b.status] or 9
          if oa ~= ob then return oa < ob end
          return a.display_path < b.display_path
        end)

        local function format_stat(insertions, deletions)
          local parts = {}
          if insertions > 0 then table.insert(parts, "+" .. insertions) end
          if deletions > 0 then table.insert(parts, "-" .. deletions) end
          return table.concat(parts, " ")
        end

        -- Compute max path width for alignment
        local max_path_len = 0
        for _, change in ipairs(changes) do
          if #change.display_path > max_path_len then
            max_path_len = #change.display_path
          end
          change._stat = format_stat(change.insertions, change.deletions)
        end

        local displayer = entry_display.create({
          separator = " ",
          items = {
            { width = 14 },              -- status label
            { width = max_path_len + 4 }, -- file path + margin
            { width = 12 },              -- +N  -N stats
          },
        })

        local function make_display(entry)
          local change = entry.value
          return displayer({
            { change.label, change.hl },
            { change.display_path },
            { change._stat, "Comment" },
          })
        end

        local summary = #changes .. " files changed"

        local diff_previewer = previewers.new_buffer_previewer({
          title = "Diff Preview",
          define_preview = function(self, entry)
            local change = entry.value
            local lines

            if change.status == "?" then
              local full_path = change.repo_root .. "/" .. change.path

              -- Skip binary files
              local is_binary = vim.fn.systemlist({ 'file', '--mime', full_path })
              if is_binary[1] and is_binary[1]:match("charset=binary") then
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "(binary file)" })
                return
              end

              local ok, content = pcall(vim.fn.readfile, full_path)
              if ok then
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
                local ft = vim.filetype.match({ filename = change.path })
                if ft then
                  vim.bo[self.state.bufnr].filetype = ft
                end
              else
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Could not read file" })
              end
              return
            end

            lines = vim.fn.systemlist({
              'git', '-C', change.repo_root, 'diff', 'HEAD', '--', change.path,
            })

            if #lines == 0 then
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "No differences" })
              return
            end

            -- Check if git reports a binary diff
            if #lines > 0 and lines[1]:match("^Binary files") then
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "(binary file)" })
              return
            end

            -- Strip git diff headers for cleaner output
            local clean_lines = {}
            local past_header = false
            for _, line in ipairs(lines) do
              if past_header then
                table.insert(clean_lines, line)
              elseif line:match("^@@") then
                past_header = true
                table.insert(clean_lines, line)
              end
            end

            if #clean_lines == 0 then
              clean_lines = lines
            end

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, clean_lines)
            vim.bo[self.state.bufnr].filetype = "diff"
          end,
        })

        -- Open a side-by-side diff view for a git change
        -- on_close is called when the user exits the diff (to reopen the picker)
        local function open_git_diff(change, on_close)
          local filename = change.path
          local full_path = change.repo_root .. "/" .. change.path
          local ft = vim.filetype.match({ filename = filename }) or ""

          -- Get old content from git HEAD
          local old_content = nil
          if change.status ~= "?" then
            local result = vim.fn.systemlist({
              'git', '-C', change.repo_root, 'show', 'HEAD:' .. change.path,
            })
            if vim.v.shell_error == 0 then
              old_content = result
            end
          end

          -- Create the left (old) buffer
          local old_buf = vim.api.nvim_create_buf(false, true)
          pcall(vim.api.nvim_buf_set_name, old_buf, "git-diff://HEAD/" .. filename)

          if old_content then
            vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_content)
          else
            vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, { "" })
          end

          vim.bo[old_buf].buftype = "nofile"
          vim.bo[old_buf].bufhidden = "wipe"
          vim.bo[old_buf].modifiable = false
          vim.bo[old_buf].swapfile = false
          if ft ~= "" then
            vim.bo[old_buf].filetype = ft
          end

          if change.status == "D" then
            -- Deleted file: old on left, empty on right
            local new_buf = vim.api.nvim_create_buf(false, true)
            pcall(vim.api.nvim_buf_set_name, new_buf, "git-diff://current/" .. filename .. " (deleted)")
            vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, { "" })
            vim.bo[new_buf].buftype = "nofile"
            vim.bo[new_buf].bufhidden = "wipe"
            vim.bo[new_buf].modifiable = false
            vim.bo[new_buf].swapfile = false
            if ft ~= "" then vim.bo[new_buf].filetype = ft end

            vim.cmd("tabnew")
            vim.api.nvim_set_current_buf(old_buf)
            vim.cmd("diffthis")
            vim.cmd("vsplit")
            vim.api.nvim_set_current_buf(new_buf)
            vim.cmd("diffthis")
          else
            -- Normal case: old on left, real file on right (editable)
            vim.cmd("tabnew")
            vim.api.nvim_set_current_buf(old_buf)
            vim.cmd("diffthis")
            vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
            vim.cmd("diffthis")
          end

          vim.opt_local.diffopt:append("algorithm:patience")
          if vim.fn.has("nvim-0.9") == 1 then
            vim.opt_local.diffopt:append("linematch:60")
          end

          -- Map q and Esc on both windows to close diff and return to picker
          local diff_tab = vim.api.nvim_get_current_tabpage()
          local diff_wins = vim.api.nvim_tabpage_list_wins(diff_tab)

          local function close_diff()
            if vim.api.nvim_tabpage_is_valid(diff_tab)
              and vim.api.nvim_get_current_tabpage() == diff_tab then
              vim.cmd("tabclose")
            end
            if on_close then
              vim.schedule(on_close)
            end
          end

          for _, win in ipairs(diff_wins) do
            local buf = vim.api.nvim_win_get_buf(win)
            vim.keymap.set("n", "q", close_diff, { buffer = buf, desc = "Close git diff" })
            vim.keymap.set("n", "<Esc>", close_diff, { buffer = buf, desc = "Close git diff" })
          end
        end

        tele_pickers.new({
          layout_strategy = "vertical",
          layout_config = {
            height = 0.95,
            width = 0.8,
            preview_height = 0.6,
          },
        }, {
          prompt_title = "Find Diff",
          results_title = summary,
          finder = finders.new_table({
            results = changes,
            entry_maker = function(change)
              return {
                value = change,
                display = make_display,
                ordinal = change.status .. " " .. change.display_path,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          previewer = diff_previewer,
          attach_mappings = function(prompt_bufnr, map)
            -- Enter: open side-by-side diff, return to picker on close
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              if not entry then return end
              actions.close(prompt_bufnr)
              local change = entry.value
              open_git_diff(change, function()
                find_git_diff()
              end)
            end)

            -- Ctrl+o: open the file directly
            local function open_file()
              local entry = action_state.get_selected_entry()
              if not entry then return end
              local change = entry.value
              if change.status == "D" then
                vim.notify("File was deleted", vim.log.levels.WARN)
                return
              end
              actions.close(prompt_bufnr)
              vim.cmd("edit " .. vim.fn.fnameescape(change.repo_root .. "/" .. change.path))
            end

            map("i", "<C-o>", open_file)
            map("n", "<C-o>", open_file)

            return true
          end,
        }):find()
      end

      -- set a vim motion to <Space> + f + p to search for projects
      vim.keymap.set('n', '<leader>fp', find_projects, { desc = '[F]ind [P]rojects' })
      -- set a vim motion to <Space> + f + f to search for files by their names
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "[F]ind [F]iles" })
      -- set a vim motion to <Space> + f + g to search for files based on the text inside of them
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "[F]ind by [G]rep" })
      vim.keymap.set('v', '<leader>fg', grep_visual_selection, { desc = "[F]ind by [G]rep (selection)" })
      -- set a vim motion to <Space> + f + b to search Open Buffers
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind Existing [B]uffers' })
      -- set a vim motion to <Space> + f + d to search for git diff files
      vim.keymap.set('n', '<leader>fd', find_git_diff, { desc = '[F]ind [D]iff' })
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
    event = "VeryLazy",
    config = function()
      -- get access to telescopes navigation functions
      local actions = require("telescope.actions")
      local icons = require("config.icons")

      require("telescope").setup({
        -- use ui-select dropdown as our ui
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          },
          fzf = {
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
          },
        },
        defaults = {
          prompt_prefix = icons.ui.Telescope .. " ",
          selection_caret = icons.ui.Forward .. " ",
          entry_prefix = "   ",
          initial_mode = "insert",
          selection_strategy = "reset",
          path_display = { "absolute" },
          color_devicons = true,
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!.git/",
          },
        },
        -- set keymappings to navigate through items in the telescope io
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,

            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
          },
          n = {
            ["<esc>"] = actions.close,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["q"] = actions.close,
          },
        },
        pickers = {
          live_grep = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
          },

          grep_string = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
          },

          find_files = {
            theme = "dropdown",
            previewer = false,
            find_command = { "fd", "--type", "f", "--hidden", "--exclude", ".git" },
            layout_config = {
              height = 0.6,
              width = 0.8,
            },
          },

          buffers = {
            theme = "dropdown",
            previewer = false,
            initial_mode = "normal",
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer,
              },
              n = {
                ["dd"] = actions.delete_buffer,
              },
            },
          },

          planets = {
            show_pluto = true,
            show_moon = true,
          },

          colorscheme = {
            enable_preview = true,
          },

          lsp_references = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
            initial_mode = "normal",
          },

          lsp_definitions = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
            initial_mode = "normal",
          },

          lsp_declarations = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
            initial_mode = "normal",
          },

          lsp_implementations = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
            initial_mode = "normal",
          },


        },
      })
      -- load the ui-select extension
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("fzf")
    end
  }
}
