local M = {}

local win = nil
local buf = nil
local MEMO_PATH = vim.fn.expand("~/memo.md")

local function get_context()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "（no file）"
	end

	local filepath = vim.fn.expand("%:p:h")
	local git_root = vim.fn.systemlist("git -C " .. filepath .. " rev-parse --show-toplevel")[1]
	local project = vim.v.shell_error == 0 and vim.fn.fnamemodify(git_root, ":t") or "（no git）"

	return filename, project
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

local function append_header(target_buf, lines)
	local line_count = vim.api.nvim_buf_line_count(target_buf)
	vim.api.nvim_buf_set_lines(target_buf, line_count, -1, false, lines)
	return line_count + 1
end

local function toggle()
	if win and vim.api.nvim_win_is_valid(win) then
		vim.cmd("write")
		vim.api.nvim_win_close(win, true)
		win = nil
		return
	end

	-- floatを開く前に元バッファのコンテキストを取得
	local filename, project = get_context()

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		buf = vim.fn.bufadd(MEMO_PATH)
		vim.fn.bufload(buf)
		vim.bo[buf].buflisted = false
	end

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.4)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		title = " 📝 memo.md ",
		title_pos = "center",
		border = "rounded",
	})

	vim.wo[win].winblend = 20

	-- ヘッダーを追記してカーソルをその行へ移動
	local header = make_header(filename, project)
	local cursor_line = append_header(buf, header)
	vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.cmd("write")
			vim.api.nvim_win_close(win, true)
			win = nil
		end
	end, { buffer = buf, desc = "Close memo" })
end

function M.setup(opts)
	opts = opts or {}
	MEMO_PATH = vim.fn.expand(opts.path or "~/memo.md")

	vim.api.nvim_create_user_command("Memo", toggle, {
		desc = "Toggle memo window",
	})
end

return M
