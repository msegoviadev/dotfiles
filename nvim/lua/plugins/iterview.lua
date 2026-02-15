-- Remote (published) version:
return {
  "msegoviadev/nvim-iterview",
  lazy = false,
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  config = function()
    require("iterview").setup()
  end,
}

-- Local development version (uncomment to use, comment the block above):
-- return {
--   dir = "~/workspace/nvim-iterview",
--   lazy = false,
--   dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
--   config = function()
--     require("iterview").setup()
--   end,
-- }
