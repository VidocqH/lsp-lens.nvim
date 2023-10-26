local M = {}

local defaults = {
  enable = true,
  include_declaration = false, -- Reference include declaration
  hide_zero_counts = true, -- Hide lsp sections which have no content
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
  },
  separator = " | ",
  decorator = function(line)
    return line
  end,
  ignore_filetype = {
    "prisma",
  },
}

M.config = vim.deepcopy(defaults)

function M.setup(opts)
  opts = opts or {}
  for k, v in pairs(opts.sections and opts.sections or {}) do
    if type(v) == "boolean" and v then
      opts.sections[k] = nil
    end
  end
  M.config = vim.tbl_deep_extend("force", defaults, opts)
end

return M
