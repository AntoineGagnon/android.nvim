local M = {}

-- Helper to read a file completely
local function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  return content
end

-- Memoize the app module path so we don't scan the disk on every command
local app_module_path = nil

function M.get_app_module_path()
  if app_module_path then return app_module_path end
  local cwd = vim.fn.getcwd()
  
  -- Search for build.gradle or build.gradle.kts recursively
  -- vim.fn.globpath with list=true returns a table of paths
  local gradle_files = vim.fn.globpath(cwd, "**/build.gradle*", false, true)
  for _, file in ipairs(gradle_files) do
    -- Ignore generated/build directories to speed up scanning
    if not file:match("/build/") and not file:match("/%.gradle/") then
      local content = read_file(file)
      -- The main app module either applies the application plugin or defines an applicationId
      if content and (content:match("com%.android%.application") or content:match("applicationId")) then
        app_module_path = vim.fn.fnamemodify(file, ":h")
        return app_module_path
      end
    end
  end

  -- Fallback: Look for an AndroidManifest.xml that contains the MAIN action
  local manifests = vim.fn.globpath(cwd, "**/AndroidManifest.xml", false, true)
  for _, file in ipairs(manifests) do
    if not file:match("/build/") then
      local content = read_file(file)
      if content and content:match("android%.intent%.action%.MAIN") then
        -- Go up 3 directories from /src/main/AndroidManifest.xml to get the module root
        app_module_path = vim.fn.fnamemodify(file, ":h:h:h")
        return app_module_path
      end
    end
  end

  -- Default fallback if nothing is found
  app_module_path = cwd .. "/app"
  return app_module_path
end

-- Tries to find applicationId in the dynamically detected module
function M.get_package_name()
  local module_path = M.get_app_module_path()
  
  -- Try finding in build.gradle
  local content = read_file(module_path .. "/build.gradle") or read_file(module_path .. "/build.gradle.kts")
  if content then
    local package_name = content:match('applicationId%s*=?%s*["\'](.-)["\']')
    if package_name then return package_name end
    
    local namespace = content:match('namespace%s*=?%s*["\'](.-)["\']')
    if namespace then return namespace end
  end

  -- Fallback to AndroidManifest.xml
  content = read_file(module_path .. "/src/main/AndroidManifest.xml")
  if content then
    local package_name = content:match('package=["\'](.-)["\']')
    if package_name then return package_name end
  end

  return nil
end

-- Tries to find the main launcher activity
function M.get_main_activity()
  local module_path = M.get_app_module_path()
  local content = read_file(module_path .. "/src/main/AndroidManifest.xml")
  if not content then return nil end

  -- We need to find an activity tag that contains the intent-filter for MAIN and LAUNCHER
  for activity in content:gmatch('<activity(.-)</activity>') do
    if activity:match('android%.intent%.action%.MAIN') and activity:match('android%.intent%.category%.LAUNCHER') then
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
