return {
  "nvim-tree/nvim-tree.lua",
  config = function()
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle [E]xplorer" })
        
        vim.keymap.set("n", "<C-h>", ":wincmd h<cr>", { desc = "Move focus to the left window" })
        local icons = require("config.icons")

    -- Set up custom highlights for git status colors (catppuccin-mocha palette)
    vim.api.nvim_set_hl(0, "NvimTreeGitDirty", { fg = "#f9e2af" }) -- Yellow for modified files
    vim.api.nvim_set_hl(0, "NvimTreeGitNew", { fg = "#a6e3a1" }) -- Green for new files
    vim.api.nvim_set_hl(0, "NvimTreeGitDeleted", { fg = "#f38ba8" }) -- Red for deleted files
    vim.api.nvim_set_hl(0, "NvimTreeGitRenamed", { fg = "#fab387" }) -- Peach for renamed files
    vim.api.nvim_set_hl(0, "NvimTreeGitStaged", { fg = "#94e2d5" }) -- Teal for staged files
    vim.api.nvim_set_hl(0, "NvimTreeGitMerge", { fg = "#cba6f7" }) -- Mauve for merge conflicts
    vim.api.nvim_set_hl(0, "NvimTreeGitIgnored", { fg = "#6c7086" }) -- Subtext1 for ignored files
    
    -- Make folders match file color exactly (using catppuccin text color)
    vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#cdd6f4", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = "#cdd6f4", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#cdd6f4", bg = "NONE" })
    vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = "#cdd6f4", bg = "NONE" })

    require("nvim-tree").setup({
      hijack_netrw = true,
      auto_reload_on_write = true,
      sync_root_with_cwd = true,
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
        vim.keymap.set("n", "l", api.node.open.edit, { desc = "Open file/directory", buffer = bufnr, noremap = true, silent = true, nowait = true })
        vim.keymap.set("n", "h", api.node.navigate.parent_close, { desc = "Close directory", buffer = bufnr, noremap = true, silent = true, nowait = true })
      end,
      renderer = {
        add_trailing = false,
        group_empty = false,
        highlight_git = true,
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
        special_files = { },
        symlink_destination = true,
      },
      update_focused_file = {
        enable = true,
        debounce_delay = 15,
        update_root = true,
        ignore_list = {},
      },

      diagnostics = {
        enable = true,
        show_on_dirs = false,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
          min = vim.diagnostic.severity.HINT,
          max = vim.diagnostic.severity.ERROR,
        },
        icons = {
          hint = icons.diagnostics.BoldHint,
          info = icons.diagnostics.BoldInformation,
          warning = icons.diagnostics.BoldWarning,
          error = icons.diagnostics.BoldError,
        },
      },
    })
  end,
}
