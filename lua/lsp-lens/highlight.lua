local api = vim.api
local M = {}

local function default_hl()
	return {
		LspLens = { link = "LspCodeLens", default = true },
	}
end

function M.setup()
	for group, hl in pairs(default_hl()) do
		api.nvim_set_hl(0, group, hl)
	end
end

return M
