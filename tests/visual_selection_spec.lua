local util = require("tmux-send.util")

describe("visual selection", function()
  describe("get_visual_selection", function()
    local original_mode, original_getpos
    
    before_each(function()
      -- Save original functions
      original_mode = vim.fn.mode
      original_getpos = vim.fn.getpos
      
      -- Create test buffer
      vim.cmd("new")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "START HERE |",
        "line1: 123 1 2 3 中文字 測試,中文 ABC"
      })
    end)
    
    after_each(function()
      -- Restore original functions
      vim.fn.mode = original_mode
      vim.fn.getpos = original_getpos
      
      -- Close test buffer
      vim.cmd("bdelete!")
    end)
    
    it("should handle test case 1: j4hv8l", function()
      -- Mock visual mode
      vim.fn.mode = function() return "v" end
      
      -- Mock positions: line 2, col 8 to col 16 (selecting "123 1 2 3")
      vim.fn.getpos = function(mark)
        if mark == "v" then
          return {0, 2, 8, 0}  -- start at "1" of "123"
        elseif mark == "." then
          return {0, 2, 16, 0} -- end at "3" of "2 3"
        end
      end
      
      local text = util.get_visual_selection()
      assert.equals("123 1 2 3", text)
    end)
    
    it("should handle test case 2: j6lv2l", function()
      -- Mock visual mode
      vim.fn.mode = function() return "v" end
      
      -- Mock positions: selecting "中文字"
      vim.fn.getpos = function(mark)
        if mark == "v" then
          return {0, 2, 18, 0}  -- start at "中"
        elseif mark == "." then
          return {0, 2, 26, 0}  -- end at "字" (byte position 24 + 3 - 1)
        end
      end
      
      local text = util.get_visual_selection()
      assert.equals("中文字", text)
    end)
    
    it("should handle test case 3: jv8l", function()
      -- Mock visual mode
      vim.fn.mode = function() return "v" end
      
      -- Mock positions: selecting "1 2 3 中文字"
      vim.fn.getpos = function(mark)
        if mark == "v" then
          return {0, 2, 12, 0}  -- start at "1"
        elseif mark == "." then
          return {0, 2, 26, 0}  -- end at "字" (byte position 24 + 3 - 1)
        end
      end
      
      local text = util.get_visual_selection()
      assert.equals("1 2 3 中文字", text)
    end)
  end)
end)