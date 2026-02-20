local M = {}
local config = require("android.config")
local adb = require("android.adb")
local logcat = require("android.logcat")
local gradle = require("android.gradle")

local function create_commands()
  vim.api.nvim_create_user_command("AndroidSelectDevice", function()
    adb.select_device()
  end, { desc = "Select an Android device to target" })

  vim.api.nvim_create_user_command("AndroidStartEmulator", function()
    adb.start_emulator()
  end, { desc = "Start an Android Emulator" })

  vim.api.nvim_create_user_command("AndroidLogcatToggle", function()
    logcat.toggle()
  end, { desc = "Toggle Android Logcat Window" })

  vim.api.nvim_create_user_command("AndroidBuild", function()
    gradle.build()
  end, { desc = "Run Gradle Build" })

  vim.api.nvim_create_user_command("AndroidBuildAndRun", function()
    gradle.install_and_run()
  end, { desc = "Run Gradle Install and Launch App" })

  vim.api.nvim_create_user_command("AndroidClean", function()
    gradle.clean()
  end, { desc = "Run Gradle Clean" })
end

local function setup_which_key()
  -- Try to safely load which-key
  local ok, wk = pcall(require, "which-key")
  if not ok then return end

  -- Register the group name for <leader>a so users see "Android" in their popup
  wk.add({
    { "<leader>a", group = "Android", icon = "󰀲 ", mode = { "n", "v" } },
  })
end

function M.setup(opts)
  config.setup(opts)
  create_commands()
  
  -- We defer this slightly to ensure which-key is loaded if lazy-loaded
  vim.schedule(function()
    setup_which_key()
  end)
end

return M
