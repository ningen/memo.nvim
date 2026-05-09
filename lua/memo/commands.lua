local M = {}

local actions = require("memo.actions")
local completion = require("memo.completion")
local picker = require("memo.picker")
local snacks = require("memo.snacks")
local telescope = require("memo.telescope")
local window = require("memo.window")

local function current_range(cmd_opts)
	local line1 = cmd_opts.line1
	local line2 = cmd_opts.line2

	if cmd_opts.range == 0 then
		line1 = vim.api.nvim_win_get_cursor(0)[1]
		line2 = line1
	end

	return {
		line1 = line1,
		line2 = line2,
		filepath = vim.fn.expand("%:p"),
		lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false),
		filetype = vim.bo.filetype,
	}
end

local function register(name, callback, opts)
	vim.api.nvim_create_user_command(name, callback, opts or {})
end

function M.register(config)
	register("Memo", function(cmd_opts)
		local range_lines = nil
		local filetype = nil
		local range = nil

		if cmd_opts.range > 0 then
			local current = current_range(cmd_opts)
			range_lines = current.lines
			filetype = current.filetype
			range = {
				line1 = current.line1,
				line2 = current.line2,
				filepath = current.filepath,
			}
		end

		window.toggle(range_lines, filetype, config, range)
	end, {
		range = true,
		desc = "Toggle memo window",
	})

	register("MemoProject", function()
		window.toggle(nil, nil, vim.tbl_deep_extend("force", config, { per_project = true }), nil)
	end, { desc = "Toggle project memo window" })

	register("MemoGlobal", function()
		window.toggle(nil, nil, vim.tbl_deep_extend("force", config, { per_project = false }), nil)
	end, { desc = "Toggle global memo window" })

	register("MemoHere", function(cmd_opts)
		local current = current_range(cmd_opts)
		window.capture_here(current.lines, current.filetype, config, {
			line1 = current.line1,
			line2 = current.line2,
			filepath = current.filepath,
		})
	end, {
		range = true,
		desc = "Capture quick memo at current location",
	})

	register("MemoSearch", function(cmd_opts)
		actions.search(cmd_opts.args, config)
	end, { nargs = "+", desc = "Search memo and show matches in quickfix" })

	register("MemoTelescope", function()
		telescope.entries(config)
	end, { desc = "Browse memo entries with Telescope" })

	register("MemoSnacks", function()
		snacks.entries(config)
	end, { desc = "Browse memo entries with Snacks picker" })

	register("MemoPicker", function()
		picker.entries(config)
	end, { desc = "Browse memo entries with Snacks or Telescope" })

	register("MemoExport", function()
		actions.export(config)
	end, { desc = "Open an LLM-friendly memo export buffer" })

	register("MemoYankLast", function()
		actions.yank_last(config)
	end, { desc = "Yank the last memo entry" })

	register("MemoTodo", function()
		actions.todo(config)
	end, { desc = "List memo TODO items in quickfix" })

	register("MemoToday", function()
		actions.today(config)
	end, { desc = "List today's memo entries in quickfix" })

	register("MemoTags", function()
		actions.tags(config)
	end, { desc = "Open memo tag summary" })

	register("MemoStats", function()
		actions.stats(config)
	end, { desc = "Open memo statistics" })

	register("MemoPruneBlank", function()
		actions.prune_blank(config)
	end, { desc = "Remove excessive blank lines from memo" })

	register("MemoIndex", function()
		actions.index(config)
	end, { desc = "Open memo index overview" })

	register("MemoTimeline", function()
		actions.timeline(config)
	end, { desc = "Open memo timeline grouped by date" })

	register("MemoExportFiltered", function(cmd_opts)
		actions.filtered_export(config, cmd_opts.fargs)
	end, { nargs = "*", desc = "Open filtered memo export" })

	register("MemoExportJsonl", function(cmd_opts)
		actions.jsonl_export(config, cmd_opts.fargs)
	end, { nargs = "*", desc = "Open memo JSONL export" })

	register("MemoOpenSource", function()
		actions.open_source(config)
	end, { desc = "Open source file for the newest indexed memo entry" })

	register("MemoPrompt", function(cmd_opts)
		actions.prompt(config, cmd_opts.fargs)
	end, { nargs = "*", complete = completion.prompt_args, desc = "Open an LLM prompt built from memo entries" })

	register("MemoSources", function()
		actions.sources(config)
	end, { desc = "List readable memo source references in quickfix" })

	register("MemoBrokenSources", function()
		actions.broken_sources(config)
	end, { desc = "List broken memo source references in quickfix" })

	register("MemoHealth", function()
		actions.health(config)
	end, { desc = "Open memo health report" })

	register("MemoArchiveBefore", function(cmd_opts)
		actions.archive_before(config, cmd_opts.args)
	end, { nargs = 1, desc = "Archive memo entries before YYYY-MM-DD" })

	register("MemoQuery", function(cmd_opts)
		actions.query(config, cmd_opts.fargs)
	end, { nargs = "*", complete = completion.query_args, desc = "Query indexed memo entries" })

	register("MemoTaskReport", function()
		actions.task_report(config)
	end, { desc = "Open memo task report" })

	register("MemoDigest", function()
		actions.digest(config)
	end, { desc = "Open memo digest" })

	register("MemoStandup", function()
		actions.standup(config)
	end, { desc = "Open standup draft from today's memo" })

	register("MemoTemplates", function()
		actions.templates(config)
	end, { desc = "Open available memo capture templates" })

	register("MemoCollections", function()
		actions.collections(config)
	end, { desc = "Open memo collection list" })

	register("MemoCollection", function(cmd_opts)
		actions.collection(config, cmd_opts.args)
	end, {
		nargs = 1,
		complete = function(arg_lead)
			return completion.collection_names(config, arg_lead)
		end,
		desc = "Open a named memo collection",
	})

	register("MemoInsights", function()
		actions.insights(config)
	end, { desc = "Open memo insight report" })

	register("MemoRecommendations", function()
		actions.recommendations(config)
	end, { desc = "Open memo workflow recommendations" })

	register("MemoReviewPack", function(cmd_opts)
		actions.review_pack(config, cmd_opts.fargs)
	end, { nargs = "*", desc = "Open review pack from memo evidence" })

	register("MemoWorktreePrompt", function()
		actions.worktree_prompt(config)
	end, { desc = "Open memo plus git worktree prompt" })

	register("MemoDuplicates", function()
		actions.duplicates(config)
	end, { desc = "Open duplicate memo candidate report" })

	register("MemoValidateConfig", function()
		actions.validate(config)
	end, { desc = "Open memo configuration validation report" })

	register("MemoVersion", function()
		actions.version()
	end, { desc = "Open memo.nvim version report" })
end

return M
