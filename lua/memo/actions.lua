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

function M.yank_last(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local lines = util.extract_last_entry(vim.fn.readfile(memo_path))
	local text = table.concat(lines, "\n")
	vim.fn.setreg('"', text)
	vim.fn.setreg("+", text)
	vim.notify("Yanked last memo entry", vim.log.levels.INFO)
	return lines
end

function M.todo(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if util.is_task_line(line) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoTodo",
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo tasks found", vim.log.levels.INFO)
	end

	return results
end

function M.today(cfg, date)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	date = date or os.date("%Y-%m-%d")
	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if line:match("^## " .. vim.pesc(date)) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoToday: " .. date,
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo entries for: " .. date, vim.log.levels.INFO)
	end

	return results
end

function M.tag_summary(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local counts = {}
	for _, line in ipairs(vim.fn.readfile(memo_path)) do
		for _, tag in ipairs(util.extract_tags(line)) do
			counts[tag] = (counts[tag] or 0) + 1
		end
	end

	return counts
end

function M.tags(cfg)
	local counts = M.tag_summary(cfg)
	local tags = {}
	for tag in pairs(counts) do
		table.insert(tags, tag)
	end
	table.sort(tags)

	local lines = { "# Memo Tags", "" }
	if #tags == 0 then
		table.insert(lines, "(no tags found)")
	else
		for _, tag in ipairs(tags) do
			table.insert(lines, "- #" .. tag .. " (" .. counts[tag] .. ")")
		end
	end

	return open_markdown_scratch("memo-tags.md", lines)
end

function M.stats_summary(cfg)
	local memo_path = current_memo_path(cfg)
	local lines = {}
	if vim.fn.filereadable(memo_path) == 1 then
		lines = vim.fn.readfile(memo_path)
	end

	local entries = 0
	local tasks = 0
	local tags = {}
	for _, line in ipairs(lines) do
		if line:match("^## %d%d%d%d%-%d%d%-%d%d") then
			entries = entries + 1
		end
		if util.is_task_line(line) then
			tasks = tasks + 1
		end
		for _, tag in ipairs(util.extract_tags(line)) do
			tags[tag] = true
		end
	end

	local tag_count = 0
	for _ in pairs(tags) do
		tag_count = tag_count + 1
	end

	return {
		path = memo_path,
		lines = #lines,
		entries = entries,
		tasks = tasks,
		tags = tag_count,
	}
end

function M.stats(cfg)
	local stats = M.stats_summary(cfg)
	return open_markdown_scratch("memo-stats.md", {
		"# Memo Stats",
		"",
		"- Memo path: " .. stats.path,
		"- Lines: " .. stats.lines,
		"- Entries: " .. stats.entries,
		"- Task lines: " .. stats.tasks,
		"- Unique tags: " .. stats.tags,
	})
end

function M.prune_blank(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return 0
	end

	local original = vim.fn.readfile(memo_path)
	local pruned = util.prune_blank_lines(original, 2)
	if #pruned == #original then
		vim.notify("Memo blank lines already look tidy", vim.log.levels.INFO)
		return 0
	end

	vim.fn.writefile(pruned, memo_path)
	local removed = #original - #pruned
	vim.notify("Removed " .. removed .. " extra blank memo lines", vim.log.levels.INFO)
	return removed
end

return M
