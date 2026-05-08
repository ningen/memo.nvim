local M = {}

local index = require("memo.index")

local function candidates(entry)
	local out = {}
	if not entry.location or not entry.location.path then
		return out
	end

	local path = entry.location.path
	table.insert(out, path)

	if not path:match("^/") then
		table.insert(out, vim.fn.getcwd() .. "/" .. path)
		if entry.memo_path then
			local memo_dir = vim.fn.fnamemodify(entry.memo_path, ":h")
			table.insert(out, memo_dir .. "/" .. path)
		end
	end

	return out
end

function M.resolve(entry)
	for _, path in ipairs(candidates(entry)) do
		local expanded = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
		if vim.fn.filereadable(expanded) == 1 then
			return expanded
		end
	end
	return nil
end

function M.source_items(entries)
	local items = {}
	for _, entry in ipairs(entries or {}) do
		local path = M.resolve(entry)
		if path then
			table.insert(items, {
				filename = path,
				lnum = entry.location.line1 or 1,
				col = 1,
				text = entry.summary or (entry.location and entry.location.text) or path,
			})
		end
	end
	return items
end

function M.broken(entries)
	local broken = {}
	for _, entry in ipairs(entries or {}) do
		if entry.location and entry.location.path and not M.resolve(entry) then
			table.insert(broken, entry)
		end
	end
	return broken
end

function M.quickfix(cfg)
	local loaded = index.load(cfg)
	local items = M.source_items(loaded.entries)
	vim.fn.setqflist({}, " ", {
		title = "Memo Sources",
		items = items,
	})
	if #items > 0 then
		vim.cmd("copen")
	else
		vim.notify("No readable memo source files found", vim.log.levels.INFO)
	end
	return items
end

function M.broken_report(cfg)
	local loaded = index.load(cfg)
	return M.broken(loaded.entries)
end

return M
