local M = {}
local lens = require('lens.lens-util')

local default_config = {
  include_declaration = true
}

-- local augroup = vim.api.nvim_create_augroup('nvim-lens')

function M.setup(opts)
  opts = opts or {}
  print("hello, world")
  M.config = vim.tbl_deep_extend('force', default_config, opts)
  vim.api.nvim_create_user_command("NvimLensOn", lens.procedure, {})
  vim.api.nvim_create_user_command("NvimLensOff", lens.nvim_lens_off, {})
end

return M

