return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "mfussenegger/nvim-dap",
    "nvim-neotest/neotest-jest",
    {
      "thenbe/neotest-playwright",
      dependencies = { "nvim-telescope/telescope.nvim" },
    },
  },
  config = function()
    local neotest = require("neotest")
    local icons = require("config.icons")

    neotest.setup({
      adapters = {
        -- Playwright for E2E tests (matches *.spec.ts in e2e folders)
        require("neotest-playwright").adapter({
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
            -- Don't set CI env var so reuseExistingServer stays true
            env = {},
            get_playwright_binary = function()
              return vim.loop.cwd() .. "/node_modules/.bin/playwright"
            end,
            get_playwright_config = function()
              return vim.loop.cwd() .. "/playwright.config.ts"
            end,
          }
        }),
        -- Jest for unit tests (matches *.test.ts/js files)
        require("neotest-jest")({
          jestCommand = "npm test --",
          env = { CI = true },
          cwd = function()
            return vim.fn.getcwd()
          end,
          -- Custom isTestFile that doesn't call vim.notify in fast events
          isTestFile = function(file_path)
            if not file_path then
              return false
            end
            -- Only match .test.* files (not .spec.* which are for Playwright)
            return file_path:match("%.test%.[jt]sx?$")
          end,
        }),
      },
      -- Configure icons for test status
      icons = {
        running = icons.misc.Watch,
        passed = icons.ui.Check,
        failed = icons.ui.Close,
        unknown = icons.diagnostics.Question,
      },
      -- Show output in a floating window
      output = {
        enabled = true,
        open_on_run = "short",
      },
      output_panel = {
        enabled = true,
        open = "botright split | resize 15",
      },
      -- Show test status in the sign column
      status = {
        enabled = true,
        virtual_text = false,
        signs = true,
      },
    })

    -- Run the nearest test
    vim.keymap.set("n", "<leader>tr", function()
      vim.notify("Running nearest test...", vim.log.levels.INFO)
      neotest.run.run()
      vim.defer_fn(function()
        neotest.output_panel.open()
      end, 500)
    end, { desc = "[T]est [R]un Nearest" })

    -- Run all tests in the current file
    vim.keymap.set("n", "<leader>tf", function()
      vim.notify("Running all tests in file...", vim.log.levels.INFO)
      neotest.run.run(vim.fn.expand("%"))
      vim.defer_fn(function()
        neotest.output_panel.open()
      end, 500)
    end, { desc = "[T]est Run [F]ile" })

    -- Show output of nearest test
    vim.keymap.set("n", "<leader>tO", function()
      neotest.output.open({ enter = true })
    end, { desc = "[T]est [O]utput" })

    -- Run all tests in the project
    vim.keymap.set("n", "<leader>ta", function()
      neotest.run.run(vim.fn.getcwd())
    end, { desc = "[T]est Run [A]ll" })

    -- Toggle test summary window
    vim.keymap.set("n", "<leader>ts", function()
      neotest.summary.toggle()
    end, { desc = "[T]est [S]ummary" })

    -- Toggle test output panel
    vim.keymap.set("n", "<leader>to", function()
      neotest.output_panel.toggle()
    end, { desc = "[T]est [O]utput Panel" })

    -- Stop the nearest test
    vim.keymap.set("n", "<leader>tx", function()
      neotest.run.stop()
    end, { desc = "[T]est Stop" })

    -- Debug the nearest test
    vim.keymap.set("n", "<leader>td", function()
      neotest.run.run({ strategy = "dap" })
    end, { desc = "[T]est [D]ebug Nearest" })

    -- Jump to next failed test
    vim.keymap.set("n", "]t", function()
      neotest.jump.next({ status = "failed" })
    end, { desc = "Next Failed Test" })

    -- Jump to previous failed test
    vim.keymap.set("n", "[t", function()
      neotest.jump.prev({ status = "failed" })
    end, { desc = "Previous Failed Test" })

    -- Debug: show adapter info
    vim.keymap.set("n", "<leader>ti", function()
      local adapters = require("neotest.config").adapters
      local msg = "Adapters:\n"
      for i, adapter in ipairs(adapters) do
        msg = msg .. string.format("%d. %s\n", i, adapter.name)
      end
      vim.notify(msg, vim.log.levels.INFO)
    end, { desc = "[T]est [I]nfo" })
  end,
}
