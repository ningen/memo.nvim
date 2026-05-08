local M = {}

local parser = require("memo.parser")
local util = require("memo.util")

local function normalize(path)
	if not path or path == "" then
		return nil
	end
	return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

local function add_path(paths, seen, path, label)
	path = normalize(path)
	if not path or seen[path] then
		return
	end
	seen[path] = true
	table.insert(paths, {
		path = path,
		label = label,
	})
end

function M.memo_paths(cfg)
	cfg = cfg or {}
	local paths = {}
	local seen = {}
	local _, _, git_root = util.get_context()

	add_path(paths, seen, util.resolve_memo_path(git_root, cfg), "active")

	if cfg.path then
		add_path(paths, seen, cfg.path, "global")
	end

	if git_root then
		add_path(paths, seen, git_root .. "/.memo.md", "project")
	end

	for _, path in ipairs(cfg.extra_paths or {}) do
		add_path(paths, seen, path, "extra")
	end

	return paths
end

function M.load(cfg, opts)
	opts = opts or {}
	local entries = {}
	local files = {}
	local missing = {}

	for _, item in ipairs(M.memo_paths(cfg)) do
		if vim.fn.filereadable(item.path) == 1 then
			local parsed = parser.parse_file(item.path, opts)
			table.insert(files, {
				path = item.path,
				label = item.label,
				entries = #parsed,
			})
			for _, entry in ipairs(parsed) do
				entry.memo_path = item.path
				entry.memo_label = item.label
				table.insert(entries, entry)
			end
		else
			table.insert(missing, item)
		end
	end

	table.sort(entries, function(a, b)
		local ad = (a.date or "") .. " " .. (a.time or "")
		local bd = (b.date or "") .. " " .. (b.time or "")
		if ad == bd then
			return (a.memo_path or "") < (b.memo_path or "")
		end
		return ad > bd
	end)

	return {
		entries = entries,
		files = files,
		missing = missing,
	}
end

function M.unique_tags(entries)
	local counts = {}
	for _, entry in ipairs(entries or {}) do
		for _, tag in ipairs(entry.tags or {}) do
			counts[tag] = (counts[tag] or 0) + 1
		end
	end

	local tags = {}
	for tag, count in pairs(counts) do
		table.insert(tags, {
			tag = tag,
			count = count,
		})
	end
	table.sort(tags, function(a, b)
		if a.count == b.count then
			return a.tag < b.tag
		end
		return a.count > b.count
	end)
	return tags
end

function M.by_date(entries)
	local dates = {}
	for _, entry in ipairs(entries or {}) do
		local date = entry.date or "(unknown)"
		dates[date] = dates[date] or {
			date = date,
			entries = {},
		}
		table.insert(dates[date].entries, entry)
	end

	local out = {}
	for _, item in pairs(dates) do
		table.insert(out, item)
	end
	table.sort(out, function(a, b)
		return a.date > b.date
	end)
	return out
end

function M.by_project(entries)
	local projects = {}
	for _, entry in ipairs(entries or {}) do
		local project = entry.project or "(unknown)"
		projects[project] = projects[project] or {
			project = project,
			entries = {},
		}
		table.insert(projects[project].entries, entry)
	end

	local out = {}
	for _, item in pairs(projects) do
		table.insert(out, item)
	end
	table.sort(out, function(a, b)
		if #a.entries == #b.entries then
			return a.project < b.project
		end
		return #a.entries > #b.entries
	end)
	return out
end

function M.filter(entries, filters)
	filters = filters or {}
	local out = {}
	local query = filters.query and filters.query:lower() or nil
	local tag = filters.tag
	local date = filters.date
	local project = filters.project
	local limit = tonumber(filters.limit)

	for _, entry in ipairs(entries or {}) do
		local ok = true
		if query and not parser.entry_text(entry):lower():find(query, 1, true) then
			ok = false
		end
		if ok and tag then
			ok = false
			for _, entry_tag in ipairs(entry.tags or {}) do
				if entry_tag == tag then
					ok = true
					break
				end
			end
		end
		if ok and date and entry.date ~= date then
			ok = false
		end
		if ok and project and entry.project ~= project then
			ok = false
		end
		if ok then
			table.insert(out, entry)
			if limit and #out >= limit then
				break
			end
		end
	end

	return out
end

function M.parse_filter_args(args)
	local filters = {}
	for _, arg in ipairs(args or {}) do
		local key, value = arg:match("^%-%-([%w_-]+)=(.+)$")
		if key then
			filters[key:gsub("-", "_")] = value
		elseif arg ~= "" then
			filters.query = filters.query and (filters.query .. " " .. arg) or arg
		end
	end
	return filters
end

return M
