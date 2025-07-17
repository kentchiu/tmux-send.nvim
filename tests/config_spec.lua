---@diagnostic disable: undefined-field
describe("tmux-send.config", function()
  local config

  before_each(function()
    package.loaded["tmux-send.config"] = nil
    config = require("tmux-send.config")
  end)

  it("should have default values", function()
    local cfg = config.get()
    assert.are.equal("last", cfg.default_pane)
    assert.are.equal(false, cfg.send_enter)
    assert.are.equal(true, cfg.use_bracketed_paste)
  end)

  it("should merge user config with defaults", function()
    config.set({
      default_pane = "next",
      send_enter = false,
    })

    local cfg = config.get()
    assert.are.equal("next", cfg.default_pane)
    assert.are.equal(false, cfg.send_enter)
    -- Should keep other defaults
    assert.are.equal(true, cfg.use_bracketed_paste)
  end)
end)
