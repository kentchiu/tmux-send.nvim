---@class tmux-send.util
local M = {}

---@class TmuxPane
---@field id string Pane identifier
---@field index integer Pane index
---@field title string Pane title
---@field current boolean Is current pane
---@field width integer Pane width
---@field height integer Pane height

---Check if running inside tmux
---@return boolean
function M.in_tmux()
  return vim.env.TMUX ~= nil
end

---Execute tmux command
---@param args string[] Command arguments
---@return string? stdout
---@return string? stderr
function M.tmux_exec(args)
  local cmd = vim.list_extend({ "tmux" }, args)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    return nil, result
  end

  return result, nil
end

---Get current tmux session
---@return string? session_name
function M.current_session()
  if not M.in_tmux() then
    return nil
  end

  local output, err = M.tmux_exec({ "display-message", "-p", "#{session_name}" })
  if err then
    return nil
  end

  return vim.trim(output)
end

---Get current pane id
---@return string? pane_id
function M.current_pane()
  if not M.in_tmux() then
    return nil
  end

  local output, err = M.tmux_exec({ "display-message", "-p", "#{pane_id}" })
  if err then
    return nil
  end

  return vim.trim(output)
end

---Parse pane info string
---@param info string
---@return TmuxPane?
function M.parse_pane_info(info)
  local parts = vim.split(info, "\t")
  if #parts < 6 then
    return nil
  end

  return {
    id = parts[1],
    index = tonumber(parts[2]) or 0,
    title = parts[3],
    current = parts[4] == "1",
    width = tonumber(parts[5]) or 0,
    height = tonumber(parts[6]) or 0,
  }
end

--- 記錄訊息
---@param message string|table 要記錄的訊息
---@param level? string 日誌級別: TRACE | DEBUG | INFO | WARN | ERROR | OFF, 預設 INFO
function M.log(message, level)
  -- 獲取配置的日誌級別
  -- 如果無法獲取調用者資訊，提供一個預設值
  -- Snacks.debug.log(string.format("UNKNOWN:? %s\t%s", message_level_str, message))
  -- end

  -- local source = info.source:gsub("^@", "")
  -- local path_part, filename_part = string.match(source, "(.-)([^/]+)$")
  -- local name_part, ext_part = string.match(filename_part or source, "(.+)%.(.+)$") -- 處理沒有路徑的情況
  -- local line_num = info.currentline
  --
  -- 使用 Snacks.debug.log 進行記錄
  -- 如果 name_part 為 nil (例如，直接在 lua 解釋器中執行)，則使用 filename_part
  -- local log_prefix = string.format("%s:%d", name_part or filename_part or "unknown", line_num)
  -- Snacks.debug.log(string.format("%s %s\t%s", log_prefix, message_level_str, message))
end

--- 取得選中範圍的文字
function M.get_visual_selection()
  -- 保存當前的選擇模式
  local mode = vim.fn.mode()
  -- 修正：空字串 "" 也可能是 visual 模式結束後的狀態，但不應觸發
  if mode ~= "v" and mode ~= "V" then
    M.log("不是 Visual 模式，無法獲取選區", "DEBUG")
    return nil
  end

  -- 獲取當前視窗和緩衝區
  local buf = vim.api.nvim_get_current_buf()

  -- 獲取選擇範圍的標記位置
  -- 'v' 是視覺模式開始的位置，'.' 是光標當前位置 (視覺模式結束的位置)
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")

  -- 確保起始位置在結束位置之前 (處理反向選擇)
  local start_line, end_line
  local start_col, end_col

  if start_pos[2] < end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] <= end_pos[3]) then
    -- 正向選擇或同行選擇
    start_line = start_pos[2]
    end_line = end_pos[2]
    start_col = start_pos[3]
    end_col = end_pos[3]
  else
    -- 反向選擇
    start_line = end_pos[2]
    end_line = start_pos[2]
    start_col = end_pos[3]
    end_col = start_pos[3]
  end

  M.log(string.format("選區範圍: 行 %d-%d, 列 %d-%d", start_line, end_line, start_col, end_col), "DEBUG")

  -- 獲取選中的行 (0-based index)
  local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

  if #lines == 0 then
    M.log("未能獲取選區行", "WARN")
    return nil -- 如果沒有獲取到行，返回 nil
  end

  -- 處理選中的文字
  if mode == "V" then
    -- V-LINE 模式：保持整行內容
    M.log("行選擇模式 (V-Line)", "DEBUG")
    -- 不需要做任何修改
  else
    -- 一般 visual 模式 ('v')：根據列位置截取
    M.log("字元選擇模式 (Visual)", "DEBUG")
    if #lines == 1 then
      -- 單行選擇
      local line_content = lines[1]
      -- vim.fn.getpos 返回的是位元組位置 (1-based)，需要轉換為字元索引
      local start_char_idx = vim.fn.charidx(line_content, start_col - 1)  -- 轉換為 0-based 位元組位置
      local end_char_idx = vim.fn.charidx(line_content, end_col - 1)      -- 轉換為 0-based 位元組位置
      local char_count = end_char_idx - start_char_idx + 1
      lines[1] = vim.fn.strcharpart(line_content, start_char_idx, char_count)
      M.log(
        string.format("單行截取: start_char=%d, end_char=%d, count=%d, content='%s'", 
          start_char_idx, end_char_idx, char_count, lines[1]),
        "DEBUG"
      )
    else
      -- 多行選擇
      local first_line_content = lines[1]
      local last_line_content = lines[#lines]

      -- 截取第一行從 start_col 開始的部分
      local start_char_idx = vim.fn.charidx(first_line_content, start_col - 1)
      lines[1] = vim.fn.strcharpart(first_line_content, start_char_idx)
      M.log(string.format("多行截取 - 第一行: start_char=%d, content='%s'", start_char_idx, lines[1]), "DEBUG")

      -- 截取最後一行到 end_col 的部分
      local end_char_idx = vim.fn.charidx(last_line_content, end_col - 1) + 1  -- +1 因為要包含結束字元
      lines[#lines] = vim.fn.strcharpart(last_line_content, 0, end_char_idx)
      M.log(
        string.format("多行截取 - 最後一行: end_char=%d, content='%s'", end_char_idx, lines[#lines]),
        "DEBUG"
      )
    end
  end

  local selected_text = table.concat(lines, "\n")
  M.log(string.format("最終選中文本:\n%s", selected_text), "DEBUG")

  -- 返回選中文本和原始的行列資訊 (1-based)
  return selected_text, start_pos[2], end_pos[2], start_pos[3], end_pos[3]
end

--- 將內容包裝在程式碼塊模板中
---@param input string 要包裝的內容
---@param filetype? string 程式碼塊的語言 (預設: nil)
---@param start_line? integer 起始行號 (預設: nil)
---@param end_line? integer 結束行號 (預設: nil)
---@param path? string 檔案路徑 (預設: nil)
---@return string
function M.template_code(input, filetype, start_line, end_line, path)
  if not input or #input == 0 then
    return ""
  end
  local tpl = ""

  -- 只有當所有路徑和行號資訊都存在時才添加 file: 行
  if path and start_line and end_line then
    -- 確保路徑不為空
    local abs_path = vim.fn.fnamemodify(path, ":p") -- 獲取絕對路徑
    if abs_path and #abs_path > 0 then
      -- 根據作業系統調整路徑表示 (可選，通常 aider 能處理)
      -- local formatted_path = vim.fn.substitute(abs_path, '\\', '/', 'g') -- 將反斜線替換為正斜線
      tpl = tpl .. "file:" .. abs_path .. ":" .. start_line .. "-" .. end_line .. "\n\n\n"
    end
  end

  -- 添加程式碼塊標記
  if filetype and #filetype > 0 then
    tpl = tpl .. "```" .. filetype .. "\n"
  else
    tpl = tpl .. "```" .. "\n"
  end
  tpl = tpl .. input
  -- 確保程式碼塊以換行符結尾
  if not input:match("\n$") then
    tpl = tpl .. "\n"
  end
  tpl = tpl .. "```\n"
  tpl = tpl .. "---\n\n"
  return tpl
end

return M

