local M = {}

local DEFAULTS = {
	bug = {
		"bug: ${note}",
		"",
		"- expected: ",
		"- actual: ",
		"- source: ${location}",
	},
	idea = {
		"idea: ${note}",
		"",
		"- why it matters: ",
		"- next step: ",
	},
	decision = {
		"decision: ${note}",
		"",
		"- context: ${location}",
		"- tradeoff: ",
		"- follow-up: ",
	},
	question = {
		"question: ${note}",
		"",
		"- source: ${location}",
		"- answer: ",
	},
}

function M.names(templates)
	local names = {}
	for name in pairs(templates or DEFAULTS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function M.merge(user_templates)
	return vim.tbl_deep_extend("force", DEFAULTS, user_templates or {})
end

local function replace_vars(line, vars)
	return (line:gsub("%${([%w_]+)}", function(key)
		return vars[key] or ""
	end))
end

function M.render(name, vars, templates)
	templates = M.merge(templates)
	local template = templates[name]
	if not template then
		return nil
	end

	local lines = {}
	for _, line in ipairs(template) do
		table.insert(lines, replace_vars(line, vars or {}))
	end
	return lines
end

function M.markdown(templates)
	templates = M.merge(templates)
	local lines = {
		"# Memo Templates",
		"",
	}
	for _, name in ipairs(M.names(templates)) do
		table.insert(lines, "## " .. name)
		table.insert(lines, "")
		table.insert(lines, "```")
		for _, line in ipairs(templates[name]) do
			table.insert(lines, line)
		end
		table.insert(lines, "```")
		table.insert(lines, "")
	end
	return lines
end

return M
