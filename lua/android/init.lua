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

function M.setup(opts)
  config.setup(opts)
  create_commands()
end

return M
