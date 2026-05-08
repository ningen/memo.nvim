local M = {}

local util = require("memo.util")
local buffer = require("memo.buffer")

local win = nil

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

function M.open(range_lines, filetype, cfg)
	local filename, project, git_root = util.get_context()
	local memo_path = util.resolve_memo_path(git_root, cfg)
	local b = buffer.get_or_create(memo_path)

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.4)
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
		title = title,
		title_pos = "center",
		border = "rounded",
	})

	vim.wo[win].winblend = 20

	local header = util.make_header(filename, project)
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

function M.toggle(range_lines, filetype, cfg)
	if M.is_open() then
		M.close()
	else
		M.open(range_lines, filetype, cfg)
	end
end

return M
