return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    config = function()
      require("mason-nvim-dap").setup({
        ensure_installed = { "javadbg", "javatest" },
        automatic_installation = true,
        handlers = {},
      })
    end,
  },
}
