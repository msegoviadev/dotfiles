-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- telescope
-- local builtin = require("telescope.builtin")
-- vim.keymap.set("n", "<leader>f", builtin.find_files, {})
-- vim.keymap.set("n", "<leader>g", builtin.live_grep, {})
-- vim.keymap.set("n", "<leader>b", builtin.buffers, {})

-- Set our leader keybinding to space
-- Anywhere you see <leader> in a keymapping specifies the space key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Remove search highlights after searching
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Remove search highlights" })

-- Exit Vim's terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- OPTIONAL: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Better window navigation
vim.keymap.set("n", "<C-h>", ":wincmd h<cr>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", ":wincmd l<cr>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", ":wincmd j<cr>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", ":wincmd k<cr>", { desc = "Move focus to the upper window" })

vim.keymap.set("n", "<leader>tc", ":tabnew<cr>", { desc = "[T]ab [C]reat New" })
vim.keymap.set("n", "<leader>tn", ":tabnext<cr>", { desc = "[T]ab [N]ext" })
vim.keymap.set("n", "<leader>tp", ":tabprevious<cr>", { desc = "[T]ab [P]revious" })

-- Easily split windows
vim.keymap.set("n", "<leader>wv", ":vsplit<cr>", { desc = "[W]indow Split [V]ertical" })
vim.keymap.set("n", "<leader>wh", ":split<cr>", { desc = "[W]indow Split [H]orizontal" })

-- Stay in indent mode
vim.keymap.set("v", "<", "<gv", { desc = "Indent left in visual mode" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right in visual mode" })

-- Faster vertical scrolling (quarter page)
-- Computed from the current window height so the jump adapts to any split size,
-- while native <C-d>/<C-u> stay available for half-page jumps
local function quarter_page(direction)
  return function()
    local quarter = math.max(1, math.floor(vim.api.nvim_win_get_height(0) / 4))
    local count = vim.v.count > 0 and vim.v.count or 1
    return (quarter * count) .. direction
  end
end

vim.keymap.set("n", "J", quarter_page("j"), { expr = true, desc = "Quarter page down" })
vim.keymap.set("n", "K", quarter_page("k"), { expr = true, desc = "Quarter page up" })
vim.keymap.set("v", "J", quarter_page("j"), { expr = true, desc = "Quarter page down" })
vim.keymap.set("v", "K", quarter_page("k"), { expr = true, desc = "Quarter page up" })

-- Jump to line edges with H/L (vanilla H/L jump to top/bottom of screen)
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Move to first non-blank of line" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Move to end of line" })

-- Comment keymaps (using native Neovim 0.10+ commenting)
vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Comment Line" })
vim.keymap.set("v", "<leader>/", "gc", { remap = true, desc = "Comment Selected" })

-- Compare the selected lines against the current system clipboard.
local function diff_selection_with_clipboard()
  local source_buf = vim.api.nvim_get_current_buf()
  local visual_line = vim.fn.getpos("v")[2]
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local start_line = math.min(visual_line, cursor_line)
  local end_line = math.max(visual_line, cursor_line)
  local selection = vim.api.nvim_buf_get_lines(source_buf, start_line - 1, end_line, false)
  local clipboard = {}
  if vim.fn.executable("wl-paste") == 1 then
    local clipboard_text = vim.fn.system("wl-paste --type text/plain")
    if vim.v.shell_error == 0 then
      clipboard = vim.split(clipboard_text, "\n", { plain = true, trimempty = false })
      if clipboard[#clipboard] == "" then table.remove(clipboard) end
    end
  end
  if vim.v.shell_error ~= 0 or (#clipboard == 0) then
    clipboard = vim.fn.getreg("+", 1, true)
  end
  if #clipboard == 0 or (#clipboard == 1 and clipboard[1] == "") then
    clipboard = vim.fn.getreg("*", 1, true)
  end

  if #clipboard == 0 or (#clipboard == 1 and clipboard[1] == "") then
    vim.notify("The system clipboard is empty", vim.log.levels.WARN)
    return
  end

  local source_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(source_buf), ":t")
  if source_name == "" then source_name = "buffer" end

  local selection_buf = vim.api.nvim_create_buf(false, true)
  local clipboard_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(selection_buf, 0, -1, false, selection)
  vim.api.nvim_buf_set_lines(clipboard_buf, 0, -1, false, clipboard)

  for buffer, label in pairs({ [selection_buf] = "Selection", [clipboard_buf] = "Clipboard" }) do
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].buflisted = false
    vim.bo[buffer].modifiable = false
    vim.bo[buffer].readonly = true
    vim.bo[buffer].filetype = vim.bo[source_buf].filetype
    vim.api.nvim_buf_set_name(buffer, string.format("[%s] %s %d", label, source_name, buffer))
  end

  vim.cmd("tabnew")
  local placeholder_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_buf(0, selection_buf)
  if vim.api.nvim_buf_is_valid(placeholder_buf) and placeholder_buf ~= selection_buf then
    vim.api.nvim_buf_delete(placeholder_buf, { force = true })
  end
  vim.cmd("vsplit")
  vim.cmd("wincmd h")
  local selection_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(selection_win, selection_buf)
  vim.cmd("wincmd l")
  local clipboard_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(clipboard_win, clipboard_buf)

  for _, window in ipairs({ selection_win, clipboard_win }) do
    vim.api.nvim_set_current_win(window)
    vim.cmd("diffthis")
  end

  for _, buffer in ipairs({ selection_buf, clipboard_buf }) do
    vim.keymap.set("n", "q", "<cmd>tabclose<cr>", { buffer = buffer, desc = "Close clipboard diff" })
    vim.keymap.set("n", "<leader>q", "<cmd>tabclose<cr>", { buffer = buffer, desc = "Close clipboard diff" })
  end
end

vim.keymap.set("v", "<leader>dc", diff_selection_with_clipboard, { desc = "[D]iff selection with [C]lipboard" })

-- Open merge conflict resolution tool
vim.keymap.set("n", "<leader>cm", "<cmd>DiffviewOpen<cr>", { desc = "[C]onflict [M]erge tool" })
