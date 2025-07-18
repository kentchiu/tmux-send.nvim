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
- `<leader>atF` - Send file paths to tmux (file picker)
- `<leader>atf` - Send current file path to tmux
- `<leader>ati` - Send image paths from /mnt/c/sharex/ to tmux

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
    send_image_paths = "<leader>ti",  -- Custom keymap for image paths
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
vim.keymap.set("n", "<leader>tf", "<Plug>(TmuxSendCurrentPath)") -- Send current file path
vim.keymap.set("n", "<leader>tF", "<Plug>(TmuxSendPath)")        -- Send file paths (picker)
vim.keymap.set("n", "<leader>ti", "<Plug>(TmuxSendImagePaths)")  -- Send image paths
```

## Commands

- `:TmuxSend [text]` - Send text to target pane (defaults to current line)
- `:TmuxSend line` - Send current line
- `:TmuxSend select` - Select target pane interactively
- `:TmuxSend path` - Open file picker and send selected paths
- `:TmuxSend current-path` - Send current file path
- `:TmuxSend image-paths` - Send image paths from /mnt/c/sharex/
- `:TmuxSendImagePaths` - Send image paths (dedicated command)

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

3. **Select target pane**: Use `<leader>atp` to interactively select which tmux pane to send text to.

4. **Send file paths**: Use `<leader>atF` to open a file picker and send selected file paths to tmux.

5. **Send current file path**: Use `<leader>atf` to send the current buffer's file path.

6. **Send image paths**: Use `<leader>ati` to browse and send image paths from `/mnt/c/sharex/` directory (useful for ShareX screenshots on WSL).

### Image Path Syntax (@IMAGE)

When sending text, you can use the `@IMAGE` syntax to reference images:

- `@IMAGE` or `@IMAGE:-1` - Latest image
- `@IMAGE:0` - First (latest) image
- `@IMAGE:1` - Second image
- `@IMAGE:2` - Third image, etc.

Example:
```
require("tmux-send").send_with_images("Check this screenshot: @IMAGE")
```

## Requirements

- Neovim >= 0.8.0
- tmux
- Must be running inside a tmux session

## License

MIT

