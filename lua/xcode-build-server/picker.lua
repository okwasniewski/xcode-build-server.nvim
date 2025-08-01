local config = require("xcode-build-server.config")
local utils = require("xcode-build-server.utils")

local M = {}

-- Check if a plugin is available
local function has_plugin(plugin_name)
  local ok, _ = pcall(require, plugin_name)
  return ok
end

-- Telescope picker implementation
local function telescope_select(items, opts, callback)
  if not has_plugin("telescope") then
    utils.error("Telescope is not available, falling back to vim.ui.select")
    return M.vim_ui_select(items, opts, callback)
  end
  
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  local picker_config = config.get().picker.telescope or {}
  local theme = picker_config.theme or "dropdown"
  local layout_config = picker_config.layout_config or {}
  
  local picker_opts = require("telescope.themes")["get_" .. theme](layout_config)
  picker_opts.prompt_title = opts.prompt or "Select"
  
  pickers.new(picker_opts, {
    finder = finders.new_table({
      results = items,
      entry_maker = function(entry)
        local display_text = opts.format_item and opts.format_item(entry) or tostring(entry)
        return {
          value = entry,
          display = display_text,
          ordinal = display_text,
        }
      end,
    }),
    sorter = conf.generic_sorter(picker_opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and callback then
          callback(selection.value)
        end
      end)
      return true
    end,
  }):find()
end

-- FZF-lua picker implementation
local function fzf_select(items, opts, callback)
  if not has_plugin("fzf-lua") then
    utils.error("fzf-lua is not available, falling back to vim.ui.select")
    return M.vim_ui_select(items, opts, callback)
  end
  
  local fzf_lua = require("fzf-lua")
  local picker_config = config.get().picker.fzf or {}
  
  local formatted_items = {}
  for i, item in ipairs(items) do
    local display_text = opts.format_item and opts.format_item(item) or tostring(item)
    table.insert(formatted_items, display_text)
  end
  
  local fzf_opts = vim.tbl_extend("force", {
    prompt = (opts.prompt or "Select") .. "> ",
    actions = {
      ["default"] = function(selected)
        if selected and #selected > 0 then
          -- Find the original item by matching the formatted text
          local selected_text = selected[1]
          for i, item in ipairs(items) do
            local display_text = opts.format_item and opts.format_item(item) or tostring(item)
            if display_text == selected_text then
              if callback then
                callback(item)
              end
              return
            end
          end
        end
      end,
    },
  }, picker_config.winopts or {})
  
  fzf_lua.fzf_exec(formatted_items, fzf_opts)
end

-- Default vim.ui.select implementation
function M.vim_ui_select(items, opts, callback)
  vim.ui.select(items, opts, callback)
end

-- Main select function that dispatches to the configured picker
function M.select(items, opts, callback)
  if not items or #items == 0 then
    utils.error("No items to select from")
    return
  end
  
  local picker_backend = config.get().picker.backend or "vim_ui"
  
  if picker_backend == "telescope" then
    telescope_select(items, opts, callback)
  elseif picker_backend == "fzf" then
    fzf_select(items, opts, callback)
  else
    M.vim_ui_select(items, opts, callback)
  end
end

return M