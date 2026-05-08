local M = {}

local util = require("memo.util")

local function current_memo_path(cfg)
	local _, _, git_root = util.get_context()
	return util.resolve_memo_path(git_root, cfg)
end

local function open_markdown_scratch(name, lines)
	local b = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(b, name)
	vim.bo[b].buftype = "nofile"
	vim.bo[b].bufhidden = "wipe"
	vim.bo[b].swapfile = false
	vim.bo[b].filetype = "markdown"
	vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
	vim.api.nvim_set_current_buf(b)
	return b
end

function M.search(query, cfg)
	if not query or query == "" then
		vim.notify("MemoSearch requires a query", vim.log.levels.WARN)
		return {}
	end

	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if line:lower():find(query:lower(), 1, true) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoSearch: " .. query,
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo matches for: " .. query, vim.log.levels.INFO)
	end

	return results
end

function M.export_lines(cfg)
	local filename, project, git_root = util.get_context()
	local memo_path = util.resolve_memo_path(git_root, cfg)
	local memo_lines = {}

	if vim.fn.filereadable(memo_path) == 1 then
		memo_lines = vim.fn.readfile(memo_path)
	end

	local lines = {
		"# Memo Context",
		"",
		"- Project: " .. project,
		"- Current file: " .. filename,
		"- Memo path: " .. memo_path,
		"- Git root: " .. (git_root or "(none)"),
		"",
		"## Instructions",
		"",
		"Use the memo entries below as working context. Preserve source paths and line numbers when they are relevant.",
		"",
		"## Memo",
		"",
	}

	if #memo_lines == 0 then
		table.insert(lines, "(memo file is empty or missing)")
	else
		vim.list_extend(lines, memo_lines)
	end

	return lines
end

function M.export(cfg)
	local lines = M.export_lines(cfg)
	return open_markdown_scratch("memo-export.md", lines)
end

return M
