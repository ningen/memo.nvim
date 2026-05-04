local M = {}

local win = nil
local buf = nil

-- M.setup 時に初期化
local MEMO_PATH = nil

local function toggle()
	-- 既に開いていたら閉じる
	if win and vim.api.nvim_win_is_valid(win) then
		vim.cmd("write")
		vim.api.nvim_win_close(win, true)
		win = nil
		return
	end

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		buf = vim.fn.bufadd(MEMO_PATH)
		vim.fn.bufload(buf)
		-- バッファリストなどで非表示にする
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
		title = "📝 memo.md ",
		title_pos = "center",
		border = "rounded",
	})

	vim.wo[win].winblend = 20

	vim.keymap.set("n", "q", function()
		if vim.api.nvim_win_is_valid(win) then
			vim.cmd("write")
			vim.api.nvim_win_close(win, true)
			win = nil
		end
	end, { buffer = buf, desc = "Close window" })
end

function M.setup(opts)
	opts = opts or {}
	MEMO_PATH = vim.fn.expand(opts.path or "~/memo.md")

	vim.api.nvim_create_user_command("Memo", toggle, {
		desc = "toggle memo window",
	})
end

return M
