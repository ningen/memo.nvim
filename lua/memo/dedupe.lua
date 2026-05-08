local M = {}

local parser = require("memo.parser")

local function normalize(text)
	text = tostring(text or ""):lower()
	text = text:gsub("%s+", " ")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

function M.key(entry)
	local location = entry.location and entry.location.text or ""
	local summary = parser.entry_summary(entry)
	return normalize(location .. " " .. summary)
end

function M.find(entries)
	local seen = {}
	local duplicates = {}
	for _, entry in ipairs(entries or {}) do
		local key = M.key(entry)
		if key ~= "" then
			if seen[key] then
				duplicates[key] = duplicates[key] or { seen[key] }
				table.insert(duplicates[key], entry)
			else
				seen[key] = entry
			end
		end
	end

	local groups = {}
	for key, group in pairs(duplicates) do
		table.insert(groups, {
			key = key,
			entries = group,
		})
	end
	table.sort(groups, function(a, b)
		return a.key < b.key
	end)
	return groups
end

function M.markdown(groups)
	local lines = {
		"# Memo Duplicate Candidates",
		"",
	}

	if #groups == 0 then
		table.insert(lines, "(no duplicate candidates)")
		return lines
	end

	for _, group in ipairs(groups) do
		table.insert(lines, "## " .. group.key)
		table.insert(lines, "")
		for _, entry in ipairs(group.entries) do
			table.insert(lines, "- " .. parser.entry_display(entry))
			table.insert(lines, "  memo: " .. (entry.memo_path or "(unknown)") .. ":" .. tostring(entry.header_lnum or entry.start_lnum or 1))
		end
		table.insert(lines, "")
	end

	return lines
end

return M
