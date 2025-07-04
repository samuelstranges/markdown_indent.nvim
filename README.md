# markdown_indent.nvim

A Neovim plugin for intelligent markdown header indentation. Allows you to
easily indent/unindent markdown headers and their subheadings using
Tab/Shift-Tab.

## Features

- **Smart header indentation**: Use Tab to increase header level (add `#`) and
  Shift-Tab to decrease
- **Subheading support**: Optionally indent all subheadings when indenting a
  parent header
- **Fallback behavior**: Configurable behavior when not on a header line
- **Buffer-local keymaps**: Only active in markdown files
- **Highly configurable**: Customize keybindings, file types, and behavior

## Installation

### Using lazy.nvim

```lua
{
  'samuelstranges/markdown_indent.nvim',
  ft = { 'markdown' },
  config = function()
    require('markdown_indent').setup()
  end,
}
```

## Usage

Once installed, the plugin automatically sets up keybindings for markdown files:

- **Tab**: Indent current header (and subheadings if enabled)
- **Shift-Tab**: Unindent current header (and subheadings if enabled)

## Configuration

```lua
require('markdown_indent').setup({
  -- Keymaps (set to false to disable default keymaps)
  keymaps = {
    indent = "<Tab>",     -- Key to indent headers
    unindent = "<S-Tab>", -- Key to unindent headers
  },

  -- Maximum header level (markdown standard is 6)
  max_header_level = 6,

  -- File types to activate on
  filetypes = { "markdown", "md" },

  -- Whether to include subheadings when indenting
  include_subheadings = true,

  -- Fallback behavior when not on a header
  fallback_behavior = "indent", -- "indent" | "tab" | "none"
})
```

### Configuration Options

- `keymaps.indent`: Key binding for indenting headers (default: `<Tab>`)
- `keymaps.unindent`: Key binding for unindenting headers (default: `<S-Tab>`)
- `max_header_level`: Maximum header level (1-6, default: 6)
- `filetypes`: File types to activate on (default: `{"markdown", "md"}`)
- `include_subheadings`: Whether to indent subheadings along with parent headers
  (default: true)
- `fallback_behavior`: What to do when not on a header line:
    - `"indent"`: Use normal indentation commands
    - `"tab"`: Insert a tab character
    - `"none"`: Do nothing

## Manual Usage

You can also call the functions directly:

```lua
local markdown_indent = require('markdown_indent')

-- Indent current header
markdown_indent.indent()

-- Unindent current header
markdown_indent.unindent()
```
