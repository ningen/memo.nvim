local M = {}

local window = require("memo.window")
local actions = require("memo.actions")
local telescope = require("memo.telescope")

local config = {}

function M.setup(opts)
	opts = opts or {}
	config = vim.tbl_deep_extend("force", {
		path = "~/memo.md",
		per_project = opts.per_project or false,
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
	}, opts)
	config.path = vim.fn.expand(config.path)

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

	vim.api.nvim_create_user_command("MemoProject", function()
		local project_config = vim.tbl_deep_extend("force", config, { per_project = true })
		window.toggle(nil, nil, project_config, nil)
	end, {
		desc = "Toggle project memo window",
	})

	vim.api.nvim_create_user_command("MemoGlobal", function()
		local global_config = vim.tbl_deep_extend("force", config, { per_project = false })
		window.toggle(nil, nil, global_config, nil)
	end, {
		desc = "Toggle global memo window",
	})

	vim.api.nvim_create_user_command("MemoHere", function(cmd_opts)
		local line1 = cmd_opts.line1
		local line2 = cmd_opts.line2

		if cmd_opts.range == 0 then
			line1 = vim.api.nvim_win_get_cursor(0)[1]
			line2 = line1
		end

		local range_lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
		local range = {
			line1 = line1,
			line2 = line2,
			filepath = vim.fn.expand("%:p"),
		}

		window.capture_here(range_lines, vim.bo.filetype, config, range)
	end, {
		range = true,
		desc = "Capture quick memo at current location",
	})

	vim.api.nvim_create_user_command("MemoSearch", function(cmd_opts)
		actions.search(cmd_opts.args, config)
	end, {
		nargs = "+",
		desc = "Search memo and show matches in quickfix",
	})

	vim.api.nvim_create_user_command("MemoTelescope", function()
		telescope.entries(config)
	end, {
		desc = "Browse memo entries with Telescope",
	})

	vim.api.nvim_create_user_command("MemoExport", function()
		actions.export(config)
	end, {
		desc = "Open an LLM-friendly memo export buffer",
	})

	vim.api.nvim_create_user_command("MemoYankLast", function()
		actions.yank_last(config)
	end, {
		desc = "Yank the last memo entry",
	})

	vim.api.nvim_create_user_command("MemoTodo", function()
		actions.todo(config)
	end, {
		desc = "List memo TODO items in quickfix",
	})

	vim.api.nvim_create_user_command("MemoToday", function()
		actions.today(config)
	end, {
		desc = "List today's memo entries in quickfix",
	})

	vim.api.nvim_create_user_command("MemoTags", function()
		actions.tags(config)
	end, {
		desc = "Open memo tag summary",
	})

	vim.api.nvim_create_user_command("MemoStats", function()
		actions.stats(config)
	end, {
		desc = "Open memo statistics",
	})

	vim.api.nvim_create_user_command("MemoPruneBlank", function()
		actions.prune_blank(config)
	end, {
		desc = "Remove excessive blank lines from memo",
	})

	vim.api.nvim_create_user_command("MemoIndex", function()
		actions.index(config)
	end, {
		desc = "Open memo index overview",
	})

	vim.api.nvim_create_user_command("MemoTimeline", function()
		actions.timeline(config)
	end, {
		desc = "Open memo timeline grouped by date",
	})

	vim.api.nvim_create_user_command("MemoExportFiltered", function(cmd_opts)
		actions.filtered_export(config, cmd_opts.fargs)
	end, {
		nargs = "*",
		desc = "Open filtered memo export",
	})

	vim.api.nvim_create_user_command("MemoExportJsonl", function(cmd_opts)
		actions.jsonl_export(config, cmd_opts.fargs)
	end, {
		nargs = "*",
		desc = "Open memo JSONL export",
	})

	vim.api.nvim_create_user_command("MemoOpenSource", function()
		actions.open_source(config)
	end, {
		desc = "Open source file for the newest indexed memo entry",
	})

	vim.api.nvim_create_user_command("MemoPrompt", function(cmd_opts)
		actions.prompt(config, cmd_opts.fargs)
	end, {
		nargs = "*",
		desc = "Open an LLM prompt built from memo entries",
	})

	vim.api.nvim_create_user_command("MemoSources", function()
		actions.sources(config)
	end, {
		desc = "List readable memo source references in quickfix",
	})

	vim.api.nvim_create_user_command("MemoBrokenSources", function()
		actions.broken_sources(config)
	end, {
		desc = "List broken memo source references in quickfix",
	})

	vim.api.nvim_create_user_command("MemoHealth", function()
		actions.health(config)
	end, {
		desc = "Open memo health report",
	})

	vim.api.nvim_create_user_command("MemoArchiveBefore", function(cmd_opts)
		actions.archive_before(config, cmd_opts.args)
	end, {
		nargs = 1,
		desc = "Archive memo entries before YYYY-MM-DD",
	})

	vim.api.nvim_create_user_command("MemoQuery", function(cmd_opts)
		actions.query(config, cmd_opts.fargs)
	end, {
		nargs = "*",
		desc = "Query indexed memo entries",
	})

	vim.api.nvim_create_user_command("MemoTaskReport", function()
		actions.task_report(config)
	end, {
		desc = "Open memo task report",
	})

	vim.api.nvim_create_user_command("MemoDigest", function()
		actions.digest(config)
	end, {
		desc = "Open memo digest",
	})

	vim.api.nvim_create_user_command("MemoStandup", function()
		actions.standup(config)
	end, {
		desc = "Open standup draft from today's memo",
	})

	vim.api.nvim_create_user_command("MemoTemplates", function()
		actions.templates(config)
	end, {
		desc = "Open available memo capture templates",
	})

	vim.api.nvim_create_user_command("MemoCollections", function()
		actions.collections(config)
	end, {
		desc = "Open memo collection list",
	})

	vim.api.nvim_create_user_command("MemoCollection", function(cmd_opts)
		actions.collection(config, cmd_opts.args)
	end, {
		nargs = 1,
		desc = "Open a named memo collection",
	})

	vim.api.nvim_create_user_command("MemoInsights", function()
		actions.insights(config)
	end, {
		desc = "Open memo insight report",
	})

	vim.api.nvim_create_user_command("MemoRecommendations", function()
		actions.recommendations(config)
	end, {
		desc = "Open memo workflow recommendations",
	})

	vim.api.nvim_create_user_command("MemoReviewPack", function(cmd_opts)
		actions.review_pack(config, cmd_opts.fargs)
	end, {
		nargs = "*",
		desc = "Open review pack from memo evidence",
	})
end

return M
