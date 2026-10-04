return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    -- map_bs (default true) removes both characters when you backspace the
    -- opening one while the cursor sits between an empty pair.
    map_bs = true,
    -- map_cr (default true) re-indents between a pair when you press Enter.
    map_cr = true,
    -- The default pattern includes %w, so a closer is skipped when the next
    -- character is a word. That blocks @NotBlank( before a type name, so drop
    -- %w and %%.
    ignored_next_char = [=[[%'%[%"%.%`%$]]=],
  },
  config = function(_, opts)
    require("nvim-autopairs").setup(opts)
  end,
}
