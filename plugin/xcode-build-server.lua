if vim.g.loaded_xcode_build_server then
  return
end
vim.g.loaded_xcode_build_server = 1

local xcode_build_server = require('xcode-build-server')

vim.api.nvim_create_user_command('XcodeBuildServerSetup', function()
  xcode_build_server.setup_interactive()
end, {
  desc = 'Setup xcode-build-server for the current project',
})

vim.api.nvim_create_user_command('XcodeBuildServerStatus', function()
  xcode_build_server.status()
end, {
  desc = 'Show xcode-build-server status',
})

vim.api.nvim_create_user_command('XcodeBuildServerRestart', function()
  xcode_build_server.restart_lsp()
end, {
  desc = 'Restart LSP clients',
})
