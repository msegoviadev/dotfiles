return {
  "MagicDuck/grug-far.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local icons = require("config.icons")
    
    require("grug-far").setup({
      -- Engine configuration
      startInInsertMode = true,
      debounceMs = 500,
      minSearchChars = 2,
      wrap = true,
      transient = false,
      
      -- Static title
      windowCreationCommand = "vsplit",
      staticTitle = "Find and Replace",
      
      -- Icons from your existing config
      icons = {
        enabled = true,
        actionEntryBullet = icons.ui.ChevronRight,
        searchInput = icons.ui.Search,
        filesFilterInput = icons.ui.Files,
        pathsInput = icons.kind.Folder,
        resultsSeparatorLineChar = icons.ui.LineMiddle,
      },
      
      -- History
      history = {
        maxHistorySize = 100,
        autoSave = {
          enabled = true,
          onBufLeave = true,
        },
      },
    })
    
    local grug = require("grug-far")
    
    -- Search and replace in ALL files (project-wide)
    vim.keymap.set("n", "<leader>sra", function()
      grug.open({ prefills = { paths = vim.fn.getcwd() } })
    end, { desc = "[S]earch and [R]eplace in [A]ll files" })
    
    -- Search and replace in CURRENT file only
    vim.keymap.set("n", "<leader>sr", function()
      grug.open({ prefills = { paths = vim.fn.expand("%") } })
    end, { desc = "[S]earch and [R]eplace in current file" })
    
    -- Visual mode support (pre-fills search with selection)
    vim.keymap.set("v", "<leader>sr", function()
      grug.with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
    end, { desc = "[S]earch and [R]eplace selection in current file" })
    
    vim.keymap.set("v", "<leader>sra", function()
      grug.with_visual_selection({ prefills = { paths = vim.fn.getcwd() } })
    end, { desc = "[S]earch and [R]eplace selection in [A]ll files" })
    
    -- Buffer-local customizations
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("grug-far-custom", { clear = true }),
      pattern = { "grug-far" },
      callback = function()
        -- Toggle --fixed-strings flag (literal search, no regex)
        vim.keymap.set("n", "<localleader>w", function()
          local state = unpack(require("grug-far").get_instance(0):toggle_flags({ "--fixed-strings" }))
          vim.notify("grug-far: literal search (--fixed-strings) " .. (state and "ON" or "OFF"))
        end, { buffer = true, desc = "Toggle literal search" })
        
        -- Toggle --ignore-case flag
        vim.keymap.set("n", "<localleader>i", function()
          local state = unpack(require("grug-far").get_instance(0):toggle_flags({ "--ignore-case" }))
          vim.notify("grug-far: ignore case " .. (state and "ON" or "OFF"))
        end, { buffer = true, desc = "Toggle ignore case" })
      end,
    })
  end,
}
