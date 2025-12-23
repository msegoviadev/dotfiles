return {
  "lewis6991/gitsigns.nvim",
  config = function()
    require("gitsigns").setup({
      -- Configure signs to show in the gutter for different change types
      signs = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
        untracked    = { text = "┆" },
      },
      -- Configure signs for staged changes (shows different indicators when changes are staged)
      signs_staged = {
        add          = { text = "┃" },
        change       = { text = "┃" },
        delete       = { text = "_" },
        topdelete    = { text = "‾" },
        changedelete = { text = "~" },
      },
      -- Enable staged signs to differentiate between staged and unstaged changes
      signs_staged_enable = true,
      -- Show signs in the sign column
      signcolumn = true,
      -- Disable number column highlighting
      numhl = false,
      -- Disable line highlighting
      linehl = false,
      -- Disable word-level diff highlighting
      word_diff = false,
      -- Watch the git directory for changes
      watch_gitdir = {
        follow_files = true
      },
      -- Automatically attach to git-tracked files
      auto_attach = true,
      -- Do not attach to untracked files
      attach_to_untracked = false,
      -- Disable current line blame virtual text
      current_line_blame = false,
      -- Enable gitsigns visual indicators
      signcolumn = true,
      numhl = false,
      linehl = false,
      -- Sign priority in the sign column
      sign_priority = 6,
      -- Debounce time for updates in milliseconds
      update_debounce = 100,
      -- Use default status formatter (integrates with lualine automatically)
      status_formatter = nil,
      -- Disable gitsigns for files longer than 40000 lines
      max_file_length = 40000,
      -- Preview window configuration
      preview_config = {
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1
      },
      -- Keymaps for viewing and managing hunks
      on_attach = function(bufnr)
        local gitsigns = require("gitsigns")

        -- Preview hunk under cursor in popup window
        vim.keymap.set("n", "<leader>hp", gitsigns.preview_hunk, { buffer = bufnr, desc = "[H]unk [P]review" })

        -- Reset (revert) hunk under cursor to match git index
        vim.keymap.set("n", "<leader>hr", gitsigns.reset_hunk, { buffer = bufnr, desc = "[H]unk [R]eset" })

        -- Navigate to next hunk
        vim.keymap.set("n", "<leader>hn", gitsigns.next_hunk, { buffer = bufnr, desc = "[H]unk [N]ext" })

        -- Navigate to previous hunk
        vim.keymap.set("n", "<leader>hN", gitsigns.prev_hunk, { buffer = bufnr, desc = "[H]unk [P]revious" })
      end,
    })
  end,
}
