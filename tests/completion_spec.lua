---@diagnostic disable: undefined-field, need-check-nil
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
    local expected = { "current-path", "line", "path", "select" }
    table.sort(results)
    table.sort(expected)
    assert.are.same(expected, results)
  end)

  it("should filter subcommands based on partial input", function()
    local results = cmd_complete("l", "TmuxSend l", 10)
    assert.are.same({ "line" }, results)
  end)

  it("should return empty when subcommand is complete with space", function()
    local results = cmd_complete("", "TmuxSend line ", 14)
    assert.are.same({}, results)
  end)

  it("should handle 's' prefix correctly", function()
    local results = cmd_complete("s", "TmuxSend s", 10)
    assert.are.same({ "select" }, results)
  end)

  it("should handle 'p' prefix correctly", function()
    local results = cmd_complete("p", "TmuxSend p", 10)
    -- Note: both "path" will match
    assert.are.same({ "path" }, results)
  end)

  it("should handle 'c' prefix correctly", function()
    local results = cmd_complete("c", "TmuxSend c", 10)
    assert.are.same({ "current-path" }, results)
  end)
end)
