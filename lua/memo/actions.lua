local M = {}

local util = require("memo.util")
local scratch = require("memo.scratch")
local index = require("memo.index")
local format = require("memo.format")
local prompt = require("memo.prompt")
local links = require("memo.links")
local archive = require("memo.archive")
local health = require("memo.health")
local query = require("memo.query")
local tasks = require("memo.tasks")
local journal = require("memo.journal")
local templates = require("memo.templates")
local collections = require("memo.collections")
local insights = require("memo.insights")
local review = require("memo.review")
local git_context = require("memo.git_context")
local dedupe = require("memo.dedupe")
local validate = require("memo.validate")
local version = require("memo.version")

local function current_memo_path(cfg)
	local _, _, git_root = util.get_context()
	return util.resolve_memo_path(git_root, cfg)
end

function M.search(query, cfg)
	if not query or query == "" then
		vim.notify("MemoSearch requires a query", vim.log.levels.WARN)
		return {}
	end

	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if line:lower():find(query:lower(), 1, true) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoSearch: " .. query,
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo matches for: " .. query, vim.log.levels.INFO)
	end

	return results
end

function M.export_lines(cfg)
	local filename, project, git_root = util.get_context()
	local memo_path = util.resolve_memo_path(git_root, cfg)
	local memo_lines = {}

	if vim.fn.filereadable(memo_path) == 1 then
		memo_lines = vim.fn.readfile(memo_path)
	end

	local lines = {
		"# Memo Context",
		"",
		"- Project: " .. project,
		"- Current file: " .. filename,
		"- Memo path: " .. memo_path,
		"- Git root: " .. (git_root or "(none)"),
		"",
		"## Instructions",
		"",
		"Use the memo entries below as working context. Preserve source paths and line numbers when they are relevant.",
		"",
		"## Memo",
		"",
	}

	if #memo_lines == 0 then
		table.insert(lines, "(memo file is empty or missing)")
	else
		vim.list_extend(lines, memo_lines)
	end

	return lines
end

function M.export(cfg)
	local lines = M.export_lines(cfg)
	return scratch.markdown("memo-export.md", lines)
end

function M.yank_last(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local lines = util.extract_last_entry(vim.fn.readfile(memo_path))
	local text = table.concat(lines, "\n")
	vim.fn.setreg('"', text)
	vim.fn.setreg("+", text)
	vim.notify("Yanked last memo entry", vim.log.levels.INFO)
	return lines
end

function M.todo(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if util.is_task_line(line) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoTodo",
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo tasks found", vim.log.levels.INFO)
	end

	return results
end

function M.today(cfg, date)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	date = date or os.date("%Y-%m-%d")
	local results = {}
	for lnum, line in ipairs(vim.fn.readfile(memo_path)) do
		if line:match("^## " .. vim.pesc(date)) then
			table.insert(results, {
				filename = memo_path,
				lnum = lnum,
				col = 1,
				text = line,
			})
		end
	end

	vim.fn.setqflist({}, " ", {
		title = "MemoToday: " .. date,
		items = results,
	})

	if #results > 0 then
		vim.cmd("copen")
	else
		vim.notify("No memo entries for: " .. date, vim.log.levels.INFO)
	end

	return results
end

function M.tag_summary(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return {}
	end

	local counts = {}
	for _, line in ipairs(vim.fn.readfile(memo_path)) do
		for _, tag in ipairs(util.extract_tags(line)) do
			counts[tag] = (counts[tag] or 0) + 1
		end
	end

	return counts
end

function M.tags(cfg)
	local counts = M.tag_summary(cfg)
	local tags = {}
	for tag in pairs(counts) do
		table.insert(tags, tag)
	end
	table.sort(tags)

	local lines = { "# Memo Tags", "" }
	if #tags == 0 then
		table.insert(lines, "(no tags found)")
	else
		for _, tag in ipairs(tags) do
			table.insert(lines, "- #" .. tag .. " (" .. counts[tag] .. ")")
		end
	end

	return scratch.markdown("memo-tags.md", lines)
end

function M.stats_summary(cfg)
	local memo_path = current_memo_path(cfg)
	local lines = {}
	if vim.fn.filereadable(memo_path) == 1 then
		lines = vim.fn.readfile(memo_path)
	end

	local entries = 0
	local tasks = 0
	local tags = {}
	for _, line in ipairs(lines) do
		if line:match("^## %d%d%d%d%-%d%d%-%d%d") then
			entries = entries + 1
		end
		if util.is_task_line(line) then
			tasks = tasks + 1
		end
		for _, tag in ipairs(util.extract_tags(line)) do
			tags[tag] = true
		end
	end

	local tag_count = 0
	for _ in pairs(tags) do
		tag_count = tag_count + 1
	end

	return {
		path = memo_path,
		lines = #lines,
		entries = entries,
		tasks = tasks,
		tags = tag_count,
	}
end

function M.stats(cfg)
	local stats = M.stats_summary(cfg)
	return scratch.markdown("memo-stats.md", {
		"# Memo Stats",
		"",
		"- Memo path: " .. stats.path,
		"- Lines: " .. stats.lines,
		"- Entries: " .. stats.entries,
		"- Task lines: " .. stats.tasks,
		"- Unique tags: " .. stats.tags,
	})
end

function M.prune_blank(cfg)
	local memo_path = current_memo_path(cfg)
	if vim.fn.filereadable(memo_path) == 0 then
		vim.notify("Memo file does not exist: " .. memo_path, vim.log.levels.WARN)
		return 0
	end

	local original = vim.fn.readfile(memo_path)
	local pruned = util.prune_blank_lines(original, 2)
	if #pruned == #original then
		vim.notify("Memo blank lines already look tidy", vim.log.levels.INFO)
		return 0
	end

	vim.fn.writefile(pruned, memo_path)
	local removed = #original - #pruned
	vim.notify("Removed " .. removed .. " extra blank memo lines", vim.log.levels.INFO)
	return removed
end

function M.index(cfg)
	return scratch.markdown("memo-index.md", format.index_markdown(index.load(cfg)))
end

function M.timeline(cfg)
	local loaded = index.load(cfg)
	local groups = index.by_date(loaded.entries)
	return scratch.markdown("memo-timeline.md", format.timeline_markdown(groups))
end

function M.filtered_export(cfg, args)
	local filters = index.parse_filter_args(args)
	local loaded = index.load(cfg)
	local entries = index.filter(loaded.entries, filters)
	return scratch.markdown("memo-filtered-export.md", format.entries_markdown(entries, {
		title = "# Memo Filtered Export",
		include_source = true,
	}))
end

function M.jsonl_export(cfg, args)
	local filters = index.parse_filter_args(args)
	local loaded = index.load(cfg)
	local entries = index.filter(loaded.entries, filters)
	local lines = format.entries_jsonl(entries)
	return scratch.jsonl("memo-export.jsonl", lines)
end

function M.open_source_from_entry(entry)
	if not entry or not entry.location or not entry.location.path then
		vim.notify("Memo entry has no source location", vim.log.levels.WARN)
		return false
	end

	local path = entry.location.path
	if not path:match("^/") then
		local cwd = vim.fn.getcwd()
		path = cwd .. "/" .. path
	end

	if vim.fn.filereadable(path) == 0 then
		vim.notify("Source file does not exist: " .. path, vim.log.levels.WARN)
		return false
	end

	vim.cmd("edit " .. vim.fn.fnameescape(path))
	if entry.location.line1 then
		vim.api.nvim_win_set_cursor(0, { entry.location.line1, 0 })
	end
	return true
end

function M.open_source(cfg)
	local loaded = index.load(cfg)
	if #loaded.entries == 0 then
		vim.notify("No memo entries found", vim.log.levels.WARN)
		return false
	end
	return M.open_source_from_entry(loaded.entries[1])
end

function M.prompt(cfg, args)
	local opts = prompt.parse_args(args)
	local lines = prompt.build_from_index(cfg, opts.prompt_kind or "summary", opts)
	return scratch.markdown("memo-prompt.md", lines)
end

function M.sources(cfg)
	return links.quickfix(cfg)
end

function M.broken_sources(cfg)
	local broken = links.broken_report(cfg)
	local items = {}
	for _, entry in ipairs(broken) do
		table.insert(items, {
			filename = entry.memo_path,
			lnum = entry.header_lnum or entry.start_lnum or 1,
			col = 1,
			text = entry.location and entry.location.text or "broken source",
		})
	end

	vim.fn.setqflist({}, " ", {
		title = "Memo Broken Sources",
		items = items,
	})
	if #items > 0 then
		vim.cmd("copen")
	else
		vim.notify("No broken memo source references", vim.log.levels.INFO)
	end
	return items
end

function M.health(cfg)
	return scratch.markdown("memo-health.md", health.to_markdown(health.check(cfg)))
end

function M.archive_before(cfg, date)
	if not date or date == "" then
		vim.notify("MemoArchiveBefore requires YYYY-MM-DD", vim.log.levels.WARN)
		return nil
	end
	local memo_path = current_memo_path(cfg)
	local result = archive.archive_file(memo_path, date)
	if result.error then
		vim.notify(result.error .. ": " .. memo_path, vim.log.levels.WARN)
	elseif result.archived == 0 then
		vim.notify("No memo entries before " .. date, vim.log.levels.INFO)
	else
		vim.notify("Archived " .. result.archived .. " memo entries to " .. result.archive_path, vim.log.levels.INFO)
	end
	return result
end

function M.query(cfg, args)
	local input = table.concat(args or {}, " ")
	local loaded = index.load(cfg)
	local entries = query.filter(loaded.entries, input)
	local parsed = query.parse(input)
	return scratch.markdown("memo-query.md", format.entries_markdown(entries, {
		title = "# Memo Query: " .. query.describe(parsed),
		include_source = true,
	}))
end

function M.task_report(cfg)
	local loaded = index.load(cfg)
	local all = {}
	for _, file in ipairs(index.memo_paths(cfg)) do
		if vim.fn.filereadable(file.path) == 1 then
			vim.list_extend(all, tasks.collect(vim.fn.readfile(file.path), file.path))
		end
	end
	return scratch.markdown("memo-tasks.md", tasks.markdown(all))
end

function M.digest(cfg)
	local loaded = index.load(cfg)
	return scratch.markdown("memo-digest.md", journal.digest(loaded.entries))
end

function M.standup(cfg)
	local loaded = index.load(cfg)
	return scratch.markdown("memo-standup.md", journal.standup(loaded.entries, os.date("%Y-%m-%d")))
end

function M.templates(cfg)
	return scratch.markdown("memo-templates.md", templates.markdown(cfg.templates))
end

function M.collections(cfg)
	return scratch.markdown("memo-collections.md", collections.list_markdown(cfg))
end

function M.collection(cfg, name)
	if not name or name == "" then
		vim.notify("MemoCollection requires a collection name", vim.log.levels.WARN)
		return nil
	end
	return scratch.markdown("memo-collection-" .. name .. ".md", collections.markdown(collections.run(name, cfg)))
end

function M.insights(cfg)
	local loaded = index.load(cfg)
	return scratch.markdown("memo-insights.md", insights.markdown(insights.analyze(loaded.entries)))
end

function M.recommendations(cfg)
	local loaded = index.load(cfg)
	return scratch.markdown("memo-recommendations.md", insights.recommendations(insights.analyze(loaded.entries)))
end

function M.review_pack(cfg, args)
	local loaded = index.load(cfg)
	local opts = {
		query = table.concat(args or {}, " "),
	}
	return scratch.markdown("memo-review-pack.md", review.pack(loaded.entries, opts))
end

function M.worktree_prompt(cfg)
	local loaded = index.load(cfg)
	local lines = {
		"# Memo Worktree Prompt",
		"",
		"Use the memo evidence and git context together. Identify likely intent, risks, missing tests, and next steps.",
		"",
	}
	vim.list_extend(lines, git_context.markdown(git_context.snapshot()))
	table.insert(lines, "")
	vim.list_extend(lines, format.entries_markdown(index.filter(loaded.entries, { limit = 20 }), {
		title = "## Recent Memo Evidence",
		include_source = true,
	}))
	return scratch.markdown("memo-worktree-prompt.md", lines)
end

function M.duplicates(cfg)
	local loaded = index.load(cfg)
	return scratch.markdown("memo-duplicates.md", dedupe.markdown(dedupe.find(loaded.entries)))
end

function M.validate(cfg)
	return scratch.markdown("memo-config-validation.md", validate.markdown(validate.config(cfg)))
end

function M.version()
	return scratch.markdown("memo-version.md", version.markdown())
end

return M
