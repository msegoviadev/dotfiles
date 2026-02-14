return {
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
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
      vim.keymap.set('n', '<leader>fd', builtin.git_status, { desc = '[F]ind [D]iff' })
    end
  },
  {
    'nvim-telescope/telescope-ui-select.nvim',
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
          -- Enable git status icons in telescope results
          git_icons = {
            added = icons.git.FileUnstaged,
            changed = icons.git.FileUnstaged,
            copied = icons.git.FileStaged,
            deleted = icons.git.FileDeleted,
            renamed = icons.git.FileRenamed,
            unmerged = icons.git.FileUnmerged,
            untracked = icons.git.FileUntracked,
          },
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

          git_status = {
            layout_strategy = "vertical",
            layout_config = {
              height = 0.95,
              width = 0.8,
              preview_height = 0.6,
            },
            -- Configure git status icons to use your custom icons
            git_icons = {
              added = icons.git.FileUnstaged,
              changed = icons.git.FileUnstaged,
              copied = icons.git.FileStaged,
              deleted = icons.git.FileDeleted,
              renamed = icons.git.FileRenamed,
              unmerged = icons.git.FileUnmerged,
              untracked = icons.git.FileUntracked,
            },
          },
        },
      })
      -- load the ui-select extension
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("fzf")
    end
  }
}
