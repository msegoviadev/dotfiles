return {
  "nvim-tree/nvim-tree.lua",
  init = function()
    -- Auto-open nvim-tree when starting nvim with a directory or no args
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function(data)
        local is_dir = vim.fn.isdirectory(data.file) == 1
        local no_args = data.file == "" or data.file == vim.fn.getcwd()
        if is_dir or no_args then
          require("nvim-tree.api").tree.open()
        end
      end,
    })
  end,
  config = function()
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })

    local icons = require("config.icons")

    -- Resolve a highlight group's foreground so tree colors follow whatever
    -- colorscheme the omarchy theme selected instead of a fixed palette
    local function hl_fg(name)
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
      return ok and hl.fg and string.format("#%06x", hl.fg) or nil
    end

    local function set_nvim_tree_highlights()
      -- Git status colors sourced from the theme's diagnostic palette
      vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { fg = hl_fg("DiagnosticWarn") })    -- modified files
      vim.api.nvim_set_hl(0, "NvimTreeGitNew", { fg = hl_fg("DiagnosticOk") })        -- new files
      vim.api.nvim_set_hl(0, "NvimTreeGitDeleted", { fg = hl_fg("DiagnosticError") }) -- deleted files
      vim.api.nvim_set_hl(0, "NvimTreeGitRenamed", { fg = hl_fg("DiagnosticHint") })  -- renamed files
      vim.api.nvim_set_hl(0, "NvimTreeGitStaged", { fg = hl_fg("DiagnosticInfo") })   -- staged files
      vim.api.nvim_set_hl(0, "NvimTreeGitMerge", { fg = hl_fg("Special") })           -- merge conflicts
      vim.api.nvim_set_hl(0, "NvimTreeGitIgnored", { fg = hl_fg("Comment") })         -- ignored files

      -- Make folders match the theme's plain text color
      vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = hl_fg("Normal"), bg = "NONE" })
      vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = hl_fg("Normal"), bg = "NONE" })
      vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = hl_fg("Normal"), bg = "NONE" })
      vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = hl_fg("Normal"), bg = "NONE" })
    end

    -- Apply highlights now and re-apply whenever the colorscheme changes,
    -- so they are not overwritten by the colorscheme.
    set_nvim_tree_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = set_nvim_tree_highlights,
    })

    require("nvim-tree").setup({
      filesystem_watchers = {
        enable = true,
        ignore_dirs = {
          "node_modules", ".next", ".nuxt", "dist", "build", ".turbo",
          "__pycache__", ".venv", "venv", ".mypy_cache", ".pytest_cache",
          "target", ".gradle",
          "vendor",
          ".bundle",
          ".terraform",
          ".git",
        },
      },
      hijack_netrw = true,
      auto_reload_on_write = false,
      sync_root_with_cwd = true,
      git = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
      },
      filters = {
        git_ignored = false,
      },
      view = {
        width = 40
      },
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")

        -- Default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- Custom mappings for vim-like navigation
        vim.keymap.set("n", "l", api.node.open.edit,
          { desc = "Open file/directory", buffer = bufnr, noremap = true, silent = true, nowait = true })
        vim.keymap.set("n", "h", api.node.navigate.parent_close,
          { desc = "Close directory", buffer = bufnr, noremap = true, silent = true, nowait = true })
      end,
      renderer = {
        add_trailing = false,
        group_empty = false,
        highlight_git = "all",
        full_name = false,
        highlight_opened_files = "none",
        root_folder_label = ":t",
        indent_width = 2,
        indent_markers = {
          enable = false,
          inline_arrows = true,
          icons = {
            corner = "└",
            edge = "│",
            item = "│",
            none = " ",
          },
        },
        icons = {
          git_placement = "before",
          padding = " ",
          symlink_arrow = " ➛ ",
          glyphs = {
            default = icons.ui.Text,
            symlink = icons.ui.FileSymlink,
            bookmark = icons.ui.BookMark,
            folder = {
              arrow_closed = icons.ui.ChevronRight,
              arrow_open = icons.ui.ChevronShortDown,
              default = icons.ui.Folder,
              open = icons.ui.FolderOpen,
              empty = icons.ui.EmptyFolder,
              empty_open = icons.ui.EmptyFolderOpen,
              symlink = icons.ui.FolderSymlink,
              symlink_open = icons.ui.FolderOpen,
            },
            git = {
              unstaged = "✚", -- Modified files
              staged = "✓", -- Staged files
              unmerged = "⚡", -- Merge conflicts
              renamed = "➜", -- Renamed files
              untracked = "★", -- New files
              deleted = "✖", -- Deleted files
              ignored = "◌", -- Ignored files
            },
          },
        },
        special_files = {},
        symlink_destination = true,
      },
      update_focused_file = {
        enable = true,
        debounce_delay = 15,
        update_root = false,
        ignore_list = {},
      },

      diagnostics = {
        enable = false,
      },
    })

    -- New files do not appear in the tree until it reloads, and
    -- auto_reload_on_write has no effect while filesystem watchers are enabled.
    -- On write, refresh the tree and reveal the file without stealing focus.
    vim.api.nvim_create_autocmd("BufWritePost", {
      callback = function(ev)
        local ok, api = pcall(require, "nvim-tree.api")
        if not ok or not api.tree.is_visible() then
          return
        end
        api.tree.reload()
        api.tree.find_file({ buf = ev.buf, open = false, update_root = false, focus = false })
      end,
    })
  end,
}
