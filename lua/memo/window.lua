local M = {}

local util = require("memo.util")
local buffer = require("memo.buffer")

local win = nil
local input_win = nil

local function resolve_size(value, total)
	if type(value) == "number" and value > 0 and value <= 1 then
		return math.floor(total * value)
	end
	return math.floor(value)
end

local function apply_window_style(window_id, style)
	vim.wo[window_id].number = style.number or false
	vim.wo[window_id].relativenumber = style.relativenumber or false

	if style.winblend ~= nil then
		vim.wo[window_id].winblend = style.winblend
	end
end

function M.is_open()
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

function M.close()
	if not M.is_open() then
		return
	end
	local memo_buf = vim.api.nvim_win_get_buf(win)
	vim.api.nvim_buf_call(memo_buf, function()
		vim.cmd("write")
	end)
	vim.api.nvim_win_close(win, true)
	win = nil
end

function M.open(range_lines, filetype, cfg, range)
	local filename, project, git_root = util.get_context()
	local memo_path = util.resolve_memo_path(git_root, cfg)
	local b = buffer.get_or_create(memo_path)
	local style = cfg.window or {}

	local width = resolve_size(style.width or 0.6, vim.o.columns)
	local height = resolve_size(style.height or 0.4, vim.o.lines)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local title = cfg.per_project and git_root
		and (" 📝 " .. vim.fn.fnamemodify(git_root, ":t") .. "/.memo.md ")
		or " 📝 memo.md "

	win = vim.api.nvim_open_win(b, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		title = style.title or title,
		title_pos = style.title_pos or "center",
		border = style.border or "rounded",
	})

	apply_window_style(win, style)

	local location = nil
	if range then
		location = util.make_location(range.filepath, git_root, range.line1, range.line2)
	end

	local header = util.make_header(location or filename, project)
	local cursor_line = buffer.append_lines(b, header)

	if range_lines and #range_lines > 0 then
		local block = util.make_code_block(range_lines, filetype)
		cursor_line = buffer.append_lines(b, block)
	end

	vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })

	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = b, desc = "Close memo" })
end

function M.open_path(memo_path, cfg, opts)
	opts = opts or {}
	local b = buffer.get_or_create(memo_path)
	local style = cfg.window or {}

	local width = resolve_size(style.width or 0.6, vim.o.columns)
	local height = resolve_size(style.height or 0.4, vim.o.lines)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	local title = style.title or (" 📝 " .. vim.fn.fnamemodify(memo_path, ":t") .. " ")

	if M.is_open() then
		vim.api.nvim_win_close(win, true)
		win = nil
	end

	win = vim.api.nvim_open_win(b, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		title = title,
		title_pos = style.title_pos or "center",
		border = style.border or "rounded",
	})

	apply_window_style(win, style)

	if opts.lnum then
		local line_count = vim.api.nvim_buf_line_count(b)
		vim.api.nvim_win_set_cursor(win, { math.min(opts.lnum, line_count), 0 })
	end

	vim.keymap.set("n", "q", function()
		M.close()
	end, { buffer = b, desc = "Close memo" })

	return win
end

function M.toggle(range_lines, filetype, cfg, range)
	if M.is_open() then
		M.close()
	else
		M.open(range_lines, filetype, cfg, range)
	end
end

local function close_input()
	if input_win and vim.api.nvim_win_is_valid(input_win) then
		vim.api.nvim_win_close(input_win, true)
	end
	input_win = nil
end

local function append_capture(note, range_lines, filetype, cfg, range, context)
	local filename = context.filename
	local project = context.project
	local git_root = context.git_root
	local memo_path = util.resolve_memo_path(git_root, cfg)
	local b = buffer.get_or_create(memo_path)
	local location = range and util.make_location(range.filepath, git_root, range.line1, range.line2) or filename
	local lines = util.make_capture(location, project, note, range_lines, filetype, cfg.capture)

	buffer.append_lines(b, lines)
	vim.api.nvim_buf_call(b, function()
		vim.cmd("write")
	end)
end

function M.capture_here(range_lines, filetype, cfg, range)
	close_input()

	local filename, project, git_root = util.get_context()
	local context = {
		filename = filename,
		project = project,
		git_root = git_root,
	}
	local style = cfg.input_window or {}
	local width = resolve_size(style.width or 0.4, vim.o.columns)
	width = math.min(math.max(style.min_width or 30, width), style.max_width or 80)
	local row = math.floor((vim.o.lines - 1) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	local b = vim.api.nvim_create_buf(false, true)

	input_win = vim.api.nvim_open_win(b, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = 1,
		title = style.title or " memo ",
		title_pos = style.title_pos or "center",
		border = style.border or "rounded",
	})

	vim.bo[b].buftype = "nofile"
	vim.bo[b].bufhidden = "wipe"
	vim.bo[b].swapfile = false
	apply_window_style(input_win, style)

	local submitted = false
	local function submit()
		if submitted then
			return
		end
		submitted = true
		local note = vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] or ""
		close_input()
		append_capture(note, range_lines, filetype, cfg, range, context)
	end

	vim.keymap.set({ "n", "i" }, "<CR>", submit, { buffer = b, desc = "Save quick memo" })
	vim.keymap.set({ "n", "i" }, "<Esc>", close_input, { buffer = b, desc = "Cancel quick memo" })
	vim.keymap.set("n", "q", close_input, { buffer = b, desc = "Cancel quick memo" })

	vim.cmd("startinsert")
end

return M
