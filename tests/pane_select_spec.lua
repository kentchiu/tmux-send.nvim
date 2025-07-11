local tmux_send = require("tmux-send")
local pane = require("tmux-send.pane")
local sender = require("tmux-send.sender")
local util = require("tmux-send.util")
local stub = require("luassert.stub")

describe("pane selection", function()
  before_each(function()
    -- Mock tmux check
    stub(util, "in_tmux").returns(true)
  end)
  
  after_each(function()
    util.in_tmux:revert()
  end)

  it("should handle single pane", function()
    -- Mock pane list with single pane
    stub(pane, "list_panes").returns({
      { id = "%0", index = 0, title = "nvim", current = true, width = 80, height = 24 }
    })
    
    stub(vim, "notify")
    
    tmux_send.send("test")
    
    assert.stub(vim.notify).was_called_with(
      "[tmux-send] Only one pane in window, cannot send text", 
      vim.log.levels.ERROR
    )
    
    pane.list_panes:revert()
    vim.notify:revert()
  end)

  it("should auto-select with two panes", function()
    -- Mock pane list with two panes
    stub(pane, "list_panes").returns({
      { id = "%0", index = 0, title = "nvim", current = true, width = 80, height = 24 },
      { id = "%1", index = 1, title = "bash", current = false, width = 80, height = 24 }
    })
    
    stub(sender, "send_to_pane").returns(true)
    
    tmux_send.send("test")
    
    -- Should auto-select the non-current pane
    assert.stub(sender.send_to_pane).was_called_with("test", "%1")
    
    pane.list_panes:revert()
    sender.send_to_pane:revert()
  end)

  it("should show picker with multiple panes", function()
    -- Mock pane list with multiple panes
    stub(pane, "list_panes").returns({
      { id = "%0", index = 0, title = "nvim", current = true, width = 80, height = 24 },
      { id = "%1", index = 1, title = "bash", current = false, width = 80, height = 24 },
      { id = "%2", index = 2, title = "claude", current = false, width = 80, height = 24 }
    })
    
    -- Mock no last target
    stub(sender, "get_last_target").returns(nil)
    
    -- Mock Snacks picker
    local spy = require("luassert.spy")
    local snacks = { picker = { select = spy.new(function() end) } }
    package.loaded["snacks"] = snacks
    
    tmux_send.send("test")
    
    -- Should call picker
    assert.spy(snacks.picker.select).was_called()
    
    -- Check picker options
    local calls = snacks.picker.select.calls
    assert.equals(1, #calls)
    local call_args = calls[1].vals
    local panes_arg = call_args[1]
    assert.equals(2, #panes_arg) -- Should only show non-current panes
    assert.equals("%1", panes_arg[1].id)
    assert.equals("%2", panes_arg[2].id)
    
    pane.list_panes:revert()
    sender.get_last_target:revert()
    package.loaded["snacks"] = nil
  end)

  it("should display pane numbers when selecting", function()
    stub(pane, "list_panes").returns({
      { id = "%0", index = 0, title = "nvim", current = true, width = 80, height = 24 },
      { id = "%1", index = 1, title = "bash", current = false, width = 80, height = 24 },
      { id = "%2", index = 2, title = "claude", current = false, width = 80, height = 24 }
    })
    
    stub(util, "tmux_exec")
    
    -- Mock Snacks picker
    local spy = require("luassert.spy")
    local snacks = { picker = { select = spy.new(function() end) } }
    package.loaded["snacks"] = snacks
    
    tmux_send.select_pane()
    
    -- Should call tmux display-panes
    assert.stub(util.tmux_exec).was_called_with({ "display-panes", "-d", "1500" })
    
    -- Check picker format
    local calls = snacks.picker.select.calls
    local call_args = calls[1].vals
    local format_fn = call_args[2].format_item
    local formatted = format_fn({ id = "%1", index = 1, title = "bash" })
    assert.equals("Pane #1: bash [%1]", formatted)
    
    pane.list_panes:revert()
    util.tmux_exec:revert()
    package.loaded["snacks"] = nil
  end)
end)