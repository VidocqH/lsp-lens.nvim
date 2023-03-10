local M = {}
local lens = require('lsp_lens.lens-util')

local default_config = {
  include_declaration = true
}

local augroup = vim.api.nvim_create_augroup('nvim-lens', {clear = true})

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', default_config, opts)

  vim.api.nvim_create_user_command("NvimLensOn", lens.procedure, {})
  vim.api.nvim_create_user_command("NvimLensOff", lens.nvim_lens_off, {})

  vim.api.nvim_create_autocmd({ "LspAttach", "InsertLeave", "TextChanged" }, {
    group = augroup,
    callback = lens.procedure
  })
end

return M

