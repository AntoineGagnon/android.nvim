local M = {}
local adb = require("android.adb")
local detect = require("android.detect")
local config = require("android.config")

local active_term = nil
M.filter_text = ""
M.app_filtered = config.options.filter_by_app

local function build_cmd()
  local device = adb.ensure_device()
  if not device then return nil end

  local cmd = { "adb", "-s", device, "logcat" }
  for _, flag in ipairs(config.options.logcat_flags) do table.insert(cmd, flag) end

  if M.app_filtered then
    local pkg = detect.get_package_name()
    if pkg then
      local pid = adb.get_pid(pkg, device)
      if pid then
        table.insert(cmd, "--pid=" .. pid)
      else
        vim.notify("App " .. pkg .. " is not running.", vim.log.levels.WARN)
      end
    end
  end

  table.insert(cmd, "*:" .. config.options.log_level)
  if M.filter_text ~= "" then
    table.insert(cmd, "-e")
    table.insert(cmd, M.filter_text)
  end

  return cmd
end

function M.toggle()
  if active_term and active_term.buf and vim.api.nvim_buf_is_valid(active_term.buf) then
    active_term:toggle()
    return
  end

  local cmd = build_cmd()
  if not cmd then return end

  active_term = Snacks.terminal(cmd, {
    win = { position = "bottom", height = 15, border = "rounded", title = " Logcat " },
    interactive = false,
  })

  -- Set keymaps after buffer is created
  vim.schedule(function()
    if active_term and active_term.buf then
      local bufnr = active_term.buf
      local opts = { buffer = bufnr, noremap = true, silent = true }
      
      vim.keymap.set("n", "q", "<cmd>close<CR>", vim.tbl_extend("force", opts, {desc="Close Logcat"}))
      vim.keymap.set("n", "c", function() M.clear() end, vim.tbl_extend("force", opts, {desc="Clear Logcat"}))
      vim.keymap.set("n", "f", function() M.change_filter() end, vim.tbl_extend("force", opts, {desc="Filter Logcat"}))
      vim.keymap.set("n", "l", function() M.change_level() end, vim.tbl_extend("force", opts, {desc="Log Level"}))
      vim.keymap.set("n", "a", function() M.toggle_app_filter() end, vim.tbl_extend("force", opts, {desc="Toggle App Filter"}))
    end
  end)
end

function M.clear()
  local device = adb.ensure_device()
  if device then
    vim.fn.system({"adb", "-s", device, "logcat", "-c"})
    vim.notify("Logcat cleared", vim.log.levels.INFO)
    if active_term then active_term:close() end
    M.toggle()
  end
end

function M.change_level()
  local levels = {"V (Verbose)", "D (Debug)", "I (Info)", "W (Warn)", "E (Error)", "F (Fatal)"}
  vim.ui.select(levels, { prompt = "Select Log Level:" }, function(choice)
    if choice then
      config.options.log_level = choice:sub(1,1)
      if active_term then active_term:close() end
      M.toggle()
    end
  end)
end

function M.change_filter()
  vim.ui.input({ prompt = "Filter logcat (regex): ", default = M.filter_text }, function(input)
    if input ~= nil then
      M.filter_text = input
      if active_term then active_term:close() end
      M.toggle()
    end
  end)
end

function M.toggle_app_filter()
  M.app_filtered = not M.app_filtered
  vim.notify("Filter by app PID: " .. tostring(M.app_filtered), vim.log.levels.INFO)
  if active_term then active_term:close() end
  M.toggle()
end

return M
