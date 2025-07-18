---@class tmux-send.actions
local M = {}

local image = require("tmux-send.image")
local pane = require("tmux-send.pane")
local resolver = require("tmux-send.resolver")
local sender = require("tmux-send.sender")
local util = require("tmux-send.util")

---Handle pane selection for multi-pane scenarios
---@param callback fun(pane_id: string|nil)
---@param target? string|integer
---@return boolean should_continue
local function handle_pane_selection(callback, target)
  local panes = pane.list_panes()
  local non_current_panes = vim.tbl_filter(function(p)
    return not p.current
  end, panes)

  if #panes == 1 then
    vim.notify("[tmux-send] Only one pane in window, cannot send text", vim.log.levels.ERROR)
    return false
  elseif #non_current_panes == 1 and not target then
    -- Auto-select the only other pane
    callback(non_current_panes[1].id)
    return false
  elseif #non_current_panes > 1 and not target and not sender.get_last_target() then
    -- Show pane selector
    M.select_pane(callback)
    return false
  end

  return true
end

---Send text to tmux pane
---@param text? string Text to send (default: current line/selection)
---@param target? string|integer Target pane (default: last used)
function M.send(text, target)
  if
    not handle_pane_selection(function(selected_pane_id)
      if selected_pane_id then
        M.send(text, selected_pane_id)
      end
    end, target)
  then
    return
  end

  local pane_id, err = resolver.resolve_target(target)
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

---Send current file path to tmux pane
---@param target? string|integer Target pane (default: last used)
function M.send_current_file_path(target)
  if
    not handle_pane_selection(function(selected_pane_id)
      if selected_pane_id then
        M.send_current_file_path(selected_pane_id)
      end
    end, target)
  then
    return
  end

  local pane_id, err = resolver.resolve_target(target)
  if not pane_id then
    vim.notify("[tmux-send] " .. (err or "No target pane"), vim.log.levels.ERROR)
    return
  end

  local success, send_err = sender.send_file_path(pane_id)
  if not success then
    vim.notify("[tmux-send] " .. (send_err or "Failed to send current file path"), vim.log.levels.ERROR)
  end
end

---Send file paths to tmux pane
---@param target? string|integer Target pane (default: last used)
function M.send_path(target)
  if
    not handle_pane_selection(function(selected_pane_id)
      if selected_pane_id then
        M.send_path(selected_pane_id)
      end
    end, target)
  then
    return
  end

  local pane_id, err = resolver.resolve_target(target)
  if not pane_id then
    vim.notify("[tmux-send] " .. (err or "No target pane"), vim.log.levels.ERROR)
    return
  end

  -- Try to use Snacks.nvim file picker if available
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks.picker then
    Snacks.picker.files({
      hidden = true,
      ignored = true,
      confirm = function(picker, item)
        -- Get all selected items, fallback to current item if none selected
        local selected_items = picker:selected({ fallback = true })

        -- Close the picker
        picker:close()

        -- Convert items to absolute paths
        local paths = {}
        for _, selected_item in ipairs(selected_items) do
          if selected_item and selected_item.file then
            local abs_path = vim.fn.fnamemodify(selected_item.file, ":p")
            table.insert(paths, abs_path)
          end
        end

        if #paths == 0 then
          vim.notify("[tmux-send] No files selected", vim.log.levels.WARN)
          return
        end

        -- Send paths to pane
        local success, send_err = sender.send_paths(paths, pane_id)
        if not success then
          vim.notify("[tmux-send] " .. (send_err or "Failed to send paths"), vim.log.levels.ERROR)
        end
      end,
    })
  else
    vim.notify("[tmux-send] Snacks.nvim is required for file picker", vim.log.levels.ERROR)
  end
end

---Select target pane interactively
---@param callback? fun(pane_id: string|nil) Optional callback function
---@return string|nil pane_id Only returns value when using synchronous method (inputlist)
function M.select_pane(callback)
  if not util.in_tmux() then
    vim.notify("[tmux-send] Not in tmux session", vim.log.levels.ERROR)
    if callback then
      callback(nil)
    end
    return nil
  end

  local panes = pane.list_panes()
  if #panes == 0 then
    vim.notify("[tmux-send] No panes available", vim.log.levels.ERROR)
    if callback then
      callback(nil)
    end
    return nil
  end

  -- Filter out current pane
  local target_panes = vim.tbl_filter(function(p)
    return not p.current
  end, panes)

  if #target_panes == 0 then
    vim.notify("[tmux-send] No other panes available in window", vim.log.levels.ERROR)
    if callback then
      callback(nil)
    end
    return nil
  end

  -- Show tmux display-panes to help users identify panes
  util.tmux_exec({ "display-panes", "-d", "1500" })

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

---Send image paths to tmux pane
---@param target? string|integer Target pane (default: last used)
function M.send_image_paths(target)
  if
    not handle_pane_selection(function(selected_pane_id)
      if selected_pane_id then
        M.send_image_paths(selected_pane_id)
      end
    end, target)
  then
    return
  end

  local pane_id, err = resolver.resolve_target(target)
  if not pane_id then
    vim.notify("[tmux-send] " .. (err or "No target pane"), vim.log.levels.ERROR)
    return
  end

  -- Get all image files
  local images = image.get_image_list()
  if #images == 0 then
    vim.notify("[tmux-send] No images found in /mnt/c/sharex/", vim.log.levels.WARN)
    return
  end

  -- Try to use Snacks.nvim picker if available
  local ok, Snacks = pcall(require, "snacks")
  if ok and Snacks.picker then
    -- Create custom items for picker
    local picker_items = {}
    for _, img in ipairs(images) do
      -- Create item with 'file' property to match files picker pattern
      table.insert(picker_items, {
        file = img.path,
        display = image.format_image_item(img),
      })
    end

    -- Create a custom picker similar to files picker
    local CustomImagePicker = {
      items = picker_items,
      prompt = "Select images to send",
      format_item = function(item)
        return item.display or vim.fn.fnamemodify(item.file, ":t")
      end,
      confirm = function(picker, item)
        -- Get all selected items, fallback to current item if none selected
        local selected_items = picker:selected({ fallback = true })

        -- Close the picker
        picker:close()

        -- Extract paths from selected items
        local paths = {}
        for _, selected_item in ipairs(selected_items) do
          if selected_item and selected_item.file then
            table.insert(paths, selected_item.file)
          end
        end

        if #paths == 0 then
          vim.notify("[tmux-send] No images selected", vim.log.levels.WARN)
          return
        end

        -- Send paths to pane
        local success, send_err = sender.send_paths(paths, pane_id)
        if not success then
          vim.notify("[tmux-send] " .. (send_err or "Failed to send image paths"), vim.log.levels.ERROR)
        end
      end,
    }
    
    -- Create and open the picker
    Snacks.picker(CustomImagePicker)
  else
    -- Fallback to inputlist if Snacks is not available
    local items = {}
    for i, img in ipairs(images) do
      table.insert(items, string.format("%d. %s", i, image.format_image_item(img)))
    end

    local choice = vim.fn.inputlist(items)
    if choice > 0 and choice <= #images then
      local success, send_err = sender.send_paths({ images[choice].path }, pane_id)
      if not success then
        vim.notify("[tmux-send] " .. (send_err or "Failed to send image path"), vim.log.levels.ERROR)
      end
    end
  end
end

---Send text with @IMAGE syntax replacement
---@param text string Text containing @IMAGE patterns
---@param target? string|integer Target pane (default: last used)
function M.send_with_images(text, target)
  -- Parse @IMAGE syntax
  local parsed_text = image.parse_image_syntax(text)

  -- Send the parsed text
  M.send(parsed_text, target)
end

return M
