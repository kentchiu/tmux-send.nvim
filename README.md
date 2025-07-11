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
  config = function()
    require("tmux-send").setup({
      -- Configuration options (see below)
    })
  end,
}
```

## Default Keymaps

By default, tmux-send.nvim sets up the following keymaps:

- `<leader>ats` - Send current line/selection to tmux
- `<leader>atp` - Select tmux pane and send
- `<leader>atl` - List tmux panes

### Disabling Default Keymaps

To disable all default keymaps:

```lua
require("tmux-send").setup({
  keymaps = false,
})
```

### Customizing Keymaps

To use a different prefix:

```lua
require("tmux-send").setup({
  keymap_prefix = "<leader>m",  -- Use <leader>m instead of <leader>at
})
```

To customize specific keymaps:

```lua
require("tmux-send").setup({
  keymaps = {
    send = "<C-s>",           -- Use Ctrl-s for send
    select_pane = false,      -- Disable pane selection keymap
  },
})
```

### Manual Keymap Setup

If you prefer to set up keymaps manually:

```lua
require("tmux-send").setup({
  keymaps = false,  -- Disable default keymaps
})

-- Set up your own keymaps
vim.keymap.set("n", "<leader>tl", "<Plug>(TmuxSendLine)")        -- Send current line
vim.keymap.set("x", "<leader>ts", "<Plug>(TmuxSendSelection)")   -- Send visual selection
vim.keymap.set("n", "<leader>tp", "<Plug>(TmuxSelectPane)")      -- Select pane
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

  -- Enable default keymaps (set to false to disable)
  keymaps = true,

  -- Prefix for default keymaps
  keymap_prefix = "<leader>at",

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

1. **Basic usage**: Place cursor on a line and use your keymap (e.g., `<leader>ats`) to send it to the last active tmux pane.

2. **Visual selection**: Select text in visual mode and use `<leader>ats` to send the selection.

3. **Select target pane**: Use `:TmuxSelectPane` to interactively select which tmux pane to send text to.

## Requirements

- Neovim >= 0.8.0
- tmux
- Must be running inside a tmux session

## License

MIT

