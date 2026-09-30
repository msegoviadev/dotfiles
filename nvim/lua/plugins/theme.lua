-- The active Omarchy theme owns the colorscheme. The spec comes from
-- ~/.local/state/omarchy/current/theme/neovim.lua via the adapter; a
-- filesystem poll on that file hot-reloads the colorscheme when the omarchy
-- theme changes, so nvim retints live without a restart.
local omarchy_theme = require("config.omarchy_theme")

omarchy_theme.watch()

local spec = omarchy_theme.get_plugin_spec()

-- No readable theme file (fresh install, non-omarchy machine): still start
-- the watcher and fall back to a built-in colorscheme.
if not spec then
  vim.schedule(function()
    pcall(vim.cmd.colorscheme, "habamax")
  end)
  return {}
end

return { spec }
