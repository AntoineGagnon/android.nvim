local M = {}

M.selected_device = nil

-- Gets a list of connected devices
function M.get_devices()
  local handle = io.popen("adb devices")
  if not handle then return {} end
  local result = handle:read("*a")
  handle:close()

  local devices = {}
  for line in result:gmatch("[^\r\n]+") do
    if not line:match("List of devices") and line ~= "" then
      local parts = {}
      for part in line:gmatch("%S+") do
        table.insert(parts, part)
      end
      if #parts >= 2 then
        table.insert(devices, { id = parts[1], state = parts[2] })
      end
    end
  end
  return devices
end

-- Selects a device using vim.ui.select
function M.select_device()
  local devices = M.get_devices()
  if #devices == 0 then
    vim.notify("No ADB devices found. Ensure a device is connected or emulator is running.", vim.log.levels.WARN)
    return
  end

  local options = {}
  for i, dev in ipairs(devices) do
    table.insert(options, string.format("%d: %s (%s)", i, dev.id, dev.state))
  end

  vim.ui.select(options, { prompt = "Select Android Device:" }, function(choice)
    if not choice then return end
    local index = tonumber(choice:match("^(%d+):"))
    if index and devices[index] then
      M.selected_device = devices[index].id
      vim.notify("Selected Android Device: " .. M.selected_device, vim.log.levels.INFO)
    end
  end)
end

-- Helper to ensure we have a device, if not auto-pick one or fail
function M.ensure_device()
  if M.selected_device then return M.selected_device end
  
  local devices = M.get_devices()
  if #devices == 1 then
    M.selected_device = devices[1].id
    vim.notify("Auto-selected only device: " .. M.selected_device, vim.log.levels.INFO)
    return M.selected_device
  elseif #devices > 1 then
    vim.notify("Multiple devices found. Please run :AndroidSelectDevice first.", vim.log.levels.ERROR)
    return nil
  end

  vim.notify("No ADB devices connected.", vim.log.levels.ERROR)
  return nil
end

-- List AVDs
function M.get_avds()
  local handle = io.popen("emulator -list-avds")
  if not handle then return {} end
  local result = handle:read("*a")
  handle:close()

  local avds = {}
  for line in result:gmatch("[^\r\n]+") do
    if line ~= "" then
      table.insert(avds, line)
    end
  end
  return avds
end

-- Start emulator asynchronously
function M.start_emulator()
  local avds = M.get_avds()
  if #avds == 0 then
    vim.notify("No AVDs found. Create one in Android Studio.", vim.log.levels.WARN)
    return
  end

  vim.ui.select(avds, { prompt = "Select AVD to Start:" }, function(choice)
    if not choice then return end
    vim.notify("Starting emulator: " .. choice, vim.log.levels.INFO)
    -- Fire and forget async process using vim.system or vim.fn.jobstart
    vim.fn.jobstart({"emulator", "-avd", choice}, {
      detach = true,
      on_exit = function(_, code)
        if code ~= 0 then
          vim.notify("Emulator " .. choice .. " exited with code " .. code, vim.log.levels.WARN)
        end
      end
    })
  end)
end

-- Get process ID for a package on the selected device
function M.get_pid(package_name, device_id)
  if not device_id then return nil end
  local cmd = string.format("adb -s %s shell pidof %s", device_id, package_name)
  local handle = io.popen(cmd)
  if not handle then return nil end
  local result = handle:read("*a")
  handle:close()
  local pid = result:match("%d+")
  return pid
end

return M
