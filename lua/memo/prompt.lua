local M = {}

local format = require("memo.format")
local index = require("memo.index")

local PROMPTS = {
	summary = {
		title = "Memo Summary Prompt",
		instruction = {
			"Summarize the memo context into concise, actionable bullets.",
			"Group related observations together.",
			"Preserve source paths and line numbers when they affect the conclusion.",
		},
	},
	plan = {
		title = "Memo Planning Prompt",
		instruction = {
			"Turn the memo context into an implementation plan.",
			"Call out dependencies, risks, and order of operations.",
			"Prefer small reversible steps when the memo suggests uncertainty.",
		},
	},
	review = {
		title = "Memo Review Prompt",
		instruction = {
			"Review the memo context as code-review evidence.",
			"Prioritize bugs, regressions, and missing tests.",
			"Quote source locations from the memo when possible.",
		},
	},
	debug = {
		title = "Memo Debug Prompt",
		instruction = {
			"Use the memo context to form debugging hypotheses.",
			"Separate observed facts from speculation.",
			"Suggest the next smallest checks to confirm or reject each hypothesis.",
		},
	},
	changelog = {
		title = "Memo Changelog Prompt",
		instruction = {
			"Convert the memo context into a user-facing changelog draft.",
			"Separate features, fixes, internal changes, and documentation.",
			"Keep the tone clear and concise.",
		},
	},
}

function M.available()
	local names = {}
	for name in pairs(PROMPTS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function M.definition(kind)
	return PROMPTS[kind or "summary"] or PROMPTS.summary
end

local function append(out, lines)
	for _, line in ipairs(lines) do
		table.insert(out, line)
	end
end

function M.build(kind, entries, opts)
	opts = opts or {}
	local def = M.definition(kind)
	local lines = {
		"# " .. def.title,
		"",
		"## Instructions",
		"",
	}

	for _, instruction in ipairs(def.instruction) do
		table.insert(lines, "- " .. instruction)
	end

	if opts.user_goal and opts.user_goal ~= "" then
		table.insert(lines, "")
		table.insert(lines, "## User Goal")
		table.insert(lines, "")
		table.insert(lines, opts.user_goal)
	end

	table.insert(lines, "")
	table.insert(lines, "## Context")
	table.insert(lines, "")

	append(lines, format.entries_markdown(entries, {
		title = "",
		include_source = true,
	}))

	return lines
end

function M.build_from_index(cfg, kind, filters)
	local loaded = index.load(cfg)
	local entries = index.filter(loaded.entries, filters or {})
	return M.build(kind, entries, filters or {})
end

function M.parse_args(args)
	local opts = index.parse_filter_args(args)
	if opts.kind then
		opts.prompt_kind = opts.kind
	end
	return opts
end

return M
