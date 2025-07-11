---@class tmux-send
local M = {}

local config = require("tmux-send.config")
local pane = require("tmux-send.pane")
local sender = require("tmux-send.sender")
local util = require("tmux-send.util")

---Get target pane based on config or specified target
---@param target? string|integer
---@return string? pane_id
---@return string? error
local function resolve_target(target)
  local cfg = config.get()

  if target then
    if type(target) == "string" then
      -- Check for tmux pane ID format (e.g., %19, %20) or plain number
      if target:match("^%%?%d+$") then
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

  if cfg.default_pane == "last" then
    local last_pane = pane.get_last_pane()
    if last_pane then
      return last_pane.id
    end
  elseif cfg.default_pane == "next" then
    local next_pane = pane.get_next_pane()
    if next_pane then
      return next_pane.id
    end
  elseif cfg.default_pane == "previous" then
    local prev_pane = pane.get_previous_pane()
    if prev_pane then
      return prev_pane.id
    end
  elseif cfg.default_pane then
    return tostring(cfg.default_pane)
  end

  return nil, "No target pane found"
end

---Send text to tmux pane
---@param text? string Text to send (default: current line/selection)
---@param target? string|integer Target pane (default: last used)
function M.send(text, target)
  -- 處理不同 pane 數量的情況
  local panes = pane.list_panes()
  local non_current_panes = vim.tbl_filter(function(p) return not p.current end, panes)
  
  if #panes == 1 then
    vim.notify("[tmux-send] Only one pane in window, cannot send text", vim.log.levels.ERROR)
    return
  elseif #non_current_panes == 1 and not target then
    -- 如果只有兩個 panes，自動選擇非當前的 pane
    target = non_current_panes[1].id
  elseif #non_current_panes > 1 and not target and not sender.get_last_target() then
    -- 多個 panes 且沒有指定 target 也沒有記錄過的 target，顯示選擇器
    M.select_pane(function(selected_pane_id)
      if selected_pane_id then
        M.send(text, selected_pane_id)
      end
    end)
    return
  end
  
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
---@param callback? fun(pane_id: string|nil) Optional callback function
---@return string|nil pane_id Only returns value when using synchronous method (inputlist)
function M.select_pane(callback)
  if not util.in_tmux() then
    vim.notify("[tmux-send] Not in tmux session", vim.log.levels.ERROR)
    if callback then callback(nil) end
    return nil
  end

  local panes = pane.list_panes()
  if #panes == 0 then
    vim.notify("[tmux-send] No panes available", vim.log.levels.ERROR)
    if callback then callback(nil) end
    return nil
  end
  
  -- 過濾掉當前 pane，只顯示其他 panes
  local target_panes = vim.tbl_filter(function(p) return not p.current end, panes)
  
  if #target_panes == 0 then
    vim.notify("[tmux-send] No other panes available in window", vim.log.levels.ERROR)
    if callback then callback(nil) end
    return nil
  end
  
  -- 顯示 tmux display-panes 來幫助使用者識別 pane
  util.tmux_exec({ "display-panes", "-d", "1500" }) -- 顯示 1.5 秒

  -- Try to use Snacks.nvim picker if available
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks.picker then
    Snacks.picker.select(target_panes, {
      prompt = "Select Target Pane",
      format_item = function(p)
        return string.format("Pane #%d: %s [%s]", p.index, p.title, p.id)
      end,
    }, function(item)
      local pane_id = item and item.id or nil
      if callback then
        callback(pane_id)
      else
        -- If no callback provided, still send directly for backward compatibility
        if pane_id then
          M.send(nil, pane_id)
        end
      end
    end)
    -- Return nil when using async picker
    return nil
  end

  -- Fallback to inputlist if Snacks is not available (synchronous)
  local items = {}
  for _, p in ipairs(target_panes) do
    local label = string.format("Pane #%d: %s [%s]", p.index, p.title, p.id)
    table.insert(items, label)
  end

  local choice = vim.fn.inputlist(items)
  local pane_id = nil
  if choice > 0 and choice <= #target_panes then
    pane_id = target_panes[choice].id
  end

  if callback then
    callback(pane_id)
  end
  
  return pane_id
end

---Optional setup
---@param opts? TmuxSendConfig
function M.setup(opts)
  config.set(opts)

  -- Setup keymaps after config is set
  local keymaps = require("tmux-send.keymaps")
  keymaps.setup()
end

return M
