---j@class tmux-send.keymaps
local M = {}

local config = require("tmux-send.config")
local tmux_send = require("tmux-send")

---@class TmuxSendKeymapDef
---@field lhs string Left-hand side of mapping
---@field rhs function Right-hand side function
---@field mode string|string[] Mode(s) for the mapping
---@field desc string Description

---Get default keymaps
---@param prefix string Keymap prefix
---@return table<string, TmuxSendKeymapDef>
local function get_default_keymaps(prefix)
  return {
    send = {
      lhs = prefix .. "s",
      rhs = function()
        tmux_send.send()
      end,
      mode = "n",
      desc = "Send",
    },
    send_visual = {
      lhs = prefix .. "s",
      rhs = "<Cmd>lua require('tmux-send').send()<CR>",
      mode = "x",
      desc = "Send selection",
    },
    select_pane = {
      lhs = prefix .. "p",
      rhs = function()
        tmux_send.select_pane(function(pane_id)
          if pane_id then
            tmux_send.send(nil, pane_id)
          end
        end)
      end,
      mode = { "n", "x" },
      desc = "Select pane and send",
    },
    send_path = {
      lhs = prefix .. "F",
      rhs = function()
        tmux_send.send_path()
      end,
      mode = "n",
      desc = "Send file paths",
    },
    send_current_file_path = {
      lhs = prefix .. "f",
      rhs = function()
        tmux_send.send_current_file_path()
      end,
      mode = "n",
      desc = "Send current file path",
    },
  }
end

---Setup keymaps based on configuration
function M.setup()
  local cfg = config.get()

  -- Skip if keymaps are disabled
  if cfg.keymaps == false then
    return
  end

  local prefix = cfg.keymap_prefix or "<leader>at"
  local keymaps = get_default_keymaps(prefix)

  -- If keymaps is a table, merge with defaults
  if type(cfg.keymaps) == "table" then
    for name, mapping in pairs(cfg.keymaps) do
      if mapping == false then
        -- Remove this keymap
        keymaps[name] = nil
      elseif type(mapping) == "string" and keymaps[name] then
        -- Override the lhs
        keymaps[name].lhs = mapping
      end
    end
  end

  -- Register all keymaps
  for _, keymap in pairs(keymaps) do
    local opts = {
      desc = keymap.desc,
      expr = keymap.expr,
    }
    -- Handle string rhs differently (for <Cmd> mappings)
    if type(keymap.rhs) == "string" then
      vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, opts)
    else
      vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, opts)
    end
  end
end

return M
