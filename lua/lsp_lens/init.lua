local lens = require('lsp_lens.lens-util')
local config = require('lsp_lens.config')

local M = {}

local augroup = vim.api.nvim_create_augroup('lsp_lens', {clear = true})

function M.setup(opts)
  config.setup(opts)

  vim.api.nvim_create_user_command("LspLensOn", lens.procedure, {})
  vim.api.nvim_create_user_command("LspLensOff", lens.lsp_lens_off, {})

  vim.api.nvim_create_autocmd({ "LspAttach", "InsertLeave", "TextChanged" }, {
    group = augroup,
    callback = lens.procedure
  })
end

return M

