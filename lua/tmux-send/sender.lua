---@class tmux-send.sender
local M = {}

local util = require("tmux-send.util")

local last_target = nil

---Send text to pane
---@param text string Text to send
---@param target string Pane ID
---@param opts? table Options
---@return boolean success
---@return string? error
function M.send_to_pane(text, target, opts)
  opts = opts or {}
  local config = require("tmux-send.config").get()

  if not util.in_tmux() then
    return false, "Not in tmux session"
  end

  last_target = target

  local args = { "send-keys", "-t", target }

  if config.use_bracketed_paste and opts.use_bracketed_paste ~= false then
    -- Send bracketed paste start sequence
    args = { "send-keys", "-t", target, "Escape", "[200~" }
    util.tmux_exec(args)

    -- Send the actual text
    -- Use -- to prevent text starting with - from being interpreted as options
    args = { "send-keys", "-t", target, "-l", "--", text }
    local _, err = util.tmux_exec(args)
    if err then
      return false, err
    end

    -- Send bracketed paste end sequence
    args = { "send-keys", "-t", target, "Escape", "[201~" }
    util.tmux_exec(args)
  else
    table.insert(args, "-l")
    table.insert(args, "--")
    table.insert(args, text)
    local _, err = util.tmux_exec(args)
    if err then
      return false, err
    end
  end


  return true
end

---Get last used target
---@return string?
function M.get_last_target()
  return last_target
end

---Send current line
---@param target string
---@return boolean success
---@return string? error
function M.send_line(target)
  local line = vim.api.nvim_get_current_line()
  return M.send_to_pane(line, target)
end

---Send visual selection
---@param target string
---@return boolean success
---@return string? error
function M.send_selection(target)
  local text = util.get_visual_selection()
  if not text then
    return false, "Failed to get visual selection"
  end

  return M.send_to_pane(text, target)
end

---Send file path
---@param target string
---@param opts? table
---@return boolean success
---@return string? error
function M.send_file_path(target, opts)
  opts = opts or {}
  local path = vim.fn.expand(opts.expand or "%:p")
  return M.send_to_pane(path, target, { send_enter = false })
end

---Send multiple file paths
---@param paths string[] Array of file paths
---@param target string Pane ID
---@return boolean success
---@return string? error
function M.send_paths(paths, target)
  if not paths or #paths == 0 then
    return true
  end
  
  local text = table.concat(paths, "\n") .. "\n"
  return M.send_to_pane(text, target)
end

return M

