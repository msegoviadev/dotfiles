return {
  'saghen/blink.cmp',
  event = "InsertEnter",
  dependencies = { 'rafamadriz/friendly-snippets' },
  version = '1.*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'enter',

      -- Tab accepts the highlighted suggestion (VSCode-style); inside a snippet
      -- it jumps to the next placeholder. <C-n>/<C-p> still move through the list.
      ['<Tab>'] = {
        function(cmp)
          if cmp.snippet_active() then return cmp.accept() end
          return cmp.select_and_accept()
        end,
        'snippet_forward',
        'fallback',
      },
      ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

      -- Disable arrow keys for completion (allow normal vim movement)
      ['<Up>'] = { 'fallback' },
      ['<Down>'] = { 'fallback' },

      -- Ctrl-j / Ctrl-k move through the list while it is open, and do their
      -- normal insert-mode thing (newline, etc.) when it is closed
      ['<C-j>'] = { 'select_next', 'fallback' },
      ['<C-k>'] = { 'select_prev', 'fallback' },
    },

    appearance = {
      nerd_font_variant = 'mono'
    },
    -- (Default) Only show the documentation popup when manually triggered
    completion = { documentation = { auto_show = false } },

    -- Show the signature help automatically while typing an argument list
    signature = { enabled = true },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
