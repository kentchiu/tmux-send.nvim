if vim.g.loaded_tmux_send then
  return
end
vim.g.loaded_tmux_send = 1

local function cmd_complete(arg_lead, cmd_line, cursor_pos)
  local subcmds = { "line", "pane", "mark", "to", "list", "history" }
  
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
  
  -- For "mark" and "to" subcommands, we could provide pane name completion
  local first_arg = after_cmd:match("^%s+(%S+)")
  if first_arg == "mark" or first_arg == "to" then
    -- TODO: In the future, we could return marked pane names
    return {}
  end
  
  return {}
end

vim.api.nvim_create_user_command("TmuxSend", function(opts)
  local tmux_send = require("tmux-send")
  local args = vim.split(opts.args, "%s+", { trimempty = true })
  
  if #args == 0 then
    tmux_send.send()
  elseif args[1] == "line" then
    tmux_send.send()
  elseif args[1] == "pane" then
    local pane_id = tmux_send.select_pane()
    if pane_id then
      tmux_send.send(nil, pane_id)
    end
  elseif args[1] == "mark" and args[2] then
    tmux_send.mark_pane(args[2])
  elseif args[1] == "to" and args[2] then
    local text = table.concat(vim.list_slice(args, 3), " ")
    if text == "" then
      text = nil
    end
    tmux_send.send(text, args[2])
  elseif args[1] == "list" then
    local pane = require("tmux-send.private.pane")
    local panes = pane.list_panes()
    for _, p in ipairs(panes) do
      local info = string.format("%s [%d] %s", p.id, p.index, p.title)
      if p.marked_as then
        info = info .. " (" .. p.marked_as .. ")"
      end
      if p.current then
        info = info .. " *"
      end
      print(info)
    end
  elseif args[1] == "history" then
    local sender = require("tmux-send.private.sender")
    local history = sender.get_history()
    for i, item in ipairs(history) do
      print(string.format("%d: %s -> %s", i, item.text:gsub("\n", "\\n"), item.target))
    end
  else
    vim.notify("[tmux-send] Unknown subcommand: " .. args[1], vim.log.levels.ERROR)
  end
end, {
  nargs = "*",
  range = true,
  complete = cmd_complete,
  desc = "Send text to tmux pane"
})

vim.keymap.set({ "n", "x" }, "<Plug>(TmuxSendLine)", function()
  require("tmux-send").send()
end, { desc = "Send current line to tmux" })

vim.keymap.set("x", "<Plug>(TmuxSendSelection)", function()
  require("tmux-send").send()
end, { desc = "Send selection to tmux" })

vim.keymap.set("n", "<Plug>(TmuxSendMotion)", function()
  vim.o.operatorfunc = "v:lua.require'tmux-send'.send_operator"
  return "g@"
end, { expr = true, desc = "Send motion to tmux" })

vim.keymap.set("n", "<Plug>(TmuxSelectPane)", function()
  local tmux_send = require("tmux-send")
  local pane_id = tmux_send.select_pane()
  if pane_id then
    tmux_send.send(nil, pane_id)
  end
end, { desc = "Select tmux pane" })

vim.keymap.set("n", "<Plug>(TmuxSendRepeat)", function()
  local sender = require("tmux-send.private.sender")
  local success, err = sender.repeat_last()
  if not success then
    vim.notify("[tmux-send] " .. err, vim.log.levels.ERROR)
  end
end, { desc = "Repeat last tmux send" })

_G.require("tmux-send").send_operator = function(motion_type)
  local tmux_send = require("tmux-send")
  local start_pos = vim.fn.getpos("'[")
  local end_pos = vim.fn.getpos("']")
  
  local lines
  if motion_type == "line" then
    lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
  else
    lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_pos[3], end_pos[3])
    elseif #lines > 1 then
      lines[1] = string.sub(lines[1], start_pos[3])
      lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
    end
  end
  
  local text = table.concat(lines, "\n")
  tmux_send.send(text)
end