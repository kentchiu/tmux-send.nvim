---@class tmux-send.pane
local M = {}

local util = require("tmux-send.util")

---@class TmuxPane
---@field id string Pane identifier
---@field index integer Pane index
---@field title string Pane title
---@field current boolean Is current pane
---@field width integer Pane width
---@field height integer Pane height

---List all panes in current session
---@return TmuxPane[]
function M.list_panes()
  if not util.in_tmux() then
    return {}
  end
  
  local format = "#{pane_id}\t#{pane_index}\t#{pane_title}\t#{pane_active}\t#{pane_width}\t#{pane_height}"
  local output, err = util.tmux_exec({ "list-panes", "-F", format })
  
  if err then
    return {}
  end
  
  local panes = {}
  for _, line in ipairs(vim.split(output, "\n")) do
    if line ~= "" then
      local pane_info = util.parse_pane_info(line)
      if pane_info then
        table.insert(panes, pane_info)
      end
    end
  end
  
  return panes
end

---Find pane by ID
---@param pane_id string
---@return TmuxPane?
function M.find_pane(pane_id)
  local panes = M.list_panes()
  for _, pane in ipairs(panes) do
    if pane.id == pane_id then
      return pane
    end
  end
  return nil
end

---Get next pane
---@return TmuxPane?
function M.get_next_pane()
  local panes = M.list_panes()
  local current_idx = nil
  
  for i, pane in ipairs(panes) do
    if pane.current then
      current_idx = i
      break
    end
  end
  
  if current_idx and current_idx < #panes then
    return panes[current_idx + 1]
  elseif #panes > 1 then
    return panes[1]
  end
  
  return nil
end

---Get previous pane
---@return TmuxPane?
function M.get_previous_pane()
  local panes = M.list_panes()
  local current_idx = nil
  
  for i, pane in ipairs(panes) do
    if pane.current then
      current_idx = i
      break
    end
  end
  
  if current_idx and current_idx > 1 then
    return panes[current_idx - 1]
  elseif #panes > 1 then
    return panes[#panes]
  end
  
  return nil
end

---Get last active pane
---@return TmuxPane?
function M.get_last_pane()
  if not util.in_tmux() then
    return nil
  end
  
  local output, err = util.tmux_exec({ "display-message", "-p", "-t", "{last}", "#{pane_id}" })
  if err then
    return nil
  end
  
  local pane_id = vim.trim(output)
  return M.find_pane(pane_id)
end

return M