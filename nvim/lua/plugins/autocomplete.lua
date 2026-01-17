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

      -- Use Tab/S-Tab for both completion navigation AND snippet navigation
      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

      -- Disable arrow keys for completion (allow normal vim movement)
      ['<Up>'] = { 'fallback' },
      ['<Down>'] = { 'fallback' },
    },

    appearance = {
      nerd_font_variant = 'mono'
    },
    -- (Default) Only show the documentation popup when manually triggered
    completion = { documentation = { auto_show = false } },

    -- Default list of enabled providers defined so that you can extend it
    -- elsewhere in your config, without redefining it, due to `opts_extend`
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    fuzzy = { implementation = "prefer_rust_with_warning" }
  },
  opts_extend = { "sources.default" }
}
