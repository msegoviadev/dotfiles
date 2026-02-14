return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "windwp/nvim-ts-autotag",
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  build = ':TSUpdate',
  config = function()
    local ts_config = require("nvim-treesitter")

    ts_config.setup({
      ensure_installed = { "vim", "vimdoc", "lua", "java", "javascript", "typescript", "html", "css", "json", "tsx", "markdown", "markdown_inline", "gitignore", "python" },
      highlight = { enable = true },
      autotag = {
        enable = true
      }
    })

    -- Configure ts-context-commentstring for native Neovim commenting
    require('ts_context_commentstring').setup({
      enable_autocmd = false,
    })

    -- Integrate with native commenting
    vim.g.skip_ts_context_commentstring_module = true
  end
}
