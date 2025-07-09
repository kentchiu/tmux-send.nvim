# tmux-send.nvim

Send text to other tmux panes from Neovim.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "kent/tmux-send.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for tests
    "folke/snacks.nvim",     -- Optional for better UI
  },
  keys = {
    { "<leader>atl", "<Plug>(TmuxSendLine)", desc = "Send current line to tmux" },
    { "<leader>ats", "<Plug>(TmuxSendSelection)", mode = "x", desc = "Send selection to tmux" },
  },
  config = function()
    require("tmux-send").setup({
      -- Configuration options (see below)
    })
  end,
}
```

## Alternative Keymap Setup

If you prefer to set up keymaps separately or use different key bindings:

```lua
-- In your Neovim configuration
vim.keymap.set("n", "<leader>tl", "<Plug>(TmuxSendLine)")        -- Send current line
vim.keymap.set("x", "<leader>ts", "<Plug>(TmuxSendSelection)")   -- Send visual selection
```

## Commands

- `:TmuxSend [text]` - Send text to target pane (defaults to current line)
- `:TmuxSendLine` - Send current line
- `:TmuxSendSelection` - Send visual selection
- `:TmuxSelectPane` - Select target pane interactively

## Configuration

```lua
require("tmux-send").setup({
  -- Default target pane: "last", "next", "previous", or pane ID
  default_pane = "last",

  -- Automatically append Enter key after sending text
  send_enter = true,

  -- Use tmux bracketed paste mode for better handling of special characters
  use_bracketed_paste = true,

  -- Pane selector options
  selector = {
    prefer_telescope = true,  -- Use telescope.nvim if available
    show_preview = true,      -- Show pane content preview
  },

  -- Text templates (not implemented yet)
  templates = {},
})
```

## Usage

1. **Basic usage**: Place cursor on a line and use your keymap (e.g., `<leader>tl`) to send it to the last active tmux pane.

2. **Visual selection**: Select text in visual mode and use `<leader>ts` to send the selection.

3. **With motions**: Use the `:TmuxSend` command with motions.

4. **Select target pane**: Use `:TmuxSelectPane` to interactively select which tmux pane to send text to.

## Requirements

- Neovim >= 0.8.0
- tmux
- Must be running inside a tmux session

## License

MIT

