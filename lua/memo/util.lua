local M = {}

function M.get_context()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "（no file）"
	end

	local filepath = vim.fn.expand("%:p:h")
	local result = vim.fn.systemlist("git -C " .. vim.fn.shellescape(filepath) .. " rev-parse --show-toplevel")
	local git_root = vim.v.shell_error == 0 and result[1] or nil
	local project = git_root and vim.fn.fnamemodify(git_root, ":t") or "（no git）"

	return filename, project, git_root
end

function M.resolve_memo_path(git_root, cfg)
	if cfg.per_project and git_root then
		return git_root .. "/.memo.md"
	end
	return cfg.path or vim.fn.expand("~/memo.md")
end

function M.make_header(filename, project)
	local date = os.date("%Y-%m-%d %H:%M")
	return {
		"",
		"---",
		"## " .. date .. " | " .. project .. " | " .. filename,
		"",
	}
end

function M.make_code_block(lines, filetype)
	local block = { "```" .. (filetype or "") }
	vim.list_extend(block, lines)
	vim.list_extend(block, { "```", "" })
	return block
end

return M
