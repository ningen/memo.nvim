local M = {}

local win = nil
local bufs = {}
local MEMO_PATH = vim.fn.expand("~/memo.md")
local config = {}

local function get_context()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "（no file）"
	end

	local filepath = vim.fn.expand("%:p:h")
	local result = vim.fn.systemlist("git -C " .. filepath .. " rev-parse --show-toplevel")
	local git_root = vim.v.shell_error == 0 and result[1] or nil
	local project = git_root and vim.fn.fnamemodify(git_root, ":t") or "（no git）"

	return filename, project, git_root
end

local function resolve_memo_path(git_root)
	if config.per_project and git_root then
		return git_root .. "/.memo.md"
	end
	return MEMO_PATH
end

local function get_or_create_buf(memo_path)
	if bufs[memo_path] and vim.api.nvim_buf_is_valid(bufs[memo_path]) then
		return bufs[memo_path]
	end
	local b = vim.fn.bufadd(memo_path)
	vim.fn.bufload(b)
	vim.bo[b].buflisted = false
	bufs[memo_path] = b
	return b
end

local function make_header(filename, project)
	local date = os.date("%Y-%m-%d %H:%M")
	return {
		"",
		"---",
		"## " .. date .. " | " .. project .. " | " .. filename,
		"",
	}
end

local function make_code_block(lines, filetype)
	local block = { "```" .. (filetype or "") }
	vim.list_extend(block, lines)
	vim.list_extend(block, { "```", "" })
	return block
end

local function append_lines(target_buf, lines)
	local n = vim.api.nvim_buf_line_count(target_buf)
	vim.api.nvim_buf_set_lines(target_buf, n, -1, false, lines)
	return n + #lines
end

local function toggle(range_lines, filetype)
	if win and vim.api.nvim_win_is_valid(win) then
		local memo_buf = vim.api.nvim_win_get_buf(win)
		vim.api.nvim_buf_call(memo_buf, function()
			vim.cmd("write")
		end)
		vim.api.nvim_win_close(win, true)
		win = nil
		return
	end

	local filename, project, git_root = get_context()
	local memo_path = resolve_memo_path(git_root)
	local b = get_or_create_buf(memo_path)

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local title = config.per_project and git_root
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

	local header = make_header(filename, project)
	local cursor_line = append_lines(b, header)

	if range_lines and #range_lines > 0 then
		local block = make_code_block(range_lines, filetype)
		cursor_line = append_lines(b, block)
	end

	vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.cmd("write")
			vim.api.nvim_win_close(win, true)
			win = nil
		end
	end, { buffer = b, desc = "Close memo" })
end

function M.setup(opts)
	opts = opts or {}
	config = opts
	MEMO_PATH = vim.fn.expand(opts.path or "~/memo.md")

	vim.api.nvim_create_user_command("Memo", function(cmd_opts)
		local range_lines = nil
		local filetype = nil

		if cmd_opts.range > 0 then
			filetype = vim.bo.filetype
			range_lines = vim.api.nvim_buf_get_lines(0, cmd_opts.line1 - 1, cmd_opts.line2, false)
		end

		toggle(range_lines, filetype)
	end, {
		range = true,
		desc = "Toggle memo window",
	})
end

return M
