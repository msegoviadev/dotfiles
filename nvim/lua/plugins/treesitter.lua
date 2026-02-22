return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "windwp/nvim-ts-autotag",
    "JoosepAlviste/nvim-ts-context-commentstring",
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  build = ':TSUpdate',
  config = function()
    local parsers = { "vim", "vimdoc", "lua", "java", "javascript", "typescript", "html", "css", "json", "tsx", "markdown", "markdown_inline", "gitignore", "python", "terraform", "hcl" }

    require("nvim-treesitter").setup({
      highlight = { enable = true },
      autotag = { enable = true },
    })

    -- ensure_installed was removed in nvim-treesitter v1; install missing parsers explicitly
    require("nvim-treesitter.install").install(parsers)

    -- nvim-treesitter-textobjects v2 requires manual keymap wiring;
    -- the old configs-based setup API no longer exists in treesitter v1
    local move = require("nvim-treesitter-textobjects.move")
    local select = require("nvim-treesitter-textobjects.select")

    -- look ahead/behind so textobjects work even when cursor is between methods/classes
    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true, lookbehind = true },
    })

    -- guard to silently skip textobject moves when no treesitter parser is available for the buffer
    local function safe_move(fn, query, group)
      return function()
        local ok, parser = pcall(vim.treesitter.get_parser, 0)
        if not ok or not parser then return end
        fn(query, group)
      end
    end

    -- m / M: jump between methods
    vim.keymap.set("n", "m", safe_move(move.goto_next_start, "@function.outer", "textobjects"), { desc = "Next [M]ethod" })
    vim.keymap.set("n", "M", safe_move(move.goto_previous_start, "@function.outer", "textobjects"), { desc = "Previous [M]ethod" })

    -- am / im: select around/inside a method (works with d, y, c, v, =)
    vim.keymap.set({ "x", "o" }, "am", function() select.select_textobject("@function.outer", "textobjects") end, { desc = "[A]round [M]ethod" })
    vim.keymap.set({ "x", "o" }, "im", function() select.select_textobject("@function.inner", "textobjects") end, { desc = "[I]nner [M]ethod" })

    -- ac / ic: select around/inside a class
    vim.keymap.set({ "x", "o" }, "ac", function() select.select_textobject("@class.outer", "textobjects") end, { desc = "[A]round [C]lass" })
    vim.keymap.set({ "x", "o" }, "ic", function() select.select_textobject("@class.inner", "textobjects") end, { desc = "[I]nner [C]lass" })

    -- aa / ia: select around/inside an argument/parameter
    vim.keymap.set({ "x", "o" }, "aa", function() select.select_textobject("@parameter.outer", "textobjects") end, { desc = "[A]round [A]rgument" })
    vim.keymap.set({ "x", "o" }, "ia", function() select.select_textobject("@parameter.inner", "textobjects") end, { desc = "[I]nner [A]rgument" })

    -- JSON: , / < jump between key-value pairs, scoped per-buffer to avoid
    -- overriding comma and indent in other filetypes
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "json", "jsonc" },
      callback = function()
        local buf = { buffer = 0 }
        vim.keymap.set("n", ",", safe_move(move.goto_next_start, "@pair.outer", "textobjects"), vim.tbl_extend("force", buf, { desc = "Next [P]air" }))
        vim.keymap.set("n", "<", safe_move(move.goto_previous_start, "@pair.outer", "textobjects"), vim.tbl_extend("force", buf, { desc = "Previous [P]air" }))
      end,
    })

    -- Terraform: m/M reuse @block.outer since terraform has no functions;
    -- ab / ib: select around/inside a terraform block (resource, module, variable, data)
    -- these only activate in terraform/hcl files via filetype autocmd to avoid
    -- conflicting with the global m/M bindings
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "terraform", "hcl" },
      callback = function()
        local buf = { buffer = 0 }
        vim.keymap.set("n", "m", safe_move(move.goto_next_start, "@block.outer", "textobjects"), vim.tbl_extend("force", buf, { desc = "Next [B]lock" }))
        vim.keymap.set("n", "M", safe_move(move.goto_previous_start, "@block.outer", "textobjects"), vim.tbl_extend("force", buf, { desc = "Previous [B]lock" }))
        vim.keymap.set({ "x", "o" }, "ab", function() select.select_textobject("@block.outer", "textobjects") end, vim.tbl_extend("force", buf, { desc = "[A]round [B]lock" }))
        vim.keymap.set({ "x", "o" }, "ib", function() select.select_textobject("@block.inner", "textobjects") end, vim.tbl_extend("force", buf, { desc = "[I]nner [B]lock" }))
      end,
    })

    -- Configure ts-context-commentstring for native Neovim commenting
    require('ts_context_commentstring').setup({
      enable_autocmd = false,
    })

    -- Integrate with native commenting
    vim.g.skip_ts_context_commentstring_module = true
  end
}
