local M = {}

local parser = require("memo.parser")
local util = require("memo.util")
local window = require("memo.window")

local function snacks()
	if _G.Snacks and _G.Snacks.picker then
		return _G.Snacks
	end
	local ok, mod = pcall(require, "snacks")
	if ok and mod and mod.picker then
		return mod
	end
	return nil
end

function M.available()
	return snacks() ~= nil
end

local function memo_path(cfg)
	local _, _, git_root = util.get_context()
	return util.resolve_memo_path(git_root, cfg)
end

local function notify_missing()
	vim.notify("memo.nvim snacks integration requires folke/snacks.nvim with picker enabled", vim.log.levels.WARN)
end

local function open_memo_entry(memo_file, entry, cfg)
	window.open_path(memo_file, cfg, {
		lnum = entry.header_lnum or entry.start_lnum or 1,
	})
end

local function make_item(memo_file, entry)
	local display = parser.entry_display(entry)
	return {
		text = display,
		file = memo_file,
		pos = { entry.header_lnum or entry.start_lnum or 1, 1 },
		entry = entry,
		preview = {
			text = parser.entry_text(entry),
			ft = "markdown",
		},
	}
end

local function entry_picker(title, memo_file, entries, cfg)
	local Snacks = snacks()
	if not Snacks then
		notify_missing()
		return nil
	end

	local items = {}
	for _, entry in ipairs(entries) do
		table.insert(items, make_item(memo_file, entry))
	end

	return Snacks.picker.pick({
		title = title,
		items = items,
		format = function(item)
			return {
				{ item.text },
			}
		end,
		preview = "preview",
		confirm = function(picker, item)
			picker:close()
			if item and item.entry then
				open_memo_entry(memo_file, item.entry, cfg)
			end
		end,
	})
end

function M.entries(cfg, opts)
	opts = opts or {}
	local path = opts.path or memo_path(cfg)
	local entries = parser.parse_file(path)
	return entry_picker(opts.title or "Memo Entries", path, entries, cfg)
end

function M.search(cfg, query)
	local path = memo_path(cfg)
	local entries = parser.parse_file(path)
	if query and query ~= "" then
		entries = parser.find_by_text(entries, query)
	end
	return entry_picker("Memo Search", path, entries, cfg)
end

function M.tags(cfg)
	local Snacks = snacks()
	if not Snacks then
		notify_missing()
		return nil
	end

	local path = memo_path(cfg)
	local entries = parser.parse_file(path)
	local by_tag = {}
	for _, entry in ipairs(entries) do
		for _, tag in ipairs(entry.tags or {}) do
			by_tag[tag] = by_tag[tag] or {
				tag = tag,
				count = 0,
				entries = {},
			}
			by_tag[tag].count = by_tag[tag].count + 1
			table.insert(by_tag[tag].entries, entry)
		end
	end

	local items = {}
	for _, item in pairs(by_tag) do
		table.insert(items, {
			text = "#" .. item.tag .. " (" .. item.count .. ")",
			tag = item.tag,
			entries = item.entries,
		})
	end
	table.sort(items, function(a, b)
		return a.text < b.text
	end)

	return Snacks.picker.pick({
		title = "Memo Tags",
		items = items,
		format = function(item)
			return {
				{ item.text },
			}
		end,
		confirm = function(picker, item)
			picker:close()
			if item then
				entry_picker("Memo #" .. item.tag, path, item.entries, cfg)
			end
		end,
	})
end

return M
