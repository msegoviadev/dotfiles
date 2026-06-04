return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen" },
  opts = {
    view = {
      merge_tool = {
        layout = "diff3_mixed",
        disable_diagnostics = true,
      },
    },
    keymaps = {
      disable_defaults = true,
      view = {
        -- Conflict resolution (current hunk)
        { "n", "<leader>co", function() require("diffview.actions").conflict_choose("ours") end,          { desc = "[C]onflict choose [O]urs" } },
        { "n", "<leader>ct", function() require("diffview.actions").conflict_choose("theirs") end,        { desc = "[C]onflict choose [T]heirs" } },
        { "n", "<leader>cx", function() require("diffview.actions").conflict_choose("none") end,          { desc = "[C]onflict [X] delete" } },
        -- Conflict resolution (whole file)
        { "n", "<leader>cO", function() require("diffview.actions").conflict_choose_all("ours") end,      { desc = "[C]onflict all [O]urs" } },
        { "n", "<leader>cT", function() require("diffview.actions").conflict_choose_all("theirs") end,    { desc = "[C]onflict all [T]heirs" } },
        -- Stage resolved file
        { "n", "<leader>cs", function() vim.cmd("silent !git add " .. vim.fn.expand("%:p")) end,          { desc = "[C]onflict [S]tage (mark resolved)" } },
        -- Navigation
        { "n", "]x",         function() require("diffview.actions").next_conflict() end,                  { desc = "Next conflict" } },
        { "n", "[x",         function() require("diffview.actions").prev_conflict() end,                  { desc = "Previous conflict" } },
        { "n", "<leader>q",  "<cmd>DiffviewClose<cr>",                                                    { desc = "Close diffview" } },
      },
      file_panel = {
        { "n", "<leader>q", "<cmd>DiffviewClose<cr>", { desc = "Close diffview" } },
      },
    },
  },
}
