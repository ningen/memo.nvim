local M = {}

local function split_words(input)
	local words = {}
	for word in tostring(input or ""):gmatch("%S+") do
		table.insert(words, word)
	end
	return words
end

function M.parse(input)
	local query = {
		text = {},
		tags = {},
		not_tags = {},
		date = nil,
		before = nil,
		after = nil,
		project = nil,
		path = nil,
		limit = nil,
	}

	for _, word in ipairs(split_words(input)) do
		local key, value = word:match("^([%w_-]+):(.+)$")
		if key == "tag" then
			table.insert(query.tags, value)
		elseif key == "notag" then
			table.insert(query.not_tags, value)
		elseif key == "date" then
			query.date = value
		elseif key == "before" then
			query.before = value
		elseif key == "after" then
			query.after = value
		elseif key == "project" then
			query.project = value
		elseif key == "path" then
			query.path = value
		elseif key == "limit" then
			query.limit = tonumber(value)
		else
			table.insert(query.text, word)
		end
	end

	query.text_query = table.concat(query.text, " ")
	return query
end

local function has_tag(entry, tag)
	for _, entry_tag in ipairs(entry.tags or {}) do
		if entry_tag == tag then
			return true
		end
	end
	return false
end

local function text_of(entry)
	return table.concat(entry.lines or {}, "\n"):lower()
end

function M.matches(entry, query)
	query = query or {}
	if query.date and entry.date ~= query.date then
		return false
	end
	if query.before and (not entry.date or entry.date >= query.before) then
		return false
	end
	if query.after and (not entry.date or entry.date <= query.after) then
		return false
	end
	if query.project and entry.project ~= query.project then
		return false
	end
	if query.path and (not entry.location or not entry.location.path or not entry.location.path:find(query.path, 1, true)) then
		return false
	end
	for _, tag in ipairs(query.tags or {}) do
		if not has_tag(entry, tag) then
			return false
		end
	end
	for _, tag in ipairs(query.not_tags or {}) do
		if has_tag(entry, tag) then
			return false
		end
	end
	if query.text_query and query.text_query ~= "" then
		if not text_of(entry):find(query.text_query:lower(), 1, true) then
			return false
		end
	end
	return true
end

function M.filter(entries, input)
	local parsed = type(input) == "table" and input or M.parse(input)
	local out = {}
	for _, entry in ipairs(entries or {}) do
		if M.matches(entry, parsed) then
			table.insert(out, entry)
			if parsed.limit and #out >= parsed.limit then
				break
			end
		end
	end
	return out
end

function M.describe(parsed)
	parsed = type(parsed) == "table" and parsed or M.parse(parsed)
	local parts = {}
	if parsed.text_query and parsed.text_query ~= "" then
		table.insert(parts, "text=" .. parsed.text_query)
	end
	for _, tag in ipairs(parsed.tags or {}) do
		table.insert(parts, "tag=" .. tag)
	end
	for _, tag in ipairs(parsed.not_tags or {}) do
		table.insert(parts, "notag=" .. tag)
	end
	for _, key in ipairs({ "date", "before", "after", "project", "path", "limit" }) do
		if parsed[key] then
			table.insert(parts, key .. "=" .. parsed[key])
		end
	end
	if #parts == 0 then
		return "(all entries)"
	end
	return table.concat(parts, ", ")
end

return M
