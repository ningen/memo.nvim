local M = {}

local parser = require("memo.parser")

local function append(out, lines)
	for _, line in ipairs(lines) do
		table.insert(out, line)
	end
end

function M.entry_heading(entry)
	local bits = {}
	if entry.date then
		table.insert(bits, entry.date .. " " .. (entry.time or ""))
	end
	if entry.project then
		table.insert(bits, entry.project)
	end
	if entry.location and entry.location.text then
		table.insert(bits, entry.location.text)
	end
	return table.concat(bits, " | ")
end

function M.entry_markdown(entry, opts)
	opts = opts or {}
	local lines = {}
	table.insert(lines, "### " .. M.entry_heading(entry))
	table.insert(lines, "")
	if opts.include_source ~= false then
		table.insert(lines, "- Memo file: " .. (entry.memo_path or "(unknown)"))
		table.insert(lines, "- Memo line: " .. tostring(entry.header_lnum or entry.start_lnum or 1))
		if entry.location and entry.location.path then
			table.insert(lines, "- Source: " .. entry.location.text)
		end
		table.insert(lines, "")
	end
	append(lines, entry.lines or {})
	table.insert(lines, "")
	return lines
end

function M.entries_markdown(entries, opts)
	opts = opts or {}
	local lines = {
		opts.title or "# Memo Entries",
		"",
	}

	if #entries == 0 then
		table.insert(lines, "(no entries)")
		return lines
	end

	for _, entry in ipairs(entries) do
		append(lines, M.entry_markdown(entry, opts))
	end
	return lines
end

local function json_escape(value)
	value = tostring(value or "")
	value = value:gsub("\\", "\\\\")
	value = value:gsub('"', '\\"')
	value = value:gsub("\n", "\\n")
	value = value:gsub("\r", "\\r")
	value = value:gsub("\t", "\\t")
	return '"' .. value .. '"'
end

local function json_array(values)
	local out = {}
	for _, value in ipairs(values or {}) do
		table.insert(out, json_escape(value))
	end
	return "[" .. table.concat(out, ",") .. "]"
end

function M.entry_json(entry)
	local fields = {
		'"date":' .. json_escape(entry.date),
		'"time":' .. json_escape(entry.time),
		'"project":' .. json_escape(entry.project),
		'"location":' .. json_escape(entry.location and entry.location.text or ""),
		'"source_path":' .. json_escape(entry.location and entry.location.path or ""),
		'"memo_path":' .. json_escape(entry.memo_path),
		'"memo_line":' .. tostring(entry.header_lnum or entry.start_lnum or 1),
		'"summary":' .. json_escape(parser.entry_summary(entry)),
		'"tags":' .. json_array(entry.tags),
		'"text":' .. json_escape(parser.entry_text(entry)),
	}
	return "{" .. table.concat(fields, ",") .. "}"
end

function M.entries_jsonl(entries)
	local lines = {}
	for _, entry in ipairs(entries or {}) do
		table.insert(lines, M.entry_json(entry))
	end
	return lines
end

function M.timeline_markdown(groups)
	local lines = {
		"# Memo Timeline",
		"",
	}
	for _, group in ipairs(groups or {}) do
		table.insert(lines, "## " .. group.date)
		table.insert(lines, "")
		for _, entry in ipairs(group.entries) do
			table.insert(lines, "- " .. (entry.time or "--:--") .. " " .. (entry.project or "") .. " " .. (entry.location and entry.location.text or ""))
			local summary = parser.entry_summary(entry)
			if summary ~= "" then
				table.insert(lines, "  " .. summary)
			end
		end
		table.insert(lines, "")
	end
	return lines
end

function M.index_markdown(index)
	local lines = {
		"# Memo Index",
		"",
		"## Files",
		"",
	}

	for _, file in ipairs(index.files or {}) do
		table.insert(lines, "- " .. file.path .. " (" .. file.entries .. " entries, " .. file.label .. ")")
	end
	if #index.files == 0 then
		table.insert(lines, "(no readable memo files)")
	end

	table.insert(lines, "")
	table.insert(lines, "## Tags")
	table.insert(lines, "")
	local tags = require("memo.index").unique_tags(index.entries)
	for _, tag in ipairs(tags) do
		table.insert(lines, "- #" .. tag.tag .. " (" .. tag.count .. ")")
	end
	if #tags == 0 then
		table.insert(lines, "(no tags)")
	end

	table.insert(lines, "")
	table.insert(lines, "## Recent Entries")
	table.insert(lines, "")
	for i, entry in ipairs(index.entries or {}) do
		if i > 20 then
			break
		end
		table.insert(lines, "- " .. parser.entry_display(entry))
	end
	if #index.entries == 0 then
		table.insert(lines, "(no entries)")
	end

	return lines
end

return M
