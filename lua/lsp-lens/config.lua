local M = {}

local defaults = {
  enable = true,
  include_declaration = false, -- Reference include declaration
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
  },
  separator = " | ",
  decorator = function(line) return line end,
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
