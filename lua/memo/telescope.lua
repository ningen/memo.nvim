local M = {}

local parser = require("memo.parser")
local util = require("memo.util")

local function has_telescope()
	local ok = pcall(require, "telescope")
	return ok
end

local function memo_path(cfg)
	local _, _, git_root = util.get_context()
	return util.resolve_memo_path(git_root, cfg)
end

local function notify_missing()
	vim.notify("memo.nvim telescope integration requires nvim-telescope/telescope.nvim", vim.log.levels.WARN)
end

local function make_entry(memo_file, entry)
	return {
		value = entry,
		display = parser.entry_display(entry),
		ordinal = table.concat({
			parser.entry_display(entry),
			parser.entry_text(entry),
			table.concat(entry.tags or {}, " "),
		}, " "),
		filename = memo_file,
		lnum = entry.header_lnum,
		col = 1,
	}
end

local function picker(title, memo_file, entries)
	if not has_telescope() then
		notify_missing()
		return nil
	end

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local previewers = require("telescope.previewers")

	return pickers
		.new({}, {
			prompt_title = title,
			finder = finders.new_table({
				results = entries,
				entry_maker = function(entry)
					return make_entry(memo_file, entry)
				end,
			}),
			sorter = conf.generic_sorter({}),
			previewer = previewers.new_buffer_previewer({
				title = "Memo Entry",
				define_preview = function(self, selected)
					local entry = selected.value
					vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.lines)
					vim.bo[self.state.bufnr].filetype = "markdown"
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selected = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selected then
						vim.cmd("edit " .. vim.fn.fnameescape(memo_file))
						vim.api.nvim_win_set_cursor(0, { selected.value.header_lnum, 0 })
					end
				end)
				return true
			end,
		})
		:find()
end

function M.entries(cfg, opts)
	opts = opts or {}
	local path = opts.path or memo_path(cfg)
	local entries = parser.parse_file(path)
	return picker(opts.title or "Memo Entries", path, entries)
end

function M.search(cfg, query)
	local path = memo_path(cfg)
	local entries = parser.parse_file(path)
	if query and query ~= "" then
		entries = parser.find_by_text(entries, query)
	end
	return picker("Memo Search", path, entries)
end

function M.tags(cfg)
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

	if not has_telescope() then
		notify_missing()
		return nil
	end

	local tags = {}
	for tag, item in pairs(by_tag) do
		table.insert(tags, item)
	end
	table.sort(tags, function(a, b)
		if a.count == b.count then
			return a.tag < b.tag
		end
		return a.count > b.count
	end)

	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	return pickers
		.new({}, {
			prompt_title = "Memo Tags",
			finder = finders.new_table({
				results = tags,
				entry_maker = function(item)
					return {
						value = item,
						display = "#" .. item.tag .. " (" .. item.count .. ")",
						ordinal = item.tag,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selected = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if selected then
						picker("Memo #" .. selected.value.tag, path, selected.value.entries)
					end
				end)
				return true
			end,
		})
		:find()
end

return M
