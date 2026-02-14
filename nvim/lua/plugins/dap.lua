return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>dc", desc = "[D]ebug: Start/[C]ontinue" },
      { "<leader>di", desc = "[D]ebug: Step [I]nto" },
      { "<leader>do", desc = "[D]ebug: Step [O]ver" },
      { "<leader>du", desc = "[D]ebug: Step O[u]t" },
      { "<leader>db", desc = "[D]ebug: Toggle [B]reakpoint" },
      { "<leader>dB", desc = "[D]ebug: Set Conditional [B]reakpoint" },
      { "<leader>dt", desc = "[D]ebug: [T]erminate" },
      { "<leader>dr", desc = "[D]ebug: Open [R]EPL" },
      { "<leader>dl", desc = "[D]ebug: Run [L]ast" },
    },
    config = function()
      local dap = require("dap")

      -- DAP keymaps
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "[D]ebug: Start/[C]ontinue" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "[D]ebug: Step [I]nto" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "[D]ebug: Step [O]ver" })
      vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "[D]ebug: Step O[u]t" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "[D]ebug: Toggle [B]reakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "[D]ebug: Set Conditional [B]reakpoint" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "[D]ebug: [T]erminate" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "[D]ebug: Open [R]EPL" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "[D]ebug: Run [L]ast" })

      -- Configure DAP signs (breakpoint markers)
      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🟡", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "❌", texthl = "", linehl = "", numhl = "" })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    keys = {
      { "<leader>dui", desc = "[D]ebug: Toggle [UI]" },
      { "<leader>de", mode = { "n", "v" }, desc = "[D]ebug: [E]val" },
    },
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dap, dapui = require("dap"), require("dapui")

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes",      size = 0.33 },
              { id = "breakpoints", size = 0.17 },
              { id = "stacks",      size = 0.25 },
              { id = "watches",     size = 0.25 },
            },
            size = 0.25,  -- 25% of screen width
            position = "right",
          },
          {
            elements = {
              { id = "repl",    size = 0.5 },
              { id = "console", size = 0.5 },
            },
            size = 0.25,  -- 25% of screen height
            position = "bottom",
          },
        },
        floating = {
          max_height = 0.9,
          max_width = 0.5,
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
      })

      -- DAP UI keymaps
      vim.keymap.set("n", "<leader>dui", function()
        dapui.toggle({ reset = true })
      end, { desc = "[D]ebug: Toggle [UI]" })

      vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "[D]ebug: [E]val under cursor" })
      vim.keymap.set("v", "<leader>de", dapui.eval, { desc = "[D]ebug: [E]val selection" })

      -- Automatically open DAP UI (keep open to see test results)
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end

      -- Reset dap-ui layout when nvim-tree toggles to prevent expansion
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "NvimTree",
        callback = function()
          vim.schedule(function()
            -- Check if dapui is open
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              local buf = vim.api.nvim_win_get_buf(win)
              local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
              if ft and ft:match("^dapui_") then
                -- Reset dapui to restore original proportions
                dapui.close()
                dapui.open({ reset = true })
                break
              end
            end
          end)
        end,
      })
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-dap-virtual-text").setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        commented = false,
        only_first_definition = true,
        all_references = false,
        filter_references_pattern = "<module",
        virt_text_pos = "eol",
        all_frames = false,
        virt_lines = false,
        virt_text_win_col = nil,
      })
    end,
  },
}
