# tmux-send.nvim Tests

## 執行測試

### 前置需求

測試需要 [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)。測試腳本會自動下載。

### 執行所有測試

```bash
make test
```

### 執行單一測試檔案

```bash
make test-file FILE=tests/config_spec.lua
```

### 開發模式（自動重新執行測試）

需要安裝 `inotify-tools`:

```bash
# Ubuntu/Debian
sudo apt-get install inotify-tools

# 然後執行
make test-watch
```

### 直接使用 Neovim 執行測試

```bash
# 執行所有測試
nvim --headless --noplugin -u scripts/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.lua' }"

# 執行單一測試
nvim --headless --noplugin -u scripts/minimal_init.lua \
  -c "PlenaryBustedFile tests/config_spec.lua"
```

## 測試結構

- `config_spec.lua` - 設定模組測試
- `tmux-send_spec.lua` - 主要功能和命令補全測試

## 撰寫測試

使用 plenary.nvim 的 busted 風格：

```lua
describe("module name", function()
  before_each(function()
    -- 每個測試前執行
  end)
  
  it("should do something", function()
    assert.equals(expected, actual)
  end)
end)
```