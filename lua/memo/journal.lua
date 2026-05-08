local M = {}

local parser = require("memo.parser")

local function append(out, lines)
	for _, line in ipairs(lines) do
		table.insert(out, line)
	end
end

function M.digest(entries, opts)
	opts = opts or {}
	local title = opts.title or "# Memo Digest"
	local lines = { title, "" }

	if #entries == 0 then
		table.insert(lines, "(no entries)")
		return lines
	end

	local current_date = nil
	for _, entry in ipairs(entries) do
		if entry.date ~= current_date then
			current_date = entry.date
			table.insert(lines, "## " .. (current_date or "(unknown date)"))
			table.insert(lines, "")
		end
		local summary = parser.entry_summary(entry)
		local prefix = "- " .. (entry.time or "--:--")
		if entry.project then
			prefix = prefix .. " [" .. entry.project .. "]"
		end
		if entry.location and entry.location.text then
			prefix = prefix .. " " .. entry.location.text
		end
		table.insert(lines, prefix)
		if summary ~= "" then
			table.insert(lines, "  " .. summary)
		end
	end

	return lines
end

function M.standup(entries, date)
	local today = {}
	local blockers = {}
	local todos = {}
	for _, entry in ipairs(entries or {}) do
		if not date or entry.date == date then
			table.insert(today, entry)
			local text = parser.entry_text(entry)
			if text:lower():find("block", 1, true) then
				table.insert(blockers, entry)
			end
			if text:find("TODO", 1, true) or text:find("- [ ]", 1, true) then
				table.insert(todos, entry)
			end
		end
	end

	local lines = {
		"# Standup From Memo",
		"",
		"## Done / Observed",
		"",
	}
	append(lines, M.digest(today, { title = "" }))
	table.insert(lines, "")
	table.insert(lines, "## TODO")
	table.insert(lines, "")
	for _, entry in ipairs(todos) do
		table.insert(lines, "- " .. parser.entry_display(entry))
	end
	if #todos == 0 then
		table.insert(lines, "(none)")
	end
	table.insert(lines, "")
	table.insert(lines, "## Blockers")
	table.insert(lines, "")
	for _, entry in ipairs(blockers) do
		table.insert(lines, "- " .. parser.entry_display(entry))
	end
	if #blockers == 0 then
		table.insert(lines, "(none)")
	end
	return lines
end

return M
