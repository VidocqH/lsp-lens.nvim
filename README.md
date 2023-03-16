# lsp-lens.nvim

Neovim plugin for displaying references and difinition infos upon functions like JB's IDEA.

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
require'lsp-lens'.setup({
  enable = true,
  include_declaration = false,      -- Reference include declaration
  sections = {                      -- Enable / Disable specific request
    definition = false,
    references = true,
    implementation = true,
  },
  ignore_filetype = {
    "prisma",
  },
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
+ Due to a [known issue](https://github.com/neovim/neovim/issues/16166) with the neovim `nvim_buf_set_extmark()` api, the function and method defined on the first line of the code may cause the len to display at the -1 index line, which is not visible.

## Thanks

[lspsaga by glepnir](https://github.com/glepnir/lspsaga.nvim#customize-appearance)
