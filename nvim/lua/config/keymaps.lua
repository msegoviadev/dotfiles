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

-- DAP (Debugging) keymaps
vim.keymap.set("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "[D]ebug: Start/[C]ontinue" })

vim.keymap.set("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "[D]ebug: Step [I]nto" })

vim.keymap.set("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "[D]ebug: Step [O]ver" })

vim.keymap.set("n", "<leader>du", function()
  require("dap").step_out()
end, { desc = "[D]ebug: Step O[u]t" })

vim.keymap.set("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "[D]ebug: Toggle [B]reakpoint" })

vim.keymap.set("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "[D]ebug: Set Conditional [B]reakpoint" })

vim.keymap.set("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "[D]ebug: [T]erminate" })

vim.keymap.set("n", "<leader>dr", function()
  require("dap").repl.open()
end, { desc = "[D]ebug: Open [R]EPL" })

vim.keymap.set("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "[D]ebug: Run [L]ast" })

-- DAP UI keymaps
vim.keymap.set("n", "<leader>dui", function()
  require("dapui").toggle({ reset = true })
end, { desc = "[D]ebug: Toggle [UI]" })

vim.keymap.set("n", "<leader>de", function()
  require("dapui").eval()
end, { desc = "[D]ebug: [E]val under cursor" })

vim.keymap.set("v", "<leader>de", function()
  require("dapui").eval()
end, { desc = "[D]ebug: [E]val selection" })

-- Java Test & Debug Keybindings (nvim-java)
-- Test Running
vim.keymap.set("n", "<leader>jt", function()
  require('dapui').open()
  require('java').test.run_current_method()
end, { desc = "[J]ava: [T]est Method" })

vim.keymap.set("n", "<leader>jT", function()
  require('dapui').open()
  require('java').test.run_current_class()
end, { desc = "[J]ava: [T]est Class" })

vim.keymap.set("n", "<leader>jr", ":JavaTestViewLastReport<CR>", { desc = "[J]ava: Test [R]eport" })

-- Test Debugging
vim.keymap.set("n", "<leader>jd", ":JavaTestDebugCurrentMethod<CR>", { desc = "[J]ava: [D]ebug Test Method" })
vim.keymap.set("n", "<leader>jD", ":JavaTestDebugCurrentClass<CR>", { desc = "[J]ava: [D]ebug Test Class" })

-- Application Running
vim.keymap.set("n", "<leader>ja", ":JavaRunnerRunMain<CR>", { desc = "[J]ava: Run [A]pplication" })
vim.keymap.set("n", "<leader>js", ":JavaRunnerStopMain<CR>", { desc = "[J]ava: [S]top Application" })
vim.keymap.set("n", "<leader>jl", ":JavaRunnerToggleLogs<CR>", { desc = "[J]ava: Toggle [L]ogs" })

-- Java Refactoring
vim.keymap.set("n", "<leader>jv", ":JavaRefactorExtractVariable<CR>", { desc = "[J]ava: Extract [V]ariable" })
vim.keymap.set("v", "<leader>jv", ":JavaRefactorExtractVariable<CR>", { desc = "[J]ava: Extract [V]ariable" })
vim.keymap.set("n", "<leader>jc", ":JavaRefactorExtractConstant<CR>", { desc = "[J]ava: Extract [C]onstant" })
vim.keymap.set("v", "<leader>jm", ":JavaRefactorExtractMethod<CR>", { desc = "[J]ava: Extract [M]ethod" })

-- Java Settings
vim.keymap.set("n", "<leader>jR", ":JavaSettingsChangeRuntime<CR>", { desc = "[J]ava: Change [R]untime" })

-- Java Build
vim.keymap.set("n", "<leader>jb", ":JavaBuildBuildWorkspace<CR>", { desc = "[J]ava: [B]uild Workspace" })
vim.keymap.set("n", "<leader>jC", ":JavaBuildCleanWorkspace<CR>", { desc = "[J]ava: [C]lean Workspace" })
