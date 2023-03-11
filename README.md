# lsp-lens.nvim

Neovim plugin for displaying references and difinition infos upon functions like JB's IDEA.

<img width="376" alt="image" src="https://user-images.githubusercontent.com/16725418/217580076-7064cc80-664c-4ade-8e66-a0c75801cf17.png">

## Installation
### Prerequisite
neovim >= 0.7.0

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
  include_declaration = false   -- Reference include declaration
})
```

## Commands
```
:LspLensOn
:LspLensOff
```

## Highlight
```lua
{
  LspLens = { link = "Comment" },
}
```

## Thanks
[lspsaga by glepnir](https://github.com/glepnir/lspsaga.nvim#customize-appearance)
