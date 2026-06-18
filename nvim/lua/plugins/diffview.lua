return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen" },
  opts = {
    view = {
      merge_tool = {
        layout = "diff4_mixed",
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
        { "n", "<leader>cb", function() require("diffview.actions").conflict_choose("base") end,          { desc = "[C]onflict choose [B]ase" } },
        -- Stage resolved file
        { "n", "<leader>cs", function()
          local view = require("diffview.lib").get_current_view()
          if not (view and view.cur_entry) then return end
          local top = view.adapter.ctx.toplevel
          local path = view.cur_entry.path
          vim.fn.system(string.format("git -C %s add %s", vim.fn.shellescape(top), vim.fn.shellescape(path)))
          view:update_files()
        end, { desc = "[C]onflict [S]tage" } },
        -- Navigation
        { "n", "]x",         function() require("diffview.actions").next_conflict() end,                  { desc = "Next conflict" } },
        { "n", "[x",         function() require("diffview.actions").prev_conflict() end,                  { desc = "Previous conflict" } },
        { "n", "<leader>q",  "<cmd>DiffviewClose<cr>",                                                    { desc = "Close diffview" } },
        { "n", "<tab>",      function() require("diffview.actions").focus_files() end,                    { desc = "Focus file panel" } },
      },
      file_panel = {
        { "n", "j",          function() require("diffview.actions").next_entry() end,                     { desc = "Next file" } },
        { "n", "k",          function() require("diffview.actions").prev_entry() end,                     { desc = "Previous file" } },
        { "n", "l",          function() require("diffview.actions").select_entry() end,                   { desc = "Open file diff" } },
        { "n", "<cr>",       function() require("diffview.actions").select_entry() end,                   { desc = "Open file diff" } },
        { "n", "<tab>",      function() require("diffview.actions").select_entry() end,                   { desc = "Open file diff" } },
        { "n", "s",          function() require("diffview.actions").toggle_stage_entry() end,             { desc = "Stage/unstage file" } },
        { "n", "<leader>q",  "<cmd>DiffviewClose<cr>",                                                    { desc = "Close diffview" } },
      },
    },
  },
}
