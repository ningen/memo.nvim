local M = {}

local bufs = {}

function M.get_or_create(memo_path)
	if bufs[memo_path] and vim.api.nvim_buf_is_valid(bufs[memo_path]) then
		return bufs[memo_path]
	end
	local b = vim.fn.bufadd(memo_path)
	vim.fn.bufload(b)
	vim.bo[b].buflisted = false
	bufs[memo_path] = b
	return b
end

function M.append_lines(buf, lines)
	local n = vim.api.nvim_buf_line_count(buf)
	vim.api.nvim_buf_set_lines(buf, n, -1, false, lines)
	return n + #lines
end

-- Reset internal state (for testing)
function M.reset()
	bufs = {}
end

return M
