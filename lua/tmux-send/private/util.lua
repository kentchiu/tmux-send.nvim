---@class tmux-send.private.util
local M = {}

---Check if running inside tmux
---@return boolean
function M.in_tmux()
  return vim.env.TMUX ~= nil
end

---Execute tmux command
---@param args string[] Command arguments
---@return string? stdout
---@return string? stderr
function M.tmux_exec(args)
  local cmd = vim.list_extend({ "tmux" }, args)
  local result = vim.fn.system(cmd)
  
  if vim.v.shell_error ~= 0 then
    return nil, result
  end
  
  return result, nil
end

---Get current tmux session
---@return string? session_name
function M.current_session()
  if not M.in_tmux() then
    return nil
  end
  
  local output, err = M.tmux_exec({ "display-message", "-p", "#{session_name}" })
  if err then
    return nil
  end
  
  return vim.trim(output)
end

---Get current pane id
---@return string? pane_id
function M.current_pane()
  if not M.in_tmux() then
    return nil
  end
  
  local output, err = M.tmux_exec({ "display-message", "-p", "#{pane_id}" })
  if err then
    return nil
  end
  
  return vim.trim(output)
end

---Parse pane info string
---@param info string
---@return table? pane_info
function M.parse_pane_info(info)
  local parts = vim.split(info, "\t")
  if #parts < 6 then
    return nil
  end
  
  return {
    id = parts[1],
    index = tonumber(parts[2]) or 0,
    title = parts[3],
    current = parts[4] == "1",
    width = tonumber(parts[5]) or 0,
    height = tonumber(parts[6]) or 0,
  }
end

return M