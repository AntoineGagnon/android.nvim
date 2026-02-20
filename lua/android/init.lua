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
  local ok, wk = pcall(require, "which-key")
  if not ok then
    -- Fallback to standard keymaps if which-key is not installed
    vim.keymap.set("n", "<leader>aa", "<cmd>AndroidBuildAndRun<cr>", { desc = "Android Build & Run" })
    vim.keymap.set("n", "<leader>ab", "<cmd>AndroidBuild<cr>", { desc = "Android Build" })
    vim.keymap.set("n", "<leader>ac", "<cmd>AndroidClean<cr>", { desc = "Android Clean" })
    vim.keymap.set("n", "<leader>al", "<cmd>AndroidLogcatToggle<cr>", { desc = "Android Logcat" })
    vim.keymap.set("n", "<leader>ad", "<cmd>AndroidSelectDevice<cr>", { desc = "Android Select Device" })
    vim.keymap.set("n", "<leader>ae", "<cmd>AndroidStartEmulator<cr>", { desc = "Android Start Emulator" })
    return
  end

  -- We use which-key to register both the group AND the actual keymaps with icons!
  wk.add({
    { "<leader>a", group = "Android", icon = "󰀲 ", mode = { "n", "v" } },
    { "<leader>aa", "<cmd>AndroidBuildAndRun<cr>", desc = "Android Build & Run", icon = "󰏖 ", mode = "n" },
    { "<leader>ab", "<cmd>AndroidBuild<cr>", desc = "Android Build", icon = "󰏖 ", mode = "n" },
    { "<leader>ac", "<cmd>AndroidClean<cr>", desc = "Android Clean", icon = "󰃢 ", mode = "n" },
    { "<leader>ad", "<cmd>AndroidSelectDevice<cr>", desc = "Android Select Device", icon = "󰄜 ", mode = "n" },
    { "<leader>ae", "<cmd>AndroidStartEmulator<cr>", desc = "Android Start Emulator", icon = "󰍲 ", mode = "n" },
    { "<leader>al", "<cmd>AndroidLogcatToggle<cr>", desc = "Android Logcat", icon = "󰈐 ", mode = "n" },
  })
end

function M.setup(opts)
  config.setup(opts)
  create_commands()
  
  -- Use an autocmd to wait until VeryLazy to setup which-key,
  -- ensuring we don't conflict with LazyVim's which-key initialization
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      setup_which_key()
    end,
  })
end

return M
