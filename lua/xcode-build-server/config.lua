local utils = require("xcode-build-server.utils")
local json = vim.fn.json_encode

local M = {}

M.defaults = {
  search_depth = 3,
  timeout = 10000,
  auto_setup = true,
  restart_lsp = true,
  build_server_path = "xcode-build-server",
}

local user_config = {}

function M.setup(opts)
  user_config = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get()
  return user_config
end

function M.generate_buildserver_config(project_path, scheme_name)
  local config = {
    name = "xcode-build-server",
    version = "1.0.0", 
    bspVersion = "2.0.0",
    languages = { "swift", "c", "cpp", "objective-c", "objective-cpp" },
    argv = {
      M.get().build_server_path,
      "build-server",
      "--project", project_path,
      "--scheme", scheme_name
    }
  }
  
  return json(config)
end

function M.write_buildserver_config(project_dir, project_path, scheme_name)
  local config_content = M.generate_buildserver_config(project_path, scheme_name)
  local config_file = utils.path_join(project_dir, "buildServer.json")
  
  local file = io.open(config_file, "w")
  if not file then
    utils.error("Failed to create buildServer.json: %s", config_file)
    return false
  end
  
  file:write(config_content)
  file:close()
  
  utils.info("Created buildServer.json: %s", config_file)
  return true
end

function M.update_buildserver_config(project_dir, project_path, scheme_name)
  local config_file = utils.path_join(project_dir, "buildServer.json")
  
  if utils.file_exists(config_file) then
    local backup_file = config_file .. ".backup"
    local success = os.rename(config_file, backup_file)
    if success then
      utils.info("Backed up existing buildServer.json to %s", backup_file)
    end
  end
  
  return M.write_buildserver_config(project_dir, project_path, scheme_name)
end

function M.check_xcode_build_server()
  local cmd = M.get().build_server_path .. " --version"
  local output, err = utils.execute_command(cmd, { ignore_errors = true })
  
  if err then
    return false, "xcode-build-server not found in PATH"
  end
  
  return true, utils.trim(output or "")
end

function M.get_project_root_for_buildserver(project_path)
  if project_path:match("%.xcworkspace$") then
    return vim.fn.fnamemodify(project_path, ":h")
  else
    return vim.fn.fnamemodify(project_path, ":h")
  end
end

return M