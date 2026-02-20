local M = {}

-- Helper to read a file completely
local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

-- Tries to find applicationId in app/build.gradle or app/build.gradle.kts
function M.get_package_name()
  local cwd = vim.fn.getcwd()
  
  -- Try finding in build.gradle
  local content = read_file(cwd .. "/app/build.gradle") or read_file(cwd .. "/app/build.gradle.kts")
  if content then
    local package_name = content:match('applicationId%s*=?%s*["\'](.-)["\']')
    if package_name then return package_name end
    
    local namespace = content:match('namespace%s*=?%s*["\'](.-)["\']')
    if namespace then return namespace end
  end

  -- Fallback to AndroidManifest.xml
  content = read_file(cwd .. "/app/src/main/AndroidManifest.xml")
  if content then
    local package_name = content:match('package=["\'](.-)["\']')
    if package_name then return package_name end
  end

  return nil
end

-- Tries to find the main launcher activity
function M.get_main_activity()
  local cwd = vim.fn.getcwd()
  local content = read_file(cwd .. "/app/src/main/AndroidManifest.xml")
  if not content then return nil end

  -- We need to find an activity tag that contains the intent-filter for MAIN and LAUNCHER
  -- This is a naive regex-based XML parsing, but usually sufficient for standard Android apps.
  for activity in content:gmatch('<activity(.-)</activity>') do
    if activity:match('android.intent.action.MAIN') and activity:match('android.intent.category.LAUNCHER') then
      local name = activity:match('android:name=["\'](.-)["\']')
      -- Handle relative activity names (e.g., ".MainActivity")
      if name and name:sub(1,1) == "." then
        local package_name = M.get_package_name()
        if package_name then
          name = package_name .. name
        end
      end
      return name
    end
  end
  return nil
end

return M
