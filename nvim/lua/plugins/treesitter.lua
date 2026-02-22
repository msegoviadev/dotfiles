return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "windwp/nvim-ts-autotag",
    "JoosepAlviste/nvim-ts-context-commentstring",
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  build = ':TSUpdate',
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = { "vim", "vimdoc", "lua", "java", "javascript", "typescript", "html", "css", "json", "tsx", "markdown", "markdown_inline", "gitignore", "python" },
      highlight = { enable = true },
      autotag = {
        enable = true
      },
    })

    -- nvim-treesitter-textobjects v2 requires manual keymap wiring;
    -- the old configs-based setup API no longer exists in treesitter v1
    local move = require("nvim-treesitter-textobjects.move")
    local select = require("nvim-treesitter-textobjects.select")

    -- look ahead/behind so textobjects work even when cursor is between methods/classes
    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true, lookbehind = true },
    })

    -- m / M: jump between methods
    vim.keymap.set("n", "m", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "Next [M]ethod" })
    vim.keymap.set("n", "M", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "Previous [M]ethod" })

    -- am / im: select around/inside a method (works with d, y, c, v, =)
    vim.keymap.set({ "x", "o" }, "am", function() select.select_textobject("@function.outer", "textobjects") end, { desc = "[A]round [M]ethod" })
    vim.keymap.set({ "x", "o" }, "im", function() select.select_textobject("@function.inner", "textobjects") end, { desc = "[I]nner [M]ethod" })

    -- ac / ic: select around/inside a class
    vim.keymap.set({ "x", "o" }, "ac", function() select.select_textobject("@class.outer", "textobjects") end, { desc = "[A]round [C]lass" })
    vim.keymap.set({ "x", "o" }, "ic", function() select.select_textobject("@class.inner", "textobjects") end, { desc = "[I]nner [C]lass" })

    -- aa / ia: select around/inside an argument/parameter
    vim.keymap.set({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer", "textobjects") end, { desc = "[A]round [A]rgument" })
    vim.keymap.set({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner", "textobjects") end, { desc = "[I]nner [A]rgument" })

    -- Configure ts-context-commentstring for native Neovim commenting
    require('ts_context_commentstring').setup({
      enable_autocmd = false,
    })

    -- Integrate with native commenting
    vim.g.skip_ts_context_commentstring_module = true
  end
}
