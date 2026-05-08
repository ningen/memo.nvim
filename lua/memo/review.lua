local M = {}

local format = require("memo.format")
local insights = require("memo.insights")
local links = require("memo.links")
local query = require("memo.query")

function M.pack(entries, opts)
	opts = opts or {}
	local analysis = insights.analyze(entries)
	local broken = links.broken(entries)
	local risks = query.filter(entries, "tag:risk")
	local bugs = query.filter(entries, "tag:bug")
	local decisions = query.filter(entries, "tag:decision")

	local lines = {
		"# Memo Review Pack",
		"",
		"## Review Intent",
		"",
		"Use this pack to prepare a code review, design review, or LLM review prompt from memo evidence.",
		"Focus on correctness, missing tests, regressions, unclear decisions, and unresolved risks.",
		"",
		"## Signals",
		"",
		"- Entries: " .. analysis.entry_count,
		"- Task lines: " .. analysis.task_count,
		"- Broken source references: " .. #broken,
		"- Bug-tagged entries: " .. #bugs,
		"- Risk-tagged entries: " .. #risks,
		"- Decision-tagged entries: " .. #decisions,
		"",
	}

	vim.list_extend(lines, insights.recommendations(analysis))
	table.insert(lines, "")
	vim.list_extend(lines, format.entries_markdown(query.filter(entries, opts.query or ""), {
		title = "## Selected Evidence",
		include_source = true,
	}))
	return lines
end

return M
