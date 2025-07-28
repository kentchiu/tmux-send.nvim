---@class tmux-send.preview
local M = {}

local config = require("tmux-send.config")

---Show preview window with editable content
---@param content string Content to preview
---@param callback fun(edited_content: string|nil) Callback with edited content (nil if cancelled)
function M.show_preview(content, callback)
  local ok, Snacks = pcall(require, "snacks")
  if not ok or not Snacks.win then
    -- Fallback: directly send without preview if Snacks is not available
    callback(content)
    return
  end

  -- Create a scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].modifiable = true

  -- Create floating window with Snacks
  local win = Snacks.win({
    buf = buf,
    title = " Preview - Edit and Press <CR> to Send or <Esc> to Cancel ",
    border = "rounded",
    width = 0.8,
    height = 0.8,
    wo = {
      wrap = true,
      linebreak = true,
      cursorline = true,
    },
  })

  -- Set up keymaps for the preview window
  local function close_and_send()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local edited_content = table.concat(lines, "\n")
    win:close()
    callback(edited_content)
  end

  local function close_and_cancel()
    win:close()
    callback(nil)
  end

  -- Buffer-local keymaps
  vim.keymap.set("n", "<CR>", close_and_send, { buffer = buf, nowait = true })
  vim.keymap.set("n", "<Esc>", close_and_cancel, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close_and_cancel, { buffer = buf, nowait = true })
  
  -- Also support sending with <C-s>
  vim.keymap.set({ "n", "i" }, "<C-s>", close_and_send, { buffer = buf, nowait = true })

  -- Focus the window
  vim.api.nvim_set_current_win(win.win)
end

return M