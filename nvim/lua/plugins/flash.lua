return {
  "folke/flash.nvim",
  event = "VeryLazy",
  opts = {
    modes = {
      char = {
        enabled = false,
        highlight = { backdrop = true },
      },
      search = {
        enabled = false,
      },
    },
    label = {
      style = "overlay",
      min_pattern_length = 1,
    },
    jump = {
      autojump = false,
    },
    highlight = {
      backdrop = true,
      matches = true,
    },
  },
  keys = {
    { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "[F]lash Jump" },
    { "F", mode = { "n", "x", "o" }, function() require("flash").jump({ search = { forward = false } }) end, desc = "[F]lash Jump Backward" },
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "[S]earch and Jump" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "[S]earch Treesitter" },
    { "r", mode = "o", function() require("flash").treesitter_search() end, desc = "[R]emote Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "[S]earch Flash Toggle" },
    { "<leader>jl", mode = { "n", "x", "o" }, function() require("flash").jump({ pattern = "." }) end, desc = "[J]ump to [L]ine" },
  },
}