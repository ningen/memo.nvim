local M = {}

local util = require("memo.util")

local function current_memo_path(cfg)
	local _, _, git_root = util.get_context()
	return util.resolve_memo_path(git_root, cfg)
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

return M
