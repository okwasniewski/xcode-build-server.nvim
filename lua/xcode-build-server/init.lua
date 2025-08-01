local utils = require("xcode-build-server.utils")
local finder = require("xcode-build-server.finder")
local schemes = require("xcode-build-server.schemes")
local config = require("xcode-build-server.config")
local ui = require("xcode-build-server.ui")

local M = {}

function M.setup(opts)
  config.setup(opts)
  
  if config.get().auto_setup then
    M.auto_setup()
  end
end

function M.auto_setup()
  local cwd = vim.fn.getcwd()
  
  if finder.has_buildserver_json(cwd) then
    return
  end
  
  local project = finder.find_nearest_project()
  if not project then
    return
  end
  
  local scheme_list = schemes.list_schemes(project.path)
  local default_scheme = schemes.get_default_scheme(scheme_list)
  
  if default_scheme then
    local project_dir = config.get_project_root_for_buildserver(project.path)
    config.write_buildserver_config(project_dir, project.path, default_scheme)
    utils.info("Auto-configured xcode-build-server for %s:%s", project.name, default_scheme)
  end
end

function M.setup_interactive()
  local available, err = config.check_xcode_build_server()
  if not available then
    utils.error("xcode-build-server not found: %s", err)
    utils.info("Install with: brew install xcode-build-server")
    return
  end
  
  local projects = finder.find_xcode_projects(nil, config.get().search_depth)
  
  ui.select_project(projects, function(selected_project)
    local is_valid, validation_err = finder.validate_project(selected_project.path)
    if not is_valid then
      utils.error("Invalid project: %s", validation_err)
      return
    end
    
    ui.select_scheme(selected_project.path, function(selected_scheme)
      ui.confirm_setup(selected_project, selected_scheme, function(confirmed)
        if confirmed then
          local project_dir = config.get_project_root_for_buildserver(selected_project.path)
          local success = config.update_buildserver_config(project_dir, selected_project.path, selected_scheme)
          ui.show_setup_result(success, project_dir)
        end
      end)
    end)
  end)
end

function M.status()
  ui.show_status()
end

function M.restart_lsp()
  ui.restart_lsp_clients()
end

function M.health()
  local results = {}
  
  local available, version = config.check_xcode_build_server()
  table.insert(results, {
    name = "xcode-build-server availability",
    status = available and "OK" or "ERROR",
    message = available and ("Found: " .. version) or "Not found in PATH"
  })
  
  local cwd = vim.fn.getcwd()
  local has_buildserver = finder.has_buildserver_json(cwd)
  table.insert(results, {
    name = "buildServer.json",
    status = has_buildserver and "OK" or "WARN",
    message = has_buildserver and "Found in current directory" or "Not found - run :XcodeBuildServerSetup"
  })
  
  local project = finder.find_nearest_project()
  table.insert(results, {
    name = "Xcode project detection",
    status = project and "OK" or "WARN", 
    message = project and (project.name .. " (" .. project.type .. ")") or "No Xcode project found nearby"
  })
  
  if project then
    local scheme_list = schemes.list_schemes(project.path)
    table.insert(results, {
      name = "Scheme detection",
      status = #scheme_list > 0 and "OK" or "ERROR",
      message = #scheme_list > 0 and (table.concat(scheme_list, ", ")) or "No schemes found"
    })
  end
  
  return results
end

return M