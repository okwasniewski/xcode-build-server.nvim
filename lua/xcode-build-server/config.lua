local utils = require('xcode-build-server.utils')

local M = {}

M.defaults = {
  search_depth = 3,
  timeout = 10000,
  auto_setup = false,
  restart_lsp = true,
  build_server_path = 'xcode-build-server',
  picker = {
    -- Options: "vim_ui", "telescope", "fzf"
    backend = 'vim_ui',
    -- Optional telescope-specific options
    telescope = {
      theme = 'dropdown',
      layout_config = {
        width = 0.8,
        height = 0.6,
      },
    },
    -- Optional fzf-specific options
    fzf = {
      winopts = {
        width = 0.8,
        height = 0.6,
      },
    },
  },
}

local user_config = {}

function M.setup(opts)
  user_config = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

function M.get()
  return user_config
end

function M.generate_buildserver_config(project_path, scheme_name)
  local cmd_parts = { M.get().build_server_path, 'config' }

  if project_path:match('%.xcworkspace$') then
    table.insert(cmd_parts, '-workspace')
    table.insert(cmd_parts, string.format("'%s'", project_path))
  else
    table.insert(cmd_parts, '-project')
    table.insert(cmd_parts, string.format("'%s'", project_path))
  end

  if scheme_name then
    table.insert(cmd_parts, '-scheme')
    table.insert(cmd_parts, string.format("'%s'", scheme_name))
  end

  local cmd = table.concat(cmd_parts, ' ')
  utils.info('Running: %s', cmd)
  local output, err = utils.execute_command(cmd, { timeout = 15000 })

  if not output then
    utils.error('Failed to generate buildServer.json: %s', err or 'Unknown error')
    return nil
  end

  return utils.trim(output)
end

function M.run_buildserver_config(project_dir, project_path, scheme_name)
  local cmd_parts = { M.get().build_server_path, 'config' }

  if project_path:match('%.xcworkspace$') then
    table.insert(cmd_parts, '-workspace')
    table.insert(cmd_parts, string.format("'%s'", project_path))
  else
    table.insert(cmd_parts, '-project')
    table.insert(cmd_parts, string.format("'%s'", project_path))
  end

  if scheme_name then
    table.insert(cmd_parts, '-scheme')
    table.insert(cmd_parts, string.format("'%s'", scheme_name))
  end

  local cmd = table.concat(cmd_parts, ' ')

  -- Change to project directory and run the command
  local original_cwd = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(project_dir))

  utils.info('Running: %s (in %s)', cmd, project_dir)
  local output, err = utils.execute_command(cmd, { timeout = 15000 })

  -- Restore original directory
  vim.cmd('cd ' .. vim.fn.fnameescape(original_cwd))

  if not output then
    utils.error('Failed to generate buildServer.json: %s', err or 'Unknown error')
    return false
  end

  local config_file = utils.path_join(project_dir, 'buildServer.json')
  if utils.file_exists(config_file) then
    utils.info('Created buildServer.json: %s', config_file)
    return true
  else
    utils.error('buildServer.json was not created')
    return false
  end
end

function M.write_buildserver_config(project_dir, project_path, scheme_name)
  -- Use the direct command approach which is more reliable
  return M.run_buildserver_config(project_dir, project_path, scheme_name)
end

function M.update_buildserver_config(project_dir, project_path, scheme_name)
  local config_file = utils.path_join(project_dir, 'buildServer.json')

  if utils.file_exists(config_file) then
    local backup_file = config_file .. '.backup'
    local success = os.rename(config_file, backup_file)
    if success then
      utils.info('Backed up existing buildServer.json to %s', backup_file)
    end
  end

  return M.write_buildserver_config(project_dir, project_path, scheme_name)
end

function M.check_xcode_build_server()
  local cmd = M.get().build_server_path .. ' --version'
  local output, err = utils.execute_command(cmd, { ignore_errors = true })

  if err then
    return false, 'xcode-build-server not found in PATH'
  end

  return true, utils.trim(output or '')
end

function M.get_project_root_for_buildserver(project_path)
  if project_path:match('%.xcworkspace$') then
    return vim.fn.fnamemodify(project_path, ':h')
  else
    return vim.fn.fnamemodify(project_path, ':h')
  end
end

return M
