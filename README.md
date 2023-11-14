# lsp-lens.nvim

Neovim plugin for displaying reference and definition info upon functions like JB's IDEA.

<img width="376" alt="image" src="https://user-images.githubusercontent.com/16725418/217580076-7064cc80-664c-4ade-8e66-a0c75801cf17.png">

## Installation

### Prerequisite

neovim >= 0.8

lsp server correctly setup

### Lazy

```lua
require("lazy").setup({
  'VidocqH/lsp-lens.nvim'
})
```

### Usage

```lua
require'lsp-lens'.setup({})
```

## Configs

Below is the default config

```lua
local SymbolKind = vim.lsp.protocol.SymbolKind

require'lsp-lens'.setup({
  enable = true,
  include_declaration = false,      -- Reference include declaration
  sections = {                      -- Enable / Disable specific request, formatter example looks 'Format Requests'
    definition = false,
    references = true,
    implements = true,
    git_authors = true,
  },
  ignore_filetype = {
    "prisma",
  },
  -- Target Symbol Kinds to show lens information
  target_symbol_kinds = { SymbolKind.Function, SymbolKind.Method, SymbolKind.Interface },
  -- Symbol Kinds that may have target symbol kinds as children
  wrapper_symbol_kinds = { SymbolKind.Class, SymbolKind.Struct },
})
```

### Format Requests

```lua
require'lsp-lens'.setup({
  sections = {
    definition = function(count)
        return "Definitions: " .. count
    end,
    references = function(count)
        return "References: " .. count
    end,
    implements = function(count)
        return "Implements: " .. count
    end,
    git_authors = function(latest_author, count)
        return " " .. latest_author .. (count - 1 == 0 and "" or (" + " .. count - 1))
    end,
  }
})

```

## Commands

```
:LspLensOn
:LspLensOff
:LspLensToggle
```

## Highlight

```lua
{
  LspLens = { link = "Comment" },
}
```

## Known Bug

- Due to a [known issue](https://github.com/neovim/neovim/issues/16166) with the neovim `nvim_buf_set_extmark()` api, the function and method defined on the first line of the code may cause the len to display at the -1 index line, which is not visible.

## Thanks

[lspsaga by glepnir](https://github.com/glepnir/lspsaga.nvim#customize-appearance)
