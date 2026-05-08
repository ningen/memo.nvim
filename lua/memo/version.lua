local M = {}

M.name = "memo.nvim"
M.version = "0.2.0"

function M.info()
	return {
		name = M.name,
		version = M.version,
		nvim = vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
	}
end

function M.markdown()
	local info = M.info()
	return {
		"# Memo Version",
		"",
		"- Plugin: " .. info.name,
		"- Version: " .. info.version,
		"- Neovim: " .. info.nvim,
	}
end

return M
