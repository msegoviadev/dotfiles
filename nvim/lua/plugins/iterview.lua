-- Remote (published) version:
return {
  "msegoviadev/nvim-iterview",
  cmd = { "IterviewCheckpoint", "IterviewDiff", "IterviewHistory", "IterviewClear" },
  keys = {
    { "<leader>ic", desc = "[I]terview [C]heckpoint" },
    { "<leader>id", desc = "[I]terview [D]iff" },
    { "<leader>ih", desc = "[I]terview [H]istory" },
    { "<leader>ix", desc = "[I]terview Clear" },
  },
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  config = function()
    require("iterview").setup()
  end,
}

-- Local development version (uncomment to use, comment the block above):
-- return {
--   dir = "~/workspace/nvim-iterview",
--   cmd = { "IterviewCheckpoint", "IterviewDiff", "IterviewHistory", "IterviewClear" },
--   keys = {
--     { "<leader>ic", desc = "[I]terview [C]heckpoint" },
--     { "<leader>id", desc = "[I]terview [D]iff" },
--     { "<leader>ih", desc = "[I]terview [H]istory" },
--     { "<leader>ix", desc = "[I]terview Clear" },
--   },
--   dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
--   config = function()
--     require("iterview").setup()
--   end,
-- }
