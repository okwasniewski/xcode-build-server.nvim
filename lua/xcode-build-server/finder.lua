local utils = require("xcode-build-server.utils")

local M = {}

function M.find_xcode_projects(search_path, max_depth)
  search_path = search_path or vim.fn.getcwd()
  max_depth = max_depth or 3
  
  local projects = {}
  
  local function scan_directory(path, current_depth)
    if current_depth > max_depth then
      return
    end
    
    local entries = vim.fn.readdir(path, function(name)
      local full_path = utils.path_join(path, name)
      return vim.fn.isdirectory(full_path) == 1
    end)
    
    for _, entry in ipairs(entries) do
      local full_path = utils.path_join(path, entry)
      
      if entry:match("%.xcodeproj$") then
        table.insert(projects, {
          type = "project",
          name = entry:gsub("%.xcodeproj$", ""),
          path = full_path,
          parent_dir = path
        })
      elseif entry:match("%.xcworkspace$") then
        table.insert(projects, {
          type = "workspace", 
          name = entry:gsub("%.xcworkspace$", ""),
          path = full_path,
          parent_dir = path
        })
      else
        scan_directory(full_path, current_depth + 1)
      end
    end
  end
  
  scan_directory(search_path, 0)
  
  table.sort(projects, function(a, b)
    if a.type ~= b.type then
      return a.type == "workspace"
    end
    return a.name < b.name
  end)
  
  return projects
end

function M.find_nearest_project(start_path)
  start_path = start_path or vim.fn.expand("%:p:h")
  local current = start_path
  
  while current ~= "/" do
    local projects = M.find_xcode_projects(current, 1)
    if #projects > 0 then
      return projects[1]
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  
  return nil
end

function M.validate_project(project_path)
  if not utils.dir_exists(project_path) then
    return false, "Project path does not exist"
  end
  
  local project_pbxproj = utils.path_join(project_path, "project.pbxproj")
  if not utils.file_exists(project_pbxproj) then
    return false, "Invalid Xcode project: missing project.pbxproj"
  end
  
  return true, nil
end

function M.has_buildserver_json(project_dir)
  return utils.file_exists(utils.path_join(project_dir, "buildServer.json"))
end

return M