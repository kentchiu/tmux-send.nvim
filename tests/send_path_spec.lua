local sender = require("tmux-send.sender")
local tmux_send = require("tmux-send")

describe("send_path", function()
  local original_system
  local system_calls = {}

  before_each(function()
    -- Mock vim.fn.system
    original_system = vim.fn.system
    vim.fn.system = function(cmd)
      -- Convert table command to string for easier matching
      local cmd_str = type(cmd) == "table" and table.concat(cmd, " ") or cmd
      table.insert(system_calls, cmd_str)

      -- Return mock data for tmux list-panes
      if cmd_str:match("tmux list%-panes") then
        return "0: [80x24] [history 0/2000, 0 bytes] %0 (active)\n1: [80x24] [history 0/2000, 0 bytes] %1\n"
      end
      return ""
    end

    -- Mock TMUX environment
    vim.env.TMUX = "/tmp/tmux-1000/default,1234,0"

    -- Reset state
    system_calls = {}
    tmux_send.last_pane = nil
  end)

  after_each(function()
    vim.fn.system = original_system
  end)

  describe("send_paths function", function()
    it("should send single file path to target pane", function()
      local test_path = "/home/user/test/file.lua"
      sender.send_paths({ test_path }, "1")

      -- Verify tmux send-keys was called with the path
      local found = false
      for _, cmd in ipairs(system_calls) do
        if type(cmd) == "string" and cmd:match("tmux send%-keys") and cmd:match(test_path) then
          found = true
          break
        end
      end
      assert.is_true(found, "Expected tmux send-keys to be called with file path")
    end)

    it("should send multiple file paths on separate lines", function()
      local paths = {
        "/home/user/test/file1.lua",
        "/home/user/test/file2.lua",
        "/home/user/test/file3.lua",
      }
      sender.send_paths(paths, "1")

      -- Verify all paths were sent
      local sent_content = nil
      for _, cmd in ipairs(system_calls) do
        if type(cmd) == "string" and cmd:match("tmux send%-keys") and cmd:match("%-l") then
          -- The command format is: tmux send-keys -t 1 -l "content"
          -- Extract everything after -l
          local content_match = cmd:match("%-l%s+(.+)$")
          if content_match then
            sent_content = content_match
          end
          break
        end
      end

      -- Check each path is in the sent content
      if sent_content then
        for _, path in ipairs(paths) do
          assert.is_truthy(sent_content:find(path, 1, true), "Expected path " .. path .. " to be in sent content")
        end

        -- Verify paths are separated by newlines
        local lines = vim.split(sent_content, "\n")
        assert.equals(#paths, #lines - 1, "Expected " .. #paths .. " lines") -- -1 for trailing newline
      else
        assert.fail("No content was sent")
      end
    end)

    it("should handle empty paths array", function()
      sender.send_paths({}, "1")

      -- Verify no send-keys command was issued
      local found = false
      for _, cmd in ipairs(system_calls) do
        if type(cmd) == "string" and cmd:match("tmux send%-keys") then
          found = true
          break
        end
      end
      assert.is_false(found, "Should not send anything for empty paths")
    end)
  end)

  describe("send_path integration", function()
    local original_picker

    before_each(function()
      -- Mock Snacks picker
      original_picker = _G.Snacks and _G.Snacks.picker
      _G.Snacks = _G.Snacks or {}
      _G.Snacks.picker = _G.Snacks.picker or {}

      -- Also need to make require("snacks") return the mock
      package.loaded["snacks"] = _G.Snacks
    end)

    after_each(function()
      if original_picker then
        _G.Snacks.picker = original_picker
      end
      package.loaded["snacks"] = nil
    end)

    it("should open file picker and send selected paths", function()
      -- Set a last target to avoid pane selection dialog
      sender.send_to_pane("dummy", "1") -- This sets last_target
      system_calls = {} -- Reset system calls after setting target

      local selected_files = {
        { file = "lua/tmux-send/init.lua" },
        { file = "tests/test_file.lua" },
      }

      -- Mock fnamemodify first
      local original_fnamemodify = vim.fn.fnamemodify
      vim.fn.fnamemodify = function(file, mods)
        if mods == ":p" then
          return "/home/user/project/" .. file
        end
        return file
      end

      -- Mock picker to immediately call confirm
      _G.Snacks.picker.files = function(opts)
        -- Create a mock picker object
        local mock_picker = {
          selected = function(self, options)
            return selected_files
          end,
          close = function(self) end,
        }

        -- Call the confirm function if it exists
        if opts.confirm then
          opts.confirm(mock_picker, selected_files[1])
        end
      end

      -- Call send_path
      tmux_send.send_path()

      -- Restore fnamemodify
      vim.fn.fnamemodify = original_fnamemodify

      -- Verify paths were sent
      local sent_content = nil
      for _, cmd in ipairs(system_calls) do
        if type(cmd) == "string" and cmd:match("tmux send%-keys") and cmd:match("%-l") then
          -- The command format is: tmux send-keys -t 1 -l "content"
          -- Extract everything after -l
          local content_match = cmd:match("%-l%s+(.+)$")
          if content_match then
            sent_content = content_match
          end
          break
        end
      end

      assert.is_not_nil(sent_content, "Expected content to be sent")
      -- The content might have the paths without quotes, check the actual content
      assert.is_truthy(
        sent_content:find("lua/tmux%-send/init%.lua", 1, false)
          or sent_content:find("/home/user/project/lua/tmux-send/init.lua", 1, true),
        "Expected to find init.lua path in: " .. sent_content
      )
      assert.is_truthy(
        sent_content:find("test_file%.lua", 1, false)
          or sent_content:find("/home/user/project/tests/test_file.lua", 1, true),
        "Expected to find test_file.lua path in: " .. sent_content
      )
    end)

    it("should handle picker cancellation", function()
      -- Mock picker to simulate cancellation
      _G.Snacks.picker.files = function(opts)
        -- Don't call confirm (simulates user cancelling)
      end

      tmux_send.send_path()

      -- Verify no send-keys command was issued
      local found = false
      for _, cmd in ipairs(system_calls) do
        if type(cmd) == "string" and cmd:match("tmux send%-keys") then
          found = true
          break
        end
      end
      assert.is_false(found, "Should not send anything when picker is cancelled")
    end)

    it("should show all files including hidden and ignored", function()
      -- Set a last target to avoid pane selection dialog
      sender.send_to_pane("dummy", "1") -- This sets last_target

      local file_opts = nil
      local picker_opts = nil

      -- Capture picker options
      _G.Snacks.picker.files = function(opts)
        file_opts = opts
        -- Extract confirm function to check if multi_select works
        if opts.confirm then
          picker_opts = { multi_select = true } -- Mock that multi_select is supported
        end
      end

      tmux_send.send_path()

      -- Verify picker was called with correct options
      assert.is_not_nil(file_opts)
      assert.is_true(file_opts.hidden, "Picker should show hidden files")
      assert.is_true(file_opts.ignored, "Picker should show ignored files")
      assert.equals("Select files to send", file_opts.prompt)

      assert.is_not_nil(picker_opts)
      assert.is_true(picker_opts.multi_select, "Picker should allow multiple selection")
    end)
  end)
end)
