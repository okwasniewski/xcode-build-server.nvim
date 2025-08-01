local utils = require("xcode-build-server.utils")

local M = {}

function M.list_schemes(project_path)
  if not utils.dir_exists(project_path) then
    utils.error("Project path does not exist: %s", project_path)
    return {}
  end
  
  local cmd
  if project_path:match("%.xcworkspace$") then
    cmd = string.format("xcodebuild -workspace '%s' -list", project_path)
  else
    cmd = string.format("xcodebuild -project '%s' -list", project_path)
  end
  
  local output, err = utils.execute_command(cmd, { timeout = 10000 })
  if not output then
    utils.error("Failed to list schemes: %s", err or "Unknown error")
    return {}
  end
  
  return M.parse_schemes_output(output)
end

function M.parse_schemes_output(output)
  local schemes = {}
  local in_schemes_section = false
  
  for line in output:gmatch("[^\r\n]+") do
    line = utils.trim(line)
    
    if line:match("^Schemes:") then
      in_schemes_section = true
    elseif in_schemes_section then
      if line == "" or line:match("^Build Configurations:") then
        break
      elseif not line:match("^Information about project") then
        table.insert(schemes, line)
      end
    end
  end
  
  return schemes
end

function M.get_default_scheme(schemes)
  if #schemes == 0 then
    return nil
  end
  
  for _, scheme in ipairs(schemes) do
    if scheme:lower():find("app") then
      return scheme
    end
  end
  
  return schemes[1]
end

function M.validate_scheme(project_path, scheme_name)
  local schemes = M.list_schemes(project_path)
  
  for _, scheme in ipairs(schemes) do
    if scheme == scheme_name then
      return true
    end
  end
  
  return false
end

function M.get_scheme_info(project_path, scheme_name)
  local cmd
  if project_path:match("%.xcworkspace$") then
    cmd = string.format("xcodebuild -workspace '%s' -scheme '%s' -showBuildSettings", 
                       project_path, scheme_name)
  else
    cmd = string.format("xcodebuild -project '%s' -scheme '%s' -showBuildSettings", 
                       project_path, scheme_name)
  end
  
  local output, err = utils.execute_command(cmd, { timeout = 15000 })
  if not output then
    utils.error("Failed to get scheme info: %s", err or "Unknown error")
    return nil
  end
  
  return M.parse_build_settings(output)
end

function M.parse_build_settings(output)
  local settings = {}
  
  for line in output:gmatch("[^\r\n]+") do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.+)$")
    if key and value then
      settings[key] = utils.trim(value)
    end
  end
  
  return settings
end

return M