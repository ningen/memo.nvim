local M = {}

M.defaults = {
	path = "~/memo.md",
	per_project = false,
	window = {
		width = 0.6,
		height = 0.4,
		border = "rounded",
		title_pos = "center",
		winblend = 20,
		number = false,
		relativenumber = false,
	},
	input_window = {
		width = 0.4,
		min_width = 30,
		max_width = 80,
		border = "rounded",
		title = " memo ",
		title_pos = "center",
		winblend = 10,
		number = false,
		relativenumber = false,
	},
	capture = {
		note_label = "memo",
		include_code = true,
	},
	templates = {},
	collections = {},
}

function M.build(opts)
	opts = opts or {}
	local cfg = vim.tbl_deep_extend("force", M.defaults, opts)
	cfg.path = vim.fn.expand(cfg.path)
	return cfg
end

return M
