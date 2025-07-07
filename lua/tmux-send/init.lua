---@class tmux-send
local M = {}

local loaded = false
local modules = {}

---Lazy load module
---@param name string
---@return table
local function load_module(name)
  if not modules[name] then
    modules[name] = require("tmux-send." .. name)
  end
  return modules[name]
end

---Lazy load private module
---@param name string
---@return table
local function load_private(name)
  local key = "private." .. name
  if not modules[key] then
    modules[key] = require("tmux-send.private." .. name)
  end
  return modules[key]
end

---Ensure plugin is loaded
local function ensure_loaded()
  if loaded then
    return
  end
  
  loaded = true
end

---Get target pane based on config or specified target
---@param target? string|integer
---@return string? pane_id
---@return string? error
local function resolve_target(target)
  local pane = load_private("pane")
  local sender = load_private("sender")
  local config = load_module("config").get()
  
  if target then
    if type(target) == "string" then
      if target:match("^%d+$") then
        return target
      end
      
      
      if target == "last" then
        local last_pane = pane.get_last_pane()
        if last_pane then
          return last_pane.id
        end
      elseif target == "next" then
        local next_pane = pane.get_next_pane()
        if next_pane then
          return next_pane.id
        end
      elseif target == "previous" then
        local prev_pane = pane.get_previous_pane()
        if prev_pane then
          return prev_pane.id
        end
      end
    end
  end
  
  local last_target = sender.get_last_target()
  if last_target then
    return last_target
  end
  
  if config.default_pane == "last" then
    local last_pane = pane.get_last_pane()
    if last_pane then
      return last_pane.id
    end
  elseif config.default_pane == "next" then
    local next_pane = pane.get_next_pane()
    if next_pane then
      return next_pane.id
    end
  elseif config.default_pane == "previous" then
    local prev_pane = pane.get_previous_pane()
    if prev_pane then
      return prev_pane.id
    end
  elseif config.default_pane then
    return tostring(config.default_pane)
  end
  
  return nil, "No target pane found"
end

---Send text to tmux pane
---@param text? string Text to send (default: current line/selection)
---@param target? string|integer Target pane (default: last used)
function M.send(text, target)
  ensure_loaded()
  local sender = load_private("sender")
  
  local pane_id, err = resolve_target(target)
  if not pane_id then
    vim.notify("[tmux-send] " .. (err or "No target pane"), vim.log.levels.ERROR)
    return
  end
  
  local success, send_err
  
  if text then
    success, send_err = sender.send_to_pane(text, pane_id)
  elseif vim.fn.mode() == "v" or vim.fn.mode() == "V" then
    success, send_err = sender.send_selection(pane_id)
  else
    success, send_err = sender.send_line(pane_id)
  end
  
  if not success then
    vim.notify("[tmux-send] " .. (send_err or "Failed to send"), vim.log.levels.ERROR)
  end
end

---Select target pane interactively
---@return string|nil pane_id
function M.select_pane()
  ensure_loaded()
  local pane = load_private("pane")
  local util = load_private("util")
  
  if not util.in_tmux() then
    vim.notify("[tmux-send] Not in tmux session", vim.log.levels.ERROR)
    return nil
  end
  
  local panes = pane.list_panes()
  if #panes == 0 then
    vim.notify("[tmux-send] No panes available", vim.log.levels.ERROR)
    return nil
  end
  
  local items = {}
  for _, p in ipairs(panes) do
    local label = string.format("%s [%d] %s", p.id, p.index, p.title)
    if p.current then
      label = label .. " *"
    end
    table.insert(items, label)
  end
  
  local choice = vim.fn.inputlist(items)
  if choice > 0 and choice <= #panes then
    return panes[choice].id
  end
  
  return nil
end


---Optional setup
---@param opts? TmuxSendConfig
function M.setup(opts)
  ensure_loaded()
  local config = load_module("config")
  config.set(opts)
end

return M