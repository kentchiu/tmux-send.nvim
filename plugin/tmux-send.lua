if vim.g.loaded_tmux_send then
  return
end
vim.g.loaded_tmux_send = 1

-- Load modules at startup for better LSP support
local pane = require("tmux-send.pane")
local tmux_send = require("tmux-send")

local function cmd_complete(arg_lead, cmd_line, cursor_pos)
  local subcmds = { "line", "select", "path" }

  -- Parse the command line to get arguments after "TmuxSend"
  local cmd_start = cmd_line:find("TmuxSend")
  if not cmd_start then
    return {}
  end

  -- Get everything after "TmuxSend"
  local after_cmd = cmd_line:sub(cmd_start + 8)

  -- Count spaces to determine if we're on first argument
  local _, space_count = after_cmd:gsub("%s", "")

  -- If no spaces or still typing first word (arg_lead matches what's after TmuxSend)
  if space_count == 0 or (space_count == 1 and after_cmd:match("^%s+(%S*)$") == arg_lead) then
    return vim.tbl_filter(function(cmd)
      return vim.startswith(cmd, arg_lead)
    end, subcmds)
  end

  return {}
end

vim.api.nvim_create_user_command("TmuxSend", function(opts)
  local args = vim.split(opts.args, "%s+", { trimempty = true })

  -- Handle visual range selection
  if opts.range > 0 then
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local text = table.concat(lines, "\n")
    tmux_send.send(text)
    return
  end

  if #args == 0 then
    tmux_send.send()
  elseif args[1] == "line" then
    tmux_send.send()
  elseif args[1] == "select" then
    tmux_send.select_pane()
  elseif args[1] == "path" then
    tmux_send.send_path()
  else
    vim.notify("[tmux-send] Unknown subcommand: " .. args[1], vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  range = true,
  complete = cmd_complete,
  desc = "Send text to tmux pane",
})

vim.keymap.set({ "n", "x" }, "<Plug>(TmuxSendLine)", function()
  tmux_send.send()
end, { desc = "Send current line to tmux" })

vim.keymap.set("x", "<Plug>(TmuxSendSelection)", "<Cmd>lua require('tmux-send').send()<CR>", { desc = "Send selection to tmux" })

vim.keymap.set("n", "<Plug>(TmuxSelectPane)", function()
  tmux_send.select_pane(function(pane_id)
    if pane_id then
      tmux_send.send(nil, pane_id)
    end
  end)
end, { desc = "Select tmux pane" })

vim.keymap.set("n", "<Plug>(TmuxSendPath)", function()
  tmux_send.send_path()
end, { desc = "Send file paths to tmux" })
