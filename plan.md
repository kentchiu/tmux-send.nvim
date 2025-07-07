# tmux-send.nvim Development Plan

## Overview

A minimalist Neovim plugin for sending text to tmux panes, following [nvim-best-practices](https://github.com/nvim-neorocks/nvim-best-practices).

## Core Principles

1. **Lazy Loading**: Minimize startup impact
2. **User Control**: No forced keybindings, use `<Plug>` mappings
3. **Type Safety**: Use LuaCATS annotations
4. **Unified Interface**: Single command with subcommands
5. **Optional Setup**: Don't require `setup()` call

## Project Structure

```
tmux-send.nvim/
├── lua/
│   ├── tmux-send/
│   │   ├── init.lua         # Main module with lazy loading
│   │   ├── config.lua       # Configuration management
│   │   ├── health.lua       # Health check implementation
│   │   └── private/         # Internal modules (not exposed)
│   │       ├── pane.lua     # Pane management
│   │       ├── sender.lua   # Send logic
│   │       └── util.lua     # Utility functions
│   └── tmux-send.lua        # Public API (minimal exposure)
├── plugin/
│   └── tmux-send.lua        # Minimal plugin entry
├── doc/
│   └── tmux-send.txt        # Vim help documentation
├── tests/                   # Test files
│   └── tmux-send_spec.lua
└── .luarc.json              # LuaCATS configuration
```

## Feature Specifications

### 1. Text Sending Modes

- **Current Line**: Send line under cursor
- **Visual Selection**: Send selected text
- **Motion Support**: Send text objects (e.g., paragraph, function)
- **Custom Text**: Send user-provided text
- **File Path**: Send current file path

### 2. Pane Management

- **List Panes**: Show all available tmux panes
- **Select Pane**: Interactive pane selection
- **Remember Target**: Keep track of last used pane
- **Multi-target**: Send to multiple panes simultaneously

### 3. Command Interface

Single command with subcommands and smart completion:

```vim
:TmuxSend              " Send current line/selection
:TmuxSend line         " Send current line
:TmuxSend pane         " Select target pane
:TmuxSend list         " List all panes
```

### 4. Plug Mappings

```vim
<Plug>(TmuxSendLine)       " Send current line
<Plug>(TmuxSendSelection)  " Send selection
<Plug>(TmuxSendMotion)     " Operator for motions
<Plug>(TmuxSelectPane)     " Open pane selector
```

## Configuration Options

```lua
{
  -- Default target pane
  default_pane = "last",  -- "last" | "next" | "previous" | pane_id

  -- Auto-append Enter key
  send_enter = true,

  -- Use bracketed paste mode
  use_bracketed_paste = true,


  -- Pane selector UI
  selector = {
    -- Use telescope if available
    prefer_telescope = true,
    -- Show pane preview
    show_preview = true,
  },

  -- Custom templates
  templates = {
    test = "npm test %file%",
    run = "python %file%",
  }
}
```

## API Design

### Public API (Minimal)

```lua
---@class TmuxSend
local M = {}

---Send text to tmux pane
---@param text? string Text to send (default: current line/selection)
---@param target? string|integer Target pane (default: last used)
function M.send(text, target) end

---Select target pane interactively
---@return string|nil pane_id
function M.select_pane() end


---Optional setup
---@param opts? TmuxSendConfig
function M.setup(opts) end
```

### Type Definitions (LuaCATS)

```lua
---@class TmuxSendConfig
---@field default_pane? string|integer Default target pane
---@field send_enter? boolean Auto-append Enter
---@field use_bracketed_paste? boolean Use bracketed paste mode
---@field selector? TmuxSendSelectorConfig Pane selector options
---@field templates? table<string, string> Text templates

---@class TmuxSendSelectorConfig
---@field prefer_telescope? boolean Use telescope if available
---@field show_preview? boolean Show pane content preview

---@class TmuxPane
---@field id string Pane identifier
---@field index integer Pane index
---@field title string Pane title
---@field current boolean Is current pane
---@field width integer Pane width
---@field height integer Pane height
```

## Implementation Phases

### Phase 1: Core Functionality

1. Basic tmux communication
2. Send current line/selection
3. Pane detection and listing

### Phase 2: Pane Management

1. Interactive pane selector
2. Interactive pane selector

### Phase 3: Enhanced Features

1. Motion support (operator)
2. Multi-pane sending
3. Template system

### Phase 4: Integration

1. Telescope integration
2. Status line component
3. Completion improvements

### Phase 5: Polish

1. Comprehensive tests
2. Documentation
3. Health check refinement

## Testing Strategy

- Unit tests for core functions
- Integration tests with tmux
- Mock tmux commands for CI
- Performance benchmarks

## Documentation

- Vim help file (`:help tmux-send`)
- README with quick start
- API documentation
- Example configurations

