describe("TmuxSend command completion", function()
  local cmd_complete

  before_each(function()
    -- Load the completion function
    package.loaded["tmux-send"] = nil
    package.loaded["tmux-send.init"] = nil

    -- We'll need to extract the completion function from the plugin file
    local plugin_content = vim.fn.readfile("plugin/tmux-send.lua")
    local completion_code = {}
    local in_completion = false

    for _, line in ipairs(plugin_content) do
      if line:match("^local function cmd_complete") then
        in_completion = true
      end

      if in_completion then
        table.insert(completion_code, line)
        if line:match("^end$") and not line:match("end,") then
          break
        end
      end
    end

    local code = table.concat(completion_code, "\n")
    local fn = loadstring(code .. "\nreturn cmd_complete")
    if fn then
      cmd_complete = fn()
    else
      error("Failed to load completion function")
    end
  end)

  it("should return all subcommands when no input after TmuxSend", function()
    local results = cmd_complete("", "TmuxSend ", 9)
    local expected = { "line", "pane", "mark", "to", "list", "history" }
    table.sort(results)
    table.sort(expected)
    assert.are.same(expected, results)
  end)

  it("should filter subcommands based on partial input", function()
    local results = cmd_complete("l", "TmuxSend l", 10)
    assert.are.same({ "line", "list" }, results)
  end)

  it("should filter subcommands for 'h' prefix", function()
    local results = cmd_complete("h", "TmuxSend h", 10)
    assert.are.same({ "history" }, results)
  end)

  it("should return empty when subcommand is complete with space", function()
    local results = cmd_complete("", "TmuxSend line ", 14)
    assert.are.same({}, results)
  end)

  it("should handle 'p' prefix correctly", function()
    local results = cmd_complete("p", "TmuxSend p", 10)
    assert.are.same({ "pane" }, results)
  end)

  it("should handle 'm' prefix correctly", function()
    local results = cmd_complete("m", "TmuxSend m", 10)
    assert.are.same({ "mark" }, results)
  end)

  it("should handle 't' prefix correctly", function()
    local results = cmd_complete("t", "TmuxSend t", 10)
    assert.are.same({ "to" }, results)
  end)
end)