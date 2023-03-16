
local M = {}

local defaults = {
  enable = true,
  include_declaration = false,      -- Reference include declaration
  sections = {                      -- Enable / Disable specific request
    definition = false,
    references = true,
    implements = true,
  },
  ignore_filetype = {
    "prisma",
  },
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', defaults, opts)
end

return M

