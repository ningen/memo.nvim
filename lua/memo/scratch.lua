local M = {}

function M.open(name, lines, filetype)
	local b = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(b, name)
	vim.bo[b].buftype = "nofile"
	vim.bo[b].bufhidden = "wipe"
	vim.bo[b].swapfile = false
	vim.bo[b].filetype = filetype or "markdown"
	vim.api.nvim_buf_set_lines(b, 0, -1, false, lines or {})
	vim.api.nvim_set_current_buf(b)
	return b
end

function M.markdown(name, lines)
	return M.open(name, lines, "markdown")
end

function M.jsonl(name, lines)
	return M.open(name, lines, "json")
end

return M
