local M = {}

function M.log(level, msg, ...)
  local formatted_msg = string.format(msg, ...)
  vim.notify("[xcode-build-server] " .. formatted_msg, level)
end

function M.error(msg, ...)
  M.log(vim.log.levels.ERROR, msg, ...)
end

function M.warn(msg, ...)
  M.log(vim.log.levels.WARN, msg, ...)
end

function M.info(msg, ...)
  M.log(vim.log.levels.INFO, msg, ...)
end

function M.debug(msg, ...)
  M.log(vim.log.levels.DEBUG, msg, ...)
end

function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

function M.dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
end

function M.path_join(...)
  local parts = { ... }
  local path = table.concat(parts, "/")
  return path:gsub("//+", "/")
end

function M.get_project_root(start_path)
  start_path = start_path or vim.fn.getcwd()
  local current = start_path
  
  while current ~= "/" do
    if M.file_exists(M.path_join(current, ".xcodeproj")) or 
       M.dir_exists(M.path_join(current, "*.xcodeproj")) or
       M.file_exists(M.path_join(current, ".xcworkspace")) or
       M.dir_exists(M.path_join(current, "*.xcworkspace")) then
      return current
    end
    current = vim.fn.fnamemodify(current, ":h")
  end
  
  return nil
end

function M.execute_command(cmd, opts)
  opts = opts or {}
  local timeout = opts.timeout or 5000
  
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code ~= 0 and not opts.ignore_errors then
    M.error("Command failed: %s (exit code: %d)", cmd, exit_code)
    return nil, result
  end
  
  return result, nil
end

function M.trim(str)
  return str:gsub("^%s*(.-)%s*$", "%1")
end

function M.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  
  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end
  
  return result
end

return M