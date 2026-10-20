-- Run the current file, or the test related to it, in a terminal split.
--
-- Test discovery follows the usual naming conventions: Foo.java pairs with
-- FooTest.java, foo.py with test_foo.py, foo.go with foo_test.go, and so on.
-- Build tools are detected by walking up to pom.xml, Gradle, package.json, or
-- Cargo.toml.

local M = {}

local run_win = nil

local file_runners = {
  java = function(file) return { "java", file } end,
  python = function(file) return { "python3", file } end,
  javascript = function(file) return { "node", file } end,
  typescript = function(file) return { "npx", "tsx", file } end,
  go = function(file) return { "go", "run", file } end,
  lua = function(file) return { "nvim", "-l", file } end,
  sh = function(file) return { "bash", file } end,
  bash = function(file) return { "bash", file } end,
  ruby = function(file) return { "ruby", file } end,
  php = function(file) return { "php", file } end,
  kotlin = function(file) return { "kotlin", file } end,
}

local function is_file(path)
  return vim.fn.filereadable(path) == 1
end

local function find_up(start, names)
  local dir = start
  while dir and dir ~= "" do
    for _, name in ipairs(names) do
      if is_file(dir .. "/" .. name) then
        return dir
      end
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

local function java_tests(file)
  local dir = vim.fn.fnamemodify(file, ":h")
  local base = vim.fn.fnamemodify(file, ":t:r")

  if base:match("Test$") or base:match("Tests$") then
    return { file }
  end

  local candidates = {
    dir .. "/" .. base .. "Test.java",
    dir .. "/" .. base .. "Tests.java",
  }

  local mirror = file:gsub("/src/main/java/", "/src/test/java/")
  if mirror ~= file then
    local mirror_base = vim.fn.fnamemodify(mirror, ":r")
    table.insert(candidates, mirror_base .. "Test.java")
    table.insert(candidates, mirror_base .. "Tests.java")
  end

  return candidates
end

local function python_tests(file)
  local dir = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(file, ":t")

  if name:match("^test_") or name:match("_test%.py$") then
    return { file }
  end

  local base = vim.fn.fnamemodify(file, ":t:r")
  return {
    dir .. "/test_" .. base .. ".py",
    dir .. "/" .. base .. "_test.py",
    dir .. "/tests/test_" .. base .. ".py",
    dir .. "/tests/" .. base .. "_test.py",
  }
end

local function go_tests(file)
  local dir = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(file, ":t")

  if name:match("_test%.go$") then
    return { file }
  end

  return { dir .. "/" .. vim.fn.fnamemodify(file, ":t:r") .. "_test.go" }
end

local function js_tests(file)
  local dir = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(file, ":t")

  if name:match("%.test%.") or name:match("%.spec%.") or dir:match("/__tests__$") then
    return { file }
  end

  local base = vim.fn.fnamemodify(file, ":t:r")
  local ext = vim.fn.fnamemodify(file, ":e")
  return {
    dir .. "/" .. base .. ".test." .. ext,
    dir .. "/" .. base .. ".spec." .. ext,
    dir .. "/__tests__/" .. base .. "." .. ext,
    dir .. "/__tests__/" .. base .. ".test." .. ext,
  }
end

local test_finders = {
  java = java_tests,
  python = python_tests,
  go = go_tests,
  javascript = js_tests,
  javascriptreact = js_tests,
  typescript = js_tests,
  typescriptreact = js_tests,
}

function M.test_file_for(file, filetype)
  filetype = filetype or vim.bo.filetype
  local finder = test_finders[filetype]
  if not finder then
    return filetype == "rust" and file or nil
  end

  for _, path in ipairs(finder(file)) do
    if is_file(path) then
      return path
    end
  end

  return nil
end

local function java_class_name(path)
  local name = vim.fn.fnamemodify(path, ":t:r")
  for _, line in ipairs(vim.fn.readfile(path, "", 40)) do
    local package = line:match("^%s*package%s+([%w_%.]+)%s*;")
    if package then
      return package .. "." .. name
    end
  end
  return name
end

local function java_test_command(test_file)
  local dir = vim.fn.fnamemodify(test_file, ":h")
  local simple_name = vim.fn.fnamemodify(test_file, ":t:r")
  local root = find_up(dir, { "pom.xml", "build.gradle", "build.gradle.kts", "gradlew" })

  if root then
    if is_file(root .. "/pom.xml") then
      return { "mvn", "-q", "-Dtest=" .. simple_name, "test" }, root
    end

    local gradlew = is_file(root .. "/gradlew") and (root .. "/gradlew") or "gradle"
    return { gradlew, "test", "--tests", simple_name }, root
  end

  local command = "javac *.java && java " .. java_class_name(test_file)
  return { "sh", "-c", command }, dir
end

local function python_test_command(test_file)
  local dir = vim.fn.fnamemodify(test_file, ":h")
  if vim.fn.executable("pytest") == 1 then
    return { "pytest", "-q", test_file }, dir
  end
  return { "python3", test_file }, dir
end

local function go_test_command(test_file)
  return { "go", "test" }, vim.fn.fnamemodify(test_file, ":h")
end

local function js_test_command(test_file)
  local dir = vim.fn.fnamemodify(test_file, ":h")
  local root = find_up(dir, { "package.json" }) or dir

  local vitest = root .. "/node_modules/.bin/vitest"
  if vim.fn.executable(vitest) == 1 then
    return { vitest, "run", test_file }, root
  end

  local jest = root .. "/node_modules/.bin/jest"
  if vim.fn.executable(jest) == 1 then
    return { jest, test_file }, root
  end

  return { "node", "--test", test_file }, dir
end

local function rust_test_command(test_file)
  local root = find_up(vim.fn.fnamemodify(test_file, ":h"), { "Cargo.toml" })
  if not root then
    return nil
  end
  return { "cargo", "test" }, root
end

local test_commands = {
  java = java_test_command,
  python = python_test_command,
  go = go_test_command,
  javascript = js_test_command,
  javascriptreact = js_test_command,
  typescript = js_test_command,
  typescriptreact = js_test_command,
  rust = rust_test_command,
}

function M.command_for_test(test_file, filetype)
  filetype = filetype or vim.bo.filetype
  local builder = test_commands[filetype]
  if not builder then
    return nil
  end
  return builder(test_file)
end

function M.command_for(filetype, file)
  local runner = file_runners[filetype]
  if not runner then
    return nil
  end
  return runner(file)
end

function M.open_terminal(command, dir)
  if run_win and vim.api.nvim_win_is_valid(run_win) then
    vim.api.nvim_win_close(run_win, true)
  end

  vim.cmd("botright 12split")
  run_win = vim.api.nvim_get_current_win()
  vim.cmd("enew")
  if dir then
    vim.fn.termopen(command, { cwd = dir })
  else
    vim.fn.termopen(command)
  end

  -- Stay in normal mode so j/k scroll the output, and close the window with
  -- Esc or q instead of leaving terminal mode.
  local close_terminal = function()
    vim.cmd("bdelete!")
  end
  local run_buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "<Esc>", close_terminal, { buffer = run_buf, desc = "Close terminal" })
  vim.keymap.set("n", "q", close_terminal, { buffer = run_buf, desc = "Close terminal" })
end

function M.run_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Save the file before running it", vim.log.levels.WARN)
    return
  end

  vim.cmd("write")

  local filetype = vim.bo.filetype
  local command = M.command_for(filetype, file)
  if not command then
    vim.notify("No runner for filetype '" .. filetype .. "'", vim.log.levels.WARN)
    return
  end

  M.open_terminal(command)
end

function M.run_test()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Save the file before running its test", vim.log.levels.WARN)
    return
  end

  vim.cmd("write")

  local filetype = vim.bo.filetype
  local test_file = M.test_file_for(file, filetype)
  if not test_file then
    vim.notify("No test file found for " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.WARN)
    return
  end

  local command, dir = M.command_for_test(test_file, filetype)
  if not command then
    vim.notify("No test runner for filetype '" .. filetype .. "'", vim.log.levels.WARN)
    return
  end

  M.open_terminal(command, dir)
end

return M
