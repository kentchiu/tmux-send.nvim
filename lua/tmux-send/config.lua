---@class TmuxSendConfig
---@field default_pane? string|integer Default target pane
---@field send_enter? boolean Auto-append Enter
---@field use_bracketed_paste? boolean Use bracketed paste mode
---@field selector? TmuxSendSelectorConfig Pane selector options
---@field templates? table<string, string> Text templates

---@class TmuxSendSelectorConfig
---@field prefer_telescope? boolean Use telescope if available
---@field show_preview? boolean Show pane content preview

---@class tmux-send.config
local M = {}

---@type TmuxSendConfig
local default_config = {
  default_pane = "last",
  send_enter = true,
  use_bracketed_paste = true,
  selector = {
    prefer_telescope = true,
    show_preview = true,
  },
  templates = {},
}

---@type TmuxSendConfig
local config = {}

---Get configuration
---@return TmuxSendConfig
function M.get()
  return config
end

---Set configuration
---@param opts? TmuxSendConfig
function M.set(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
end

---Initialize with defaults
M.set({})

return M