local utils = require('xcode-build-server.utils')

local M = {}

function M.find_xcode_projects(search_path, max_depth)
  search_path = search_path or vim.fn.getcwd()
  max_depth = max_depth or 3

  local projects = {}

  -- Use a single pattern that covers all depths
  local glob_patterns = {
    search_path .. '/**/*.xcodeproj',
    search_path .. '/**/*.xcworkspace',
  }

  for _, pattern in ipairs(glob_patterns) do
    local matches = vim.fn.glob(pattern, false, true)

    for _, match in ipairs(matches) do
      if vim.fn.isdirectory(match) == 1 then
        -- Skip if this is inside an .xcodeproj directory
        if match:find('%.xcodeproj/') then
          goto continue
        end

        -- Check if this project is within our max_depth
        local relative_path = match:sub(#search_path + 2) -- Remove search_path + '/'
        local depth = 0
        for _ in relative_path:gmatch('/') do
          depth = depth + 1
        end

        if depth <= max_depth then
          local name = vim.fn.fnamemodify(match, ':t')
          local parent_dir = vim.fn.fnamemodify(match, ':h')

          if name:match('%.xcodeproj$') then
            table.insert(projects, {
              type = 'project',
              name = name:gsub('%.xcodeproj$', ''),
              path = match,
              parent_dir = parent_dir,
            })
          elseif name:match('%.xcworkspace$') then
            table.insert(projects, {
              type = 'workspace',
              name = name:gsub('%.xcworkspace$', ''),
              path = match,
              parent_dir = parent_dir,
            })
          end
        end

        ::continue::
      end
    end
  end

  -- Remove duplicates
  local seen = {}
  local unique_projects = {}
  for _, project in ipairs(projects) do
    local key = project.path
    if not seen[key] then
      seen[key] = true
      table.insert(unique_projects, project)
    end
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

  local project_pbxproj = utils.path_join(project_path, 'project.pbxproj')
  if not utils.file_exists(project_pbxproj) then
    return false, 'Invalid Xcode project: missing project.pbxproj'
  end

  return true, nil
end

function M.has_buildserver_json(project_dir)
  return utils.file_exists(utils.path_join(project_dir, 'buildServer.json'))
end

return M
