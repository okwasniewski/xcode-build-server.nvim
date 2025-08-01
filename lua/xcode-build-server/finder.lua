local utils = require('xcode-build-server.utils')

local M = {}

local function scan_directory(dir, pattern_lpeg, skip_dirs, current_depth, max_depth, projects)
  if current_depth > max_depth then
    return
  end

  local handle = vim.loop.fs_scandir(dir)
  if not handle then
    return
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end

    local full_path = utils.path_join(dir, name)

    if type == 'directory' then
      -- Skip unwanted directories
      local should_skip = false
      for _, skip_dir in ipairs(skip_dirs) do
        if name == skip_dir then
          should_skip = true
          break
        end
      end

      if not should_skip then
        -- Check if this directory matches our pattern
        local relative_path = full_path:sub(#vim.fn.getcwd() + 2) -- Remove cwd + '/'
        if pattern_lpeg:match(relative_path) then
          if name:match('%.xcodeproj$') then
            table.insert(projects, {
              type = 'project',
              name = name:gsub('%.xcodeproj$', ''),
              path = full_path,
              parent_dir = dir,
            })
          elseif name:match('%.xcworkspace$') then
            table.insert(projects, {
              type = 'workspace',
              name = name:gsub('%.xcworkspace$', ''),
              path = full_path,
              parent_dir = dir,
            })
          end
        else
          -- Recursively scan subdirectory
          scan_directory(full_path, pattern_lpeg, skip_dirs, current_depth + 1, max_depth, projects)
        end
      end
    end
  end
end

function M.find_xcode_projects(search_path, max_depth)
  search_path = search_path or vim.fn.getcwd()
  max_depth = max_depth or 10

  local projects = {}

  -- Directories to skip for performance
  local skip_dirs = {
    'node_modules',
    '.git',
    'build',
    'DerivedData',
    '.build',
    'Pods',
    'vendor',
    'target',
    'dist',
    'out',
  }

  -- Use vim.glob.to_lpeg for efficient pattern matching
  local pattern = '**/*.{xcodeproj,xcworkspace}'
  local pattern_lpeg = vim.glob.to_lpeg(pattern)

  scan_directory(search_path, pattern_lpeg, skip_dirs, 0, max_depth, projects)

  -- Remove duplicates and filter out xcodeproj when xcworkspace exists in same directory
  local seen = {}
  local unique_projects = {}
  local workspace_dirs = {}

  -- First pass: collect workspace directories
  for _, project in ipairs(projects) do
    if project.type == 'workspace' then
      workspace_dirs[project.parent_dir] = true
    end
  end

  -- Second pass: add projects, excluding xcodeproj if workspace exists in same directory
  for _, project in ipairs(projects) do
    local key = project.path
    if not seen[key] then
      -- Skip xcodeproj if workspace exists in same directory
      if project.type == 'project' and workspace_dirs[project.parent_dir] then
        goto continue
      end

      seen[key] = true
      table.insert(unique_projects, project)
    end
    ::continue::
  end

  table.sort(unique_projects, function(a, b)
    if a.type ~= b.type then
      return a.type == 'workspace'
    end
    return a.name < b.name
  end)

  return unique_projects
end

function M.find_nearest_project(start_path)
  start_path = start_path or vim.fn.expand('%:p:h')
  local current = start_path

  while current ~= '/' do
    local projects = M.find_xcode_projects(current, 1)
    if #projects > 0 then
      return projects[1]
    end
    current = vim.fn.fnamemodify(current, ':h')
  end

  return nil
end

function M.validate_project(project_path)
  if not utils.dir_exists(project_path) then
    return false, 'Project path does not exist'
  end

  if project_path:match('%.xcworkspace$') then
    -- Validate xcworkspace
    local contents_xcworkspacedata = utils.path_join(project_path, 'contents.xcworkspacedata')
    if not utils.file_exists(contents_xcworkspacedata) then
      return false, 'Invalid Xcode workspace: missing contents.xcworkspacedata'
    end
  else
    -- Validate xcodeproj
    local project_pbxproj = utils.path_join(project_path, 'project.pbxproj')
    if not utils.file_exists(project_pbxproj) then
      return false, 'Invalid Xcode project: missing project.pbxproj'
    end
  end

  return true, nil
end

function M.has_buildserver_json(project_dir)
  -- Check in root directory (where nvim is opened) instead of project directory
  local root_dir = vim.fn.getcwd()
  return utils.file_exists(utils.path_join(root_dir, 'buildServer.json'))
end

return M
