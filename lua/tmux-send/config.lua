---@class TmuxSendConfig
---@field default_pane? string|integer Default target pane
---@field send_enter? boolean Auto-append Enter
---@field use_bracketed_paste? boolean Use bracketed paste mode
---@field use_preview? boolean Use preview window for visual selection (default: true)
---@field keymaps? boolean|table<string, string|false> Enable default keymaps or custom mappings
---@field keymap_prefix? string Prefix for default keymaps (default: "<leader>t")

---@class tmux-send.config
local M = {}

---@type TmuxSendConfig
local default_config = {
  default_pane = "last",
  send_enter = false,
  use_bracketed_paste = true,
  use_preview = true,
  keymaps = true,
  keymap_prefix = "<leader>at",
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
