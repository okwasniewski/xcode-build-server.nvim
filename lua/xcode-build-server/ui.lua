local utils = require('xcode-build-server.utils')
local finder = require('xcode-build-server.finder')
local schemes = require('xcode-build-server.schemes')
local config = require('xcode-build-server.config')
local picker = require('xcode-build-server.picker')

local M = {}

function M.select_project(projects, callback)
  if #projects == 0 then
    utils.error('No Xcode projects found')
    return
  end

  if #projects == 1 then
    callback(projects[1])
    return
  end

  local items = {}
  for i, project in ipairs(projects) do
    local display_name =
      string.format('[%s] %s (%s)', project.type:upper(), project.name, project.parent_dir)
    table.insert(items, {
      text = display_name,
      project = project,
      index = i,
    })
  end

  picker.select(items, {
    prompt = 'Select Xcode project:',
    format_item = function(item)
      return item.text
    end,
  }, function(selected)
    if selected then
      callback(selected.project)
    end
  end)
end

function M.select_scheme(project_path, callback)
  utils.info('Loading schemes for project...')

  local scheme_list = schemes.list_schemes(project_path)

  if #scheme_list == 0 then
    utils.error('No schemes found for project')
    return
  end

  if #scheme_list == 1 then
    callback(scheme_list[1])
    return
  end

  local default_scheme = schemes.get_default_scheme(scheme_list)

  picker.select(scheme_list, {
    prompt = 'Select scheme:',
    format_item = function(scheme)
      if scheme == default_scheme then
        return scheme .. ' (default)'
      end
      return scheme
    end,
  }, function(selected)
    if selected then
      callback(selected)
    end
  end)
end

function M.confirm_setup(project, scheme, callback)
  local prompt = string.format('Setup %s with scheme: %s? (y/N): ', project.name, scheme)

  vim.ui.input({
    prompt = prompt,
  }, function(input)
    local confirmed = input and input:lower():match('^y')
    callback(confirmed == 'y')
  end)
end

function M.show_setup_result(success, project_dir)
  if success then
    utils.info('Successfully configured xcode-build-server')

    if config.get().restart_lsp then
      M.prompt_lsp_restart()
    end
  else
    utils.error('Failed to configure xcode-build-server')
  end
end

function M.prompt_lsp_restart()
  vim.ui.input({
    prompt = 'Restart LSP clients to apply changes? (Y/n): ',
  }, function(input)
    local should_restart = not input or input:lower():match('^y') or input == ''
    if should_restart then
      M.restart_lsp_clients()
    end
  end)
end

function M.restart_lsp_clients()
  local clients = vim.lsp.get_active_clients()
  local restarted = 0

  for _, client in ipairs(clients) do
    if client.name == 'sourcekit' then
      utils.info('Restarting LSP client: %s', client.name)
      client.stop()
      restarted = restarted + 1
    end
  end

  if restarted > 0 then
    utils.info('Restarted %d LSP client(s)', restarted)
    vim.defer_fn(function()
      vim.cmd('edit!')
    end, 1000)
  else
    utils.info('No sourcekit LSP clients found to restart')
  end
end

function M.show_status()
  local cwd = vim.fn.getcwd()
  local has_buildserver = finder.has_buildserver_json(cwd)
  local xcode_available, version_info = config.check_xcode_build_server()

  local lines = {
    '=== xcode-build-server Status ===',
    '',
    string.format('Working directory: %s', cwd),
    string.format('buildServer.json: %s', has_buildserver and '✓ Found' or '✗ Not found'),
    string.format(
      'xcode-build-server: %s',
      xcode_available and '✓ Available' or '✗ Not available'
    ),
  }

  if xcode_available and version_info then
    table.insert(lines, string.format('Version: %s', version_info))
  end

  table.insert(lines, '')

  if has_buildserver then
    table.insert(lines, 'LSP should work with sourcekit-lsp')
  else
    table.insert(lines, 'Run :XcodeBuildServerSetup to configure')
  end

  vim.api.nvim_echo({ { table.concat(lines, '\n'), 'Normal' } }, false, {})
end

return M
