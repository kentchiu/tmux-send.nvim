local M = {}

-- Get all image files from /mnt/c/sharex/ directory
-- Returns a table of image paths sorted by timestamp (newest first)
function M.get_image_list()
  local sharex_dir = "/mnt/c/sharex/"
  local images = {}

  -- Check if directory exists
  if vim.fn.isdirectory(sharex_dir) == 0 then
    return images
  end

  -- Scan all MMDD subdirectories
  local subdirs = vim.fn.readdir(sharex_dir, function(name)
    return vim.fn.isdirectory(sharex_dir .. name) == 1
  end)

  for _, subdir in ipairs(subdirs) do
    -- Only process directories matching MMDD pattern
    if subdir:match("^%d%d%d%d$") then
      local subdir_path = sharex_dir .. subdir .. "/"
      local files = vim.fn.readdir(subdir_path, function(name)
        -- Match image files (png, jpg, jpeg, gif)
        return (name:match("%.png$") or name:match("%.jpe?g$") or name:match("%.gif$")) ~= nil
      end)

      for _, file in ipairs(files) do
        -- Extract timestamp from filename (hhmmss format)
        local hour, min, sec = file:match("^(%d%d)(%d%d)(%d%d)")
        if hour and min and sec then
          local full_path = subdir_path .. file
          local month = tonumber(subdir:sub(1, 2))
          local day = tonumber(subdir:sub(3, 4))

          -- Create a sortable timestamp
          local current_year = os.date("%Y")
          local timestamp = os.time({
            year = current_year,
            month = month,
            day = day,
            hour = tonumber(hour),
            min = tonumber(min),
            sec = tonumber(sec),
          })

          table.insert(images, {
            path = full_path,
            timestamp = timestamp,
            display = string.format("%02d/%02d %02d:%02d:%02d", month, day, hour, min, sec),
          })
        end
      end
    end
  end

  -- Sort by timestamp (newest first)
  table.sort(images, function(a, b)
    return a.timestamp > b.timestamp
  end)

  return images
end

-- Parse @IMAGE syntax and return the corresponding image path
-- @IMAGE or @IMAGE:-1 = latest image
-- @IMAGE:0 = first image, @IMAGE:1 = second image, etc.
function M.parse_image_syntax(text)
  local images = M.get_image_list()
  if #images == 0 then
    return text
  end

  -- Replace all @IMAGE patterns
  return text:gsub("@IMAGE:?([%-]?%d*)", function(index)
    local idx
    if index == "" or index == "-1" then
      idx = 1 -- Latest image
    else
      idx = tonumber(index) + 1 -- Convert 0-based to 1-based index
    end

    if idx > 0 and idx <= #images then
      return images[idx].path
    else
      return "@IMAGE" .. (index ~= "" and ":" .. index or "")
    end
  end)
end

-- Get relative time string (e.g., "2 hours ago")
function M.get_relative_time(timestamp)
  local now = os.time()
  local diff = now - timestamp

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. " min" .. (mins > 1 and "s" or "") .. " ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " hour" .. (hours > 1 and "s" or "") .. " ago"
  else
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days > 1 and "s" or "") .. " ago"
  end
end

-- Format image item for picker display
function M.format_image_item(image)
  -- Return directory/filename format (e.g., "0718/085014.png")
  local parts = vim.split(image.path, "/")
  if #parts >= 2 then
    return parts[#parts - 1] .. "/" .. parts[#parts]
  end
  return vim.fn.fnamemodify(image.path, ":t")
end

return M
