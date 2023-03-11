
local M = {}

local defaults = {
  include_declaration = false   -- Reference include declaration
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', defaults, opts)
end

return M

