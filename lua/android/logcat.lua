local M = {}
local adb = require("android.adb")
local detect = require("android.detect")
local config = require("android.config")

local active_term = nil
M.filter_text = ""
M.app_filtered = config.options.filter_by_app

-- Returns a formatted title showing active filters
local function get_title()
  local title = " Logcat [Level: " .. config.options.log_level .. "] "
  if M.app_filtered then
    title = title .. "[App Only] "
  else
    title = title .. "[All Apps] "
  end
  if M.filter_text ~= "" then
    title = title .. "[Filter: '" .. M.filter_text .. "'] "
  end
  return title
end

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
        -- Fallback to all logs if app is not running
        M.app_filtered = false
      end
    else
      vim.notify("Could not detect package name.", vim.log.levels.WARN)
      M.app_filtered = false
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
  -- If terminal exists and buffer is valid, just toggle visibility
  if active_term and active_term.buf and vim.api.nvim_buf_is_valid(active_term.buf) then
    active_term:toggle()
    return
  end

  local cmd = build_cmd()
  if not cmd then return end

  active_term = Snacks.terminal(cmd, {
    win = { 
      position = "bottom", 
      height = 15, 
      border = "rounded", 
      title = get_title(),
      title_pos = "center" 
    },
    interactive = false, -- Logcat is read-only
  })

  -- Set terminal-local and normal-mode keymaps inside the Snacks terminal
  vim.schedule(function()
    if active_term and active_term.buf then
      local bufnr = active_term.buf
      local opts = { buffer = bufnr, noremap = true, silent = true }
      
      -- Keymaps for Normal mode
      vim.keymap.set("n", "q", "<cmd>close<CR>", vim.tbl_extend("force", opts, {desc="Close Logcat"}))
      vim.keymap.set("n", "c", function() M.clear() end, vim.tbl_extend("force", opts, {desc="Clear Logcat"}))
      vim.keymap.set("n", "f", function() M.change_filter() end, vim.tbl_extend("force", opts, {desc="Filter Logcat"}))
      vim.keymap.set("n", "l", function() M.change_level() end, vim.tbl_extend("force", opts, {desc="Log Level"}))
      vim.keymap.set("n", "a", function() M.toggle_app_filter() end, vim.tbl_extend("force", opts, {desc="Toggle App Filter"}))

      -- Also set mappings for Terminal mode so users don't have to exit terminal mode to use them
      -- Note: In terminal mode, `<C-\><C-n>` is required to escape before executing Lua functions.
      vim.keymap.set("t", "<C-q>", [[<C-\><C-n><cmd>close<CR>]], vim.tbl_extend("force", opts, {desc="Close Logcat"}))
      vim.keymap.set("t", "<C-c>", function() 
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        M.clear() 
      end, vim.tbl_extend("force", opts, {desc="Clear Logcat"}))
      vim.keymap.set("t", "<C-f>", function() 
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        M.change_filter() 
      end, vim.tbl_extend("force", opts, {desc="Filter Logcat"}))
      vim.keymap.set("t", "<C-l>", function() 
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        M.change_level() 
      end, vim.tbl_extend("force", opts, {desc="Log Level"}))
      vim.keymap.set("t", "<C-a>", function() 
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true), "n", false)
        M.toggle_app_filter() 
      end, vim.tbl_extend("force", opts, {desc="Toggle App Filter"}))
    end
  end)
end

function M.clear()
  local device = adb.ensure_device()
  if device then
    vim.fn.system({"adb", "-s", device, "logcat", "-c"})
    vim.notify("Logcat cleared", vim.log.levels.INFO)
    -- We must destroy the old terminal buffer so a new one spawns with the cleared logs
    if active_term then 
      active_term:close() 
      active_term = nil
    end
    M.toggle()
  end
end

function M.change_level()
  local levels = {"V (Verbose)", "D (Debug)", "I (Info)", "W (Warn)", "E (Error)", "F (Fatal)"}
  vim.ui.select(levels, { prompt = "Select Log Level:" }, function(choice)
    if choice then
      config.options.log_level = choice:sub(1,1)
      if active_term then 
        active_term:close() 
        active_term = nil
      end
      M.toggle()
    end
  end)
end

function M.change_filter()
  vim.ui.input({ prompt = "Filter logcat (regex): ", default = M.filter_text }, function(input)
    if input ~= nil then
      M.filter_text = input
      if active_term then 
        active_term:close() 
        active_term = nil
      end
      M.toggle()
    end
  end)
end

function M.toggle_app_filter()
  M.app_filtered = not M.app_filtered
  vim.notify("Filter by app PID: " .. tostring(M.app_filtered), vim.log.levels.INFO)
  if active_term then 
    active_term:close() 
    active_term = nil
  end
  M.toggle()
end

return M
