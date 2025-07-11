# Porduct Requirement Document

## TODO

- [x] send text to other pane
- [x] show pane number (tmux command)
- [x] select pane by pane number
- [ ] send path to target pane
- [ ] send diagnostics

名稱解釋:

- nvim pane: 執行 nvim 的 pane
- target pane: send text 的目標 pane. current window 中, 除了 nvim pane 外, 其他的 panes 都是 target pane 的候選

## send text to other pane

1. nvim 會向 target pane 傳送信息
2. 如果 window 只有兩個 panes, 自動設定 target pane 為 非 nvim name 的那個 pane
3. 如果 window 只有一個 pane , 要顯示錯誤訊息
4. 如果 window 有 兩個以上的 panes, picker 讓 user 選擇 taget pane

## select pane by pane number

`tmux display-panes` command 可以顯示 pane number, 必須在適當的時機顯示這個 pane number 的訊息, 以利 picker 做選擇

1. 使用 snack.nvim 的 picker 提供 current window 的 panes 以供選擇
2. 使用 picker 選擇後, 要記住選擇的 pane, 把 target pane 設定為被選中的 pane
3. picker 中顯示的訊息要包含 pane number

## Range Selection Test

```text
START HERE |
line1: 123 1 2 3 中文字 測試,中文 ABC
```

測試步驟:

1. 先將 cursor 定位在 START HERE | 的 `|` 處 , `|` 表示 CURSOR 的起始位置, 預設為 normal
2. 使用 neovim 的 motion 操作 定位到特定的位置, ex: `j4hv8l` 會 visual select, line1 的 `123 1 2 3`
3. <space>ats 會 send text to target pane

以下為 test case 跟結果:

### test case 1:

- motion: j4hv8l
- selection: `123 1 2 3`
- expect: `123 1 2 3`
- action: `123 1 2 3`
- result: passed

### test case 2:

- motion: j6lv2l
- selection: `中文字`
- expect: `中文字`
- action: `中文字 測試`
- result: failed

### test case 3:

- motion: jv8l
- selection: `1 2 3 中文字`
- expect: `1 2 3 中文字`
- action: `1 2 3 中文字 測試,`
- result: failed
