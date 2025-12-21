return {
  {
    "mfussenegger/nvim-jdtls",
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = false,
      },
    },
  },
}
