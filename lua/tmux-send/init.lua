---@class tmux-send
local M = {}

local actions = require("tmux-send.actions")
local config = require("tmux-send.config")

---Optional setup
---@param opts? TmuxSendConfig
function M.setup(opts)
  config.set(opts)

  -- Setup keymaps after config is set
  local keymaps = require("tmux-send.keymaps")
  keymaps.setup()
end

-- Delegate all actions to the actions module
M.send = actions.send
M.send_path = actions.send_path
M.send_current_file_path = actions.send_current_file_path
M.select_pane = actions.select_pane

return M
