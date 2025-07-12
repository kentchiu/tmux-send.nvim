---@class tmux-send
local M = {}

local config = require("tmux-send.config")
local actions = require("tmux-send.actions")

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
M.select_pane = actions.select_pane

return M
