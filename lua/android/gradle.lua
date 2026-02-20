local M = {}
local adb = require("android.adb")
local detect = require("android.detect")
local config = require("android.config")

local build_term = nil

local function get_gradlew()
  local cwd = vim.fn.getcwd()
  if vim.fn.filereadable(cwd .. "/gradlew") == 1 then
    return "./gradlew"
  end
  return "gradle" -- Fallback if not found locally
end

function M.build()
  local cmd = { get_gradlew() }
  for _, arg in ipairs(config.options.build_args) do
    table.insert(cmd, arg)
  end

  if build_term and build_term.buf and vim.api.nvim_buf_is_valid(build_term.buf) then
    build_term:toggle()
    return
  end

  build_term = Snacks.terminal(cmd, {
    win = { position = "bottom", height = 15, title = " Gradle Build " },
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Android build completed successfully!", vim.log.levels.INFO)
      else
        vim.notify("Android build failed with code " .. code, vim.log.levels.ERROR)
      end
    end
  })
end

function M.install_and_run()
  local device = adb.ensure_device()
  if not device then return end

  local pkg = detect.get_package_name()
  local activity = detect.get_main_activity()

  if not pkg then
    vim.notify("Could not detect package name to run.", vim.log.levels.ERROR)
    return
  end
  if not activity then
    vim.notify("Could not detect main activity. App might install but won't auto-launch.", vim.log.levels.WARN)
  end

  local cmd = { get_gradlew() }
  for _, arg in ipairs(config.options.install_args) do
    table.insert(cmd, arg)
  end

  if build_term and build_term.buf and vim.api.nvim_buf_is_valid(build_term.buf) then
    build_term:toggle()
    return
  end

  build_term = Snacks.terminal(cmd, {
    win = { position = "bottom", height = 15, title = " Gradle Install " },
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Android install completed successfully!", vim.log.levels.INFO)
        if activity then
          -- Run the app
          local run_cmd = string.format("adb -s %s shell am start -n %s/%s", device, pkg, activity)
          vim.fn.system(run_cmd)
          vim.notify("Launched " .. pkg, vim.log.levels.INFO)
        end
      else
        vim.notify("Android install failed with code " .. code, vim.log.levels.ERROR)
      end
    end
  })
end

function M.clean()
  local cmd = { get_gradlew(), "clean" }
  
  if build_term and build_term.buf and vim.api.nvim_buf_is_valid(build_term.buf) then
    build_term:toggle()
    return
  end

  build_term = Snacks.terminal(cmd, {
    win = { position = "bottom", height = 15, title = " Gradle Clean " },
  })
end

return M
