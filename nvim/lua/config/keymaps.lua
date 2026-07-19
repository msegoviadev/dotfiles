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

-- Open merge conflict resolution tool
vim.keymap.set("n", "<leader>cm", "<cmd>DiffviewOpen<cr>", { desc = "[C]onflict [M]erge tool" })
