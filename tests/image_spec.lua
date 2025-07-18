local image = require("tmux-send.image")

describe("tmux-send.image", function()
  describe("parse_image_syntax", function()
    -- Mock get_image_list to return predictable results
    local original_get_image_list
    
    before_each(function()
      original_get_image_list = image.get_image_list
      image.get_image_list = function()
        return {
          { path = "/mnt/c/sharex/0718/143000.png", timestamp = 1721303400, display = "07/18 14:30:00" },
          { path = "/mnt/c/sharex/0718/142500.png", timestamp = 1721303100, display = "07/18 14:25:00" },
          { path = "/mnt/c/sharex/0718/142000.png", timestamp = 1721302800, display = "07/18 14:20:00" },
        }
      end
    end)
    
    after_each(function()
      image.get_image_list = original_get_image_list
    end)
    
    it("should replace @IMAGE with latest image", function()
      local result = image.parse_image_syntax("Check this @IMAGE")
      assert.equals("Check this /mnt/c/sharex/0718/143000.png", result)
    end)
    
    it("should replace @IMAGE:-1 with latest image", function()
      local result = image.parse_image_syntax("Latest: @IMAGE:-1")
      assert.equals("Latest: /mnt/c/sharex/0718/143000.png", result)
    end)
    
    it("should replace @IMAGE:0 with first image", function()
      local result = image.parse_image_syntax("First: @IMAGE:0")
      assert.equals("First: /mnt/c/sharex/0718/143000.png", result)
    end)
    
    it("should replace @IMAGE:1 with second image", function()
      local result = image.parse_image_syntax("Second: @IMAGE:1")
      assert.equals("Second: /mnt/c/sharex/0718/142500.png", result)
    end)
    
    it("should handle multiple @IMAGE patterns", function()
      local result = image.parse_image_syntax("Latest: @IMAGE, First: @IMAGE:0, Second: @IMAGE:1")
      assert.equals("Latest: /mnt/c/sharex/0718/143000.png, First: /mnt/c/sharex/0718/143000.png, Second: /mnt/c/sharex/0718/142500.png", result)
    end)
    
    it("should keep invalid indices unchanged", function()
      local result = image.parse_image_syntax("Invalid: @IMAGE:10")
      assert.equals("Invalid: @IMAGE:10", result)
    end)
    
    it("should handle empty image list", function()
      image.get_image_list = function() return {} end
      local result = image.parse_image_syntax("No images: @IMAGE")
      assert.equals("No images: @IMAGE", result)
    end)
  end)
  
  describe("get_relative_time", function()
    local current_time = os.time()
    
    it("should show 'just now' for recent timestamps", function()
      local result = image.get_relative_time(current_time - 30)
      assert.equals("just now", result)
    end)
    
    it("should show minutes for timestamps within an hour", function()
      local result = image.get_relative_time(current_time - 150)
      assert.equals("2 mins ago", result)
    end)
    
    it("should show hours for timestamps within a day", function()
      local result = image.get_relative_time(current_time - 7200)
      assert.equals("2 hours ago", result)
    end)
    
    it("should show days for older timestamps", function()
      local result = image.get_relative_time(current_time - 172800)
      assert.equals("2 days ago", result)
    end)
  end)
end)