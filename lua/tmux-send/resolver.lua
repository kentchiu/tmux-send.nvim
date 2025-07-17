---@class tmux-send.resolver
local M = {}

local config = require("tmux-send.config")
local pane = require("tmux-send.pane")
local sender = require("tmux-send.sender")

---Parse pane target string to determine target type
---@param target string
---@return string type "id"|"last"|"next"|"previous"|"unknown"
local function parse_target_type(target)
  if target:match("^%%?%d+$") then
    return "id"
  elseif target == "last" then
    return "last"
  elseif target == "next" then
    return "next"
  elseif target == "previous" then
    return "previous"
  end
  return "unknown"
end

---Get pane by relative position
---@param position "last"|"next"|"previous"
---@return string? pane_id
local function get_pane_by_position(position)
  local pane_func = {
    last = pane.get_last_pane,
    next = pane.get_next_pane,
    previous = pane.get_previous_pane,
  }

  local func = pane_func[position]
  if func then
    local target_pane = func()
    return target_pane and target_pane.id or nil
  end
  return nil
end

---Get target pane based on config or specified target
---@param target? string|integer
---@return string? pane_id
---@return string? error
function M.resolve_target(target)
  local cfg = config.get()

  -- Handle explicit target
  if target then
    if type(target) == "string" then
      local target_type = parse_target_type(target)

      if target_type == "id" then
        return target
      elseif target_type ~= "unknown" then
        local pane_id = get_pane_by_position(target_type)
        if pane_id then
          return pane_id
        end
      end
    end
  end

  -- Check for last used target
  local last_target = sender.get_last_target()
  if last_target then
    return last_target
  end

  -- Use default pane from config
  if cfg.default_pane then
    if type(cfg.default_pane) == "string" then
      local pane_id = get_pane_by_position(cfg.default_pane)
      if pane_id then
        return pane_id
      end
    else
      return tostring(cfg.default_pane)
    end
  end

  return nil, "No target pane found"
end

return M
