---@diagnostic disable: undefined-field
local eq = assert.are.same

describe("tmux-send", function()
  local tmux_send

  before_each(function()
    -- Clear any loaded modules
    package.loaded["tmux-send"] = nil
    package.loaded["tmux-send.init"] = nil
    package.loaded["tmux-send.config"] = nil
    package.loaded["tmux-send.private.util"] = nil
    package.loaded["tmux-send.private.pane"] = nil
    package.loaded["tmux-send.private.sender"] = nil

    tmux_send = require("tmux-send")
  end)

  describe("setup", function()
    it("should accept configuration options", function()
      tmux_send.setup({
        default_pane = "next",
        send_enter = false,
        use_bracketed_paste = false,
      })

      local config = require("tmux-send.config").get()
      eq("next", config.default_pane)
      eq(false, config.send_enter)
      eq(false, config.use_bracketed_paste)
    end)

    it("should work without setup", function()
      -- Should not error when using without setup
      assert.has_no.errors(function()
        local config = require("tmux-send.config").get()
        eq("last", config.default_pane)
        eq(true, config.send_enter)
      end)
    end)
  end)

end)