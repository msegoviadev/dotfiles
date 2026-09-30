-- Adapter between Omarchy's theme system and this (LazyVim-free) config.
--
-- Omarchy writes the active theme's neovim spec to
-- ~/.local/state/omarchy/current/theme/neovim.lua. That file is shaped for
-- LazyVim: it holds one spec per theme plugin plus a "LazyVim/LazyVim" entry
-- whose opts.colorscheme names the colorscheme to apply. We parse out both
-- parts so the theme plugin loads through lazy.nvim like any other plugin,
-- without pulling in LazyVim itself.
--
-- The theme path is polled (not fs_event) because `omarchy theme set` swaps
-- the whole current/theme directory atomically with rm+mv, which would
-- orphan an inode-based watcher. Polling re-stats the path, so it survives.
local M = {}

local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

-- Colorscheme used when the theme's own colorscheme cannot be applied, so a
-- broken/new theme never leaves the editor unstyled.
local fallback_colorscheme = "habamax"

-- Parse the omarchy theme file into its two relevant pieces.
-- Returns (theme plugin spec table | nil, colorscheme name | nil).
local function parse_theme()
  if vim.fn.filereadable(theme_file) == 0 then
    return nil, nil
  end

  local ok, specs = pcall(dofile, theme_file)
  if not ok or type(specs) ~= "table" then
    return nil, nil
  end

  local plugin_spec, colorscheme
  for _, spec in ipairs(specs) do
    if spec[1] == "LazyVim/LazyVim" then
      colorscheme = spec.opts and spec.opts.colorscheme
    elseif spec[1] then
      plugin_spec = spec
    end
  end

  return plugin_spec, colorscheme
end

-- The name lazy.nvim knows the theme plugin by (explicit name or url tail,
-- matching lazy's own derivation: tail minus a ".git" suffix only), needed
-- to look the plugin up in lazy's registry for reloads.
local function plugin_name(spec)
  return spec.name or spec[1]:match("[^/]+$"):gsub("%.git$", "")
end

local function apply_transparency()
  if vim.fn.filereadable(transparency_file) == 1 then
    vim.defer_fn(function()
      vim.cmd.source(transparency_file)
      vim.cmd("redraw!")
    end, 5)
  end
end

-- Apply a colorscheme by name, never throwing: on failure keep a usable
-- editor via the fallback and tell the user what happened.
local function apply_colorscheme(colorscheme)
  local ok = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok then
    vim.notify(
      ("Omarchy theme: colorscheme '%s' failed, falling back to '%s'"):format(colorscheme, fallback_colorscheme),
      vim.log.levels.WARN
    )
    pcall(vim.cmd.colorscheme, fallback_colorscheme)
  end
  apply_transparency()
end

-- Spec consumed by lua/plugins/theme.lua: the theme plugin itself, forced to
-- load eagerly so the colorscheme exists at startup. When the theme file is
-- missing or unparsable we return no spec at all and stay on the fallback.
function M.get_plugin_spec()
  local plugin_spec, colorscheme = parse_theme()
  if not plugin_spec then
    vim.notify("Omarchy theme: no theme file found, using fallback colorscheme", vim.log.levels.WARN)
    return nil
  end

  plugin_spec.lazy = false
  plugin_spec.priority = 1000
  plugin_spec.config = function()
    apply_colorscheme(colorscheme or fallback_colorscheme)
  end

  return plugin_spec
end

-- Hot-reload: re-read the theme file, swap the plugin if the theme uses a
-- different one, and apply the new colorscheme. Mirrors what omarchy's own
-- LazyVim-based hotreload plugin does on `User LazyReload`.
local function reload_theme()
  local plugin_spec, colorscheme = parse_theme()
  if not plugin_spec or not colorscheme then
    return
  end

  -- Clear existing highlights so the new theme starts from a clean slate
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  -- Let light themes set their own background
  vim.o.background = "dark"

  local name = plugin_name(plugin_spec)
  local plugin = require("lazy.core.config").plugins[name]

  if not plugin then
    -- Theme references a plugin we have not installed yet (e.g. a brand-new
    -- omarchy theme). Install just it, then finish the reload once done.
    vim.notify(("Omarchy theme: installing new theme plugin '%s'..."):format(name), vim.log.levels.INFO)
    require("lazy").install({
      plugins = { plugin_spec },
      wait = false,
      show = false,
    })
    vim.schedule(function()
      require("lazy").load({ plugins = { name } })
      vim.defer_fn(function()
        apply_colorscheme(colorscheme)
      end, 10)
    end)
    return
  end

  if plugin._.loaded then
    -- Already loaded: unload its lua modules so a reload re-runs setup() with
    -- the new theme's opts (matters when old and new theme share a plugin,
    -- e.g. aether-based generated themes).
    local plugin_dir = plugin.dir .. "/lua"
    require("lazy.core.util").walkmods(plugin_dir, function(modname)
      package.loaded[modname] = nil
      package.preload[modname] = nil
    end)
    require("lazy.core.loader").reload(plugin)
  else
    require("lazy").load({ plugins = { name } })
  end

  vim.defer_fn(function()
    apply_colorscheme(colorscheme)
  end, 10)
end

-- Start polling the theme file; on change, reload. Debounced because a theme
-- swap can touch the file more than once.
function M.watch()
  -- Only Omarchy writes this directory. Elsewhere (macOS) there is nothing to
  -- watch, and polling a missing path would tick once a second for no reason.
  if vim.fn.isdirectory(vim.fn.expand("~/.local/state/omarchy")) == 0 then
    return
  end

  local timer
  local poll = vim.uv.new_fs_poll()
  poll:start(theme_file, 1000, function()
    if timer then
      timer:stop()
    else
      timer = vim.uv.new_timer()
    end
    timer:start(300, 0, function()
      timer:stop()
      vim.schedule(reload_theme)
    end)
  end)
end

return M
