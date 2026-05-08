local M = {}

local window = require("memo.window")

local config = {}

function M.setup(opts)
	opts = opts or {}
	config = {
		path = vim.fn.expand(opts.path or "~/memo.md"),
		per_project = opts.per_project or false,
	}

	vim.api.nvim_create_user_command("Memo", function(cmd_opts)
		local range_lines = nil
		local filetype = nil
		local range = nil

		if cmd_opts.range > 0 then
			filetype = vim.bo.filetype
			range_lines = vim.api.nvim_buf_get_lines(0, cmd_opts.line1 - 1, cmd_opts.line2, false)
			range = {
				line1 = cmd_opts.line1,
				line2 = cmd_opts.line2,
				filepath = vim.fn.expand("%:p"),
			}
		end

		window.toggle(range_lines, filetype, config, range)
	end, {
		range = true,
		desc = "Toggle memo window",
	})
end

return M
