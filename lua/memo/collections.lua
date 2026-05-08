local M = {}

local index = require("memo.index")
local query = require("memo.query")
local format = require("memo.format")

local DEFAULTS = {
	bugs = {
		query = "tag:bug",
		description = "Entries tagged as bugs.",
	},
	ideas = {
		query = "tag:idea",
		description = "Design ideas and possible improvements.",
	},
	open_tasks = {
		query = "TODO",
		description = "Entries containing TODO text.",
	},
}

function M.merge(user_collections)
	return vim.tbl_deep_extend("force", DEFAULTS, user_collections or {})
end

function M.names(collections)
	local names = {}
	for name in pairs(collections or DEFAULTS) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

function M.resolve(name, cfg)
	local collections = M.merge(cfg and cfg.collections or {})
	return collections[name]
end

function M.run(name, cfg)
	local collection = M.resolve(name, cfg)
	if not collection then
		return nil
	end

	local loaded = index.load(cfg)
	local entries = query.filter(loaded.entries, collection.query or "")
	return {
		name = name,
		description = collection.description,
		query = collection.query,
		entries = entries,
	}
end

function M.markdown(result)
	if not result then
		return {
			"# Memo Collection",
			"",
			"(unknown collection)",
		}
	end

	local lines = {
		"# Memo Collection: " .. result.name,
		"",
		"- Query: `" .. (result.query or "") .. "`",
		"- Description: " .. (result.description or ""),
		"- Entries: " .. #result.entries,
		"",
	}
	vim.list_extend(lines, format.entries_markdown(result.entries, {
		title = "## Entries",
		include_source = true,
	}))
	return lines
end

function M.list_markdown(cfg)
	local collections = M.merge(cfg and cfg.collections or {})
	local lines = {
		"# Memo Collections",
		"",
	}
	for _, name in ipairs(M.names(collections)) do
		local item = collections[name]
		table.insert(lines, "## " .. name)
		table.insert(lines, "")
		table.insert(lines, "- Query: `" .. (item.query or "") .. "`")
		table.insert(lines, "- Description: " .. (item.description or ""))
		table.insert(lines, "")
	end
	return lines
end

return M
