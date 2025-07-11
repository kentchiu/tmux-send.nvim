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
    table.insert(args, "-X")
    table.insert(args, "begin-selection")
    util.tmux_exec(args)

    args = { "send-keys", "-t", target, "-l", text }
    local _, err = util.tmux_exec(args)
    if err then
      return false, err
    end

    args = { "send-keys", "-t", target, "-X", "cancel" }
    util.tmux_exec(args)
  else
    table.insert(args, "-l")
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

return M

