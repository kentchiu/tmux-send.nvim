# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 專案概述

這是一個 Neovim 插件，用於在 tmux 環境中發送文字到其他 pane。目前主要實作為 Claude Code, Gemini CLI 整合，但架構可擴展為通用的 tmux-send 工具。

## 開發命令

### 測試

```bash
make test  # 使用 plenary.nvim 執行測試
```

### 程式碼品質

- **格式化**: 使用 stylua（縮排 2 空格，行寬 120）
- **Linting**: 使用 selene（Lua 5.1 標準）
- 程式寫法慣例 use context7 lazy.nvim 跟 Snacks.nvim
- 嚴格遵守 https://github.com/nvim-neorocks/nvim-best-practices/blob/main/README.md 的 Best Practices

## 核心架構

### 模組結構

- `lua/tmux-send/tmux.lua`: tmux 整合核心，處理 pane 偵測和文字發送
- `lua/tmux-send/actions.lua`: 使用者操作（fix、dialog、add_file）
- `lua/tmux-send/dialog.lua`: 浮動視窗對話框系統
- `lua/tmux-send/health.lua`: 健康檢查功能
- `plugin/tmuxsend.lua`: Vim 命令定義

### 關鍵概念

1. **Pane 偵測**: 自動尋找運行特定程式（目前為 Claude code）的 tmux pane
2. **Bracketed Paste Mode**: 使用 tmux 的 bracketed paste 確保文字正確發送
3. **內容格式化**: 自動將程式碼包裝成 Markdown 格式，附加檔案路徑和行號資訊

### 依賴管理

- 必要依賴：plenary.nvim（測試）、snacks.nvim（UI 元件）
- 執行環境：必須在 tmux session 內使用

## 重要注意事項

1. **提供計劃優先**: 所有操作都要先提供詳細計劃，得到同意後再進行實作
2. **避免過度設計**: 
   - 直接使用 `require()` 載入模組，不需要 lazy loading
   - Lua 的 require 本身就有 cache 機制
   - 保持程式碼簡單，提升 LSP 支援度
3. **Tmux 環境**: 所有功能都依賴於 tmux 環境，必須檢查 `$TMUX` 環境變數

## LSP 支援

- 程式要儘可能的支援開發的 LSP 功能