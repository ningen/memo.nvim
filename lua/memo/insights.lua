local M = {}

local parser = require("memo.parser")
local tasks = require("memo.tasks")

local function inc(table_, key)
	table_[key] = (table_[key] or 0) + 1
end

local function sorted_counts(counts)
	local out = {}
	for key, count in pairs(counts) do
		table.insert(out, {
			key = key,
			count = count,
		})
	end
	table.sort(out, function(a, b)
		if a.count == b.count then
			return a.key < b.key
		end
		return a.count > b.count
	end)
	return out
end

function M.analyze(entries)
	local projects = {}
	local paths = {}
	local tags = {}
	local dates = {}
	local tag_pairs = {}
	local task_count = 0
	local code_blocks = 0

	for _, entry in ipairs(entries or {}) do
		inc(projects, entry.project or "(unknown)")
		inc(dates, entry.date or "(unknown)")
		if entry.location and entry.location.path then
			inc(paths, entry.location.path)
		end
		for _, tag in ipairs(entry.tags or {}) do
			inc(tags, tag)
		end
		for i = 1, #(entry.tags or {}) do
			for j = i + 1, #(entry.tags or {}) do
				local a = entry.tags[i]
				local b = entry.tags[j]
				if b < a then
					a, b = b, a
				end
				inc(tag_pairs, a .. "+" .. b)
			end
		end
		for _, line in ipairs(entry.lines or {}) do
			if tasks.parse_line(line, 1, entry.memo_path) then
				task_count = task_count + 1
			end
		end
		code_blocks = code_blocks + #(entry.code_blocks or {})
	end

	return {
		entry_count = #(entries or {}),
		task_count = task_count,
		code_blocks = code_blocks,
		projects = sorted_counts(projects),
		paths = sorted_counts(paths),
		tags = sorted_counts(tags),
		dates = sorted_counts(dates),
		tag_pairs = sorted_counts(tag_pairs),
	}
end

local function append_counts(lines, title, counts, limit)
	table.insert(lines, "## " .. title)
	table.insert(lines, "")
	limit = limit or 10
	for i, item in ipairs(counts or {}) do
		if i > limit then
			break
		end
		table.insert(lines, "- " .. item.key .. ": " .. item.count)
	end
	if #(counts or {}) == 0 then
		table.insert(lines, "(none)")
	end
	table.insert(lines, "")
end

function M.markdown(analysis)
	local lines = {
		"# Memo Insights",
		"",
		"- Entries: " .. analysis.entry_count,
		"- Task lines: " .. analysis.task_count,
		"- Code blocks: " .. analysis.code_blocks,
		"",
	}
	append_counts(lines, "Projects", analysis.projects)
	append_counts(lines, "Source Hotspots", analysis.paths)
	append_counts(lines, "Tags", analysis.tags)
	append_counts(lines, "Tag Pairs", analysis.tag_pairs)
	append_counts(lines, "Dates", analysis.dates)
	return lines
end

function M.recommendations(analysis)
	local lines = {
		"# Memo Recommendations",
		"",
	}
	if analysis.entry_count == 0 then
		table.insert(lines, "- Start by capturing a few `MemoHere` notes before optimizing retrieval.")
	elseif analysis.task_count > 10 then
		table.insert(lines, "- Task markers are accumulating. Use `:MemoTaskReport` or move durable tasks into your tracker.")
	end
	if #(analysis.tags or {}) == 0 then
		table.insert(lines, "- No tags found. Add lightweight tags like `#bug`, `#idea`, or `#decision` when you want future grouping.")
	end
	if #(analysis.paths or {}) > 0 and analysis.paths[1].count > 5 then
		table.insert(lines, "- Many notes point at `" .. analysis.paths[1].key .. "`. Consider a focused refactor or review pass.")
	end
	if #lines == 2 then
		table.insert(lines, "- Memo signals look balanced. Keep capturing and use filtered exports when asking an LLM for help.")
	end
	return lines
end

return M
