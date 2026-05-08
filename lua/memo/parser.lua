local M = {}

local HEADER_PATTERN = "^## (%d%d%d%d%-%d%d%-%d%d) (%d%d:%d%d) | (.-) | (.+)$"

local function trim(value)
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function clone_lines(lines, start_lnum, end_lnum)
	local out = {}
	for i = start_lnum, end_lnum do
		table.insert(out, lines[i])
	end
	return out
end

local function parse_location(location)
	local path, line1, line2 = location:match("^(.-):(%d+)%-(%d+)$")
	if path then
		return {
			text = location,
			path = path,
			line1 = tonumber(line1),
			line2 = tonumber(line2),
		}
	end

	path, line1 = location:match("^(.-):(%d+)$")
	if path then
		return {
			text = location,
			path = path,
			line1 = tonumber(line1),
			line2 = tonumber(line1),
		}
	end

	return {
		text = location,
		path = location,
		line1 = nil,
		line2 = nil,
	}
end

local function collect_tags(lines)
	local tags = {}
	local seen = {}
	for _, line in ipairs(lines) do
		for tag in line:gmatch("#([%w_-]+)") do
			if not seen[tag] then
				seen[tag] = true
				table.insert(tags, tag)
			end
		end
	end
	table.sort(tags)
	return tags
end

local function collect_note(lines)
	for _, line in ipairs(lines) do
		local label, text = line:match("^([%w_-]+):%s*(.+)$")
		if label and text then
			return {
				label = label,
				text = text,
			}
		end
	end
	return nil
end

local function collect_code(lines)
	local blocks = {}
	local in_block = false
	local current = nil

	for _, line in ipairs(lines) do
		if not in_block then
			local lang = line:match("^```(.*)$")
			if lang ~= nil then
				in_block = true
				current = {
					language = trim(lang),
					lines = {},
				}
			end
		elseif line == "```" then
			table.insert(blocks, current)
			current = nil
			in_block = false
		else
			table.insert(current.lines, line)
		end
	end

	return blocks
end

local function first_content_line(lines)
	for _, line in ipairs(lines) do
		if line ~= "" and line ~= "---" and not line:match("^## ") and not line:match("^```") then
			return line
		end
	end
	return ""
end

function M.parse_header(line)
	local date, time, project, location = line:match(HEADER_PATTERN)
	if not date then
		return nil
	end

	return {
		date = date,
		time = time,
		project = project,
		location = parse_location(location),
	}
end

function M.entry_summary(entry)
	local note = entry.note and entry.note.text or nil
	if note and note ~= "" then
		return note
	end
	return first_content_line(entry.lines)
end

function M.parse_entries(lines, opts)
	opts = opts or {}
	local entries = {}
	local current_start = nil
	local current_header = nil

	local function flush(end_lnum)
		if not current_start or not current_header then
			return
		end

		local entry_lines = clone_lines(lines, current_start, end_lnum)
		local entry = {
			index = #entries + 1,
			start_lnum = current_start,
			end_lnum = end_lnum,
			header_lnum = current_start,
			date = current_header.date,
			time = current_header.time,
			project = current_header.project,
			location = current_header.location,
			lines = entry_lines,
			tags = collect_tags(entry_lines),
			note = collect_note(entry_lines),
			code_blocks = collect_code(entry_lines),
		}
		entry.summary = M.entry_summary(entry)
		table.insert(entries, entry)
	end

	for lnum, line in ipairs(lines) do
		local header = M.parse_header(line)
		if header then
			flush(lnum - 1)
			current_start = lnum
			if lnum > 1 and lines[lnum - 1] == "---" then
				current_start = lnum - 1
			end
			if current_start > 1 and lines[current_start - 1] == "" then
				current_start = current_start - 1
			end
			current_header = header
		end
	end

	flush(#lines)

	if opts.include_orphan and #entries == 0 and #lines > 0 then
		table.insert(entries, {
			index = 1,
			start_lnum = 1,
			end_lnum = #lines,
			header_lnum = 1,
			date = nil,
			time = nil,
			project = nil,
			location = {
				text = "(unknown)",
				path = "(unknown)",
			},
			lines = lines,
			tags = collect_tags(lines),
			note = collect_note(lines),
			code_blocks = collect_code(lines),
			summary = first_content_line(lines),
		})
	end

	return entries
end

function M.parse_file(path, opts)
	if vim.fn.filereadable(path) == 0 then
		return {}
	end
	return M.parse_entries(vim.fn.readfile(path), opts)
end

function M.entry_display(entry)
	local parts = {}
	if entry.date then
		table.insert(parts, entry.date .. " " .. (entry.time or ""))
	end
	if entry.project then
		table.insert(parts, "[" .. entry.project .. "]")
	end
	if entry.location and entry.location.text then
		table.insert(parts, entry.location.text)
	end
	local summary = M.entry_summary(entry)
	if summary ~= "" then
		table.insert(parts, "- " .. summary)
	end
	return table.concat(parts, " ")
end

function M.entry_text(entry)
	return table.concat(entry.lines, "\n")
end

function M.filter_entries(entries, predicate)
	local out = {}
	for _, entry in ipairs(entries) do
		if predicate(entry) then
			table.insert(out, entry)
		end
	end
	return out
end

function M.find_by_tag(entries, tag)
	return M.filter_entries(entries, function(entry)
		for _, entry_tag in ipairs(entry.tags or {}) do
			if entry_tag == tag then
				return true
			end
		end
		return false
	end)
end

function M.find_by_date(entries, date)
	return M.filter_entries(entries, function(entry)
		return entry.date == date
	end)
end

function M.find_by_text(entries, query)
	local needle = query:lower()
	return M.filter_entries(entries, function(entry)
		return M.entry_text(entry):lower():find(needle, 1, true) ~= nil
	end)
end

return M
