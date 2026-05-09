local actions = require("memo.actions")
local index = require("memo.index")
local format = require("memo.format")
local prompt = require("memo.prompt")
local archive = require("memo.archive")
local health = require("memo.health")
local query = require("memo.query")
local tasks = require("memo.tasks")
local journal = require("memo.journal")
local templates = require("memo.templates")
local collections = require("memo.collections")
local insights = require("memo.insights")
local review = require("memo.review")
local dedupe = require("memo.dedupe")
local git_context = require("memo.git_context")
local completion = require("memo.completion")
local validate = require("memo.validate")
local version = require("memo.version")
local config = require("memo.config")

describe("search", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"# memo",
			"alpha line",
			"Beta Line",
			"other",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
		vim.fn.setqflist({}, "r")
	end)

	it("finds case-insensitive literal matches", function()
		local results = actions.search("beta", { path = tmpfile, per_project = false })

		assert.equals(1, #results)
		assert.equals(3, results[1].lnum)
		assert.equals("Beta Line", results[1].text)
	end)

	it("returns no results for missing matches", function()
		local results = actions.search("missing", { path = tmpfile, per_project = false })

		assert.equals(0, #results)
	end)
end)

describe("export_lines", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"## entry",
			"memo: keep this",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("builds an LLM-friendly markdown payload", function()
		local lines = actions.export_lines({ path = tmpfile, per_project = false })
		local text = table.concat(lines, "\n")

		assert.truthy(text:match("# Memo Context"))
		assert.truthy(text:match("Memo path: " .. vim.pesc(tmpfile)))
		assert.truthy(text:match("memo: keep this"))
	end)
end)

describe("todo", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"plain",
			"TODO: one",
			"- [ ] two",
			"FIXME three",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
		vim.fn.setqflist({}, "r")
	end)

	it("lists task-like memo lines", function()
		local results = actions.todo({ path = tmpfile, per_project = false })

		assert.equals(3, #results)
		assert.equals(2, results[1].lnum)
		assert.equals(3, results[2].lnum)
		assert.equals(4, results[3].lnum)
	end)
end)

describe("today", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"## 2026-05-09 10:00 | project | a.lua",
			"memo",
			"## 2026-05-08 10:00 | project | b.lua",
			"memo",
			"## 2026-05-09 11:00 | project | c.lua",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
		vim.fn.setqflist({}, "r")
	end)

	it("lists entries for the requested date", function()
		local results = actions.today({ path = tmpfile, per_project = false }, "2026-05-09")

		assert.equals(2, #results)
		assert.equals(1, results[1].lnum)
		assert.equals(5, results[2].lnum)
	end)
end)

describe("tag_summary", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"memo #idea #bug",
			"another #idea",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("counts memo tags", function()
		local counts = actions.tag_summary({ path = tmpfile, per_project = false })

		assert.equals(2, counts.idea)
		assert.equals(1, counts.bug)
	end)
end)

describe("stats_summary", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"---",
			"## 2026-05-09 10:00 | project | a.lua",
			"memo #idea",
			"TODO: task",
			"---",
			"## 2026-05-09 11:00 | project | b.lua",
			"memo #bug #idea",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("counts memo size and indexed signals", function()
		local stats = actions.stats_summary({ path = tmpfile, per_project = false })

		assert.equals(7, stats.lines)
		assert.equals(2, stats.entries)
		assert.equals(1, stats.tasks)
		assert.equals(2, stats.tags)
	end)
end)

describe("prune_blank", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({ "a", "", "", "", "b" }, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("writes memo file with excessive blank lines removed", function()
		local removed = actions.prune_blank({ path = tmpfile, per_project = false })
		local lines = vim.fn.readfile(tmpfile)

		assert.equals(1, removed)
		assert.equals(4, #lines)
	end)
end)

describe("index and format actions", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"---",
			"## 2026-05-09 10:00 | project | a.lua:2",
			"memo: alpha #one",
			"---",
			"## 2026-05-10 11:00 | project | b.lua:3",
			"memo: beta #two",
		}, tmpfile)
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("loads indexed entries from configured memo paths", function()
		local loaded = index.load({ path = tmpfile, per_project = false })

		assert.equals(2, #loaded.entries)
		assert.equals(tmpfile, loaded.entries[1].memo_path)
		assert.equals("2026-05-10", loaded.entries[1].date)
	end)

	it("filters indexed entries by query and tag", function()
		local loaded = index.load({ path = tmpfile, per_project = false })
		local by_query = index.filter(loaded.entries, { query = "alpha" })
		local by_tag = index.filter(loaded.entries, { tag = "two" })

		assert.equals(1, #by_query)
		assert.equals("2026-05-09", by_query[1].date)
		assert.equals(1, #by_tag)
		assert.equals("2026-05-10", by_tag[1].date)
	end)

	it("formats entries as jsonl", function()
		local loaded = index.load({ path = tmpfile, per_project = false })
		local lines = format.entries_jsonl(loaded.entries)

		assert.equals(2, #lines)
		assert.truthy(lines[1]:match('"summary":"beta #two"'))
	end)
end)

describe("prompt", function()
	it("builds purpose-specific prompt text", function()
		local lines = prompt.build("debug", {
			{
				date = "2026-05-09",
				time = "10:00",
				project = "p",
				location = { text = "a.lua:1" },
				lines = { "memo: nil crash #bug" },
				tags = { "bug" },
				summary = "nil crash #bug",
			},
		})
		local text = table.concat(lines, "\n")

		assert.truthy(text:match("Memo Debug Prompt"))
		assert.truthy(text:match("debugging hypotheses"))
		assert.truthy(text:match("nil crash"))
	end)
end)

describe("archive", function()
	it("plans entries before the requested date", function()
		local planned = archive.plan({
			"---",
			"## 2026-05-08 10:00 | p | a.lua",
			"old",
			"---",
			"## 2026-05-09 10:00 | p | b.lua",
			"new",
		}, "2026-05-09")

		assert.equals(1, planned.archived)
		assert.equals("old", planned.archive_lines[3])
		assert.equals("new", planned.keep_lines[3])
	end)
end)

describe("health", function()
	it("returns a markdown health report", function()
		local report = health.to_markdown({
			{ level = "ok", message = "fine" },
			{ level = "warn", message = "careful" },
		})

		assert.equals("# Memo Health", report[1])
		assert.equals("- ok: fine", report[3])
		assert.equals("- warn: careful", report[4])
	end)
end)

describe("query", function()
	it("parses and matches structured memo query syntax", function()
		local parsed = query.parse("tag:bug after:2026-05-01 path:lua crash")
		local entry = {
			date = "2026-05-09",
			location = { path = "lua/memo/init.lua" },
			tags = { "bug" },
			lines = { "memo: crash happens" },
		}

		assert.equals("bug", parsed.tags[1])
		assert.truthy(query.matches(entry, parsed))
		assert.equals("text=crash, tag=bug, after=2026-05-01, path=lua", query.describe(parsed))
	end)
end)

describe("tasks", function()
	it("collects checkboxes and TODO lines", function()
		local found = tasks.collect({
			"## 2026-05-09 10:00 | p | a.lua",
			"- [ ] checkbox task",
			"TODO: keyword task",
		}, "/tmp/memo.md")

		assert.equals(2, #found)
		assert.equals("checkbox", found[1].kind)
		assert.equals("todo", found[2].kind)
	end)

	it("toggles markdown checkbox lines", function()
		local line, changed = tasks.toggle_line("- [ ] task")
		assert.truthy(changed)
		assert.equals("- [x] task", line)
	end)
end)

describe("journal", function()
	it("builds a standup draft from entries", function()
		local lines = journal.standup({
			{
				date = os.date("%Y-%m-%d"),
				time = "10:00",
				project = "p",
				location = { text = "a.lua" },
				lines = { "memo: TODO finish" },
				summary = "TODO finish",
			},
		}, os.date("%Y-%m-%d"))
		local text = table.concat(lines, "\n")

		assert.truthy(text:match("Standup From Memo"))
		assert.truthy(text:match("TODO finish"))
	end)
end)

describe("templates", function()
	it("renders capture templates with variables", function()
		local rendered = templates.render("bug", {
			note = "nil crash",
			location = "a.lua:1",
		})

		assert.equals("bug: nil crash", rendered[1])
		assert.equals("- source: a.lua:1", rendered[5])
	end)
end)

describe("collections", function()
	it("runs a named collection as a saved query", function()
		local tmpfile = vim.fn.tempname() .. ".md"
		vim.fn.writefile({
			"## 2026-05-09 10:00 | p | a.lua",
			"memo: broken #bug",
		}, tmpfile)

		local result = collections.run("bugs", { path = tmpfile, per_project = false })
		vim.fn.delete(tmpfile)

		assert.equals("bugs", result.name)
		assert.equals(1, #result.entries)
	end)
end)

describe("insights", function()
	it("analyzes entry signals and recommendations", function()
		local analysis = insights.analyze({
			{
				project = "p",
				date = "2026-05-09",
				location = { path = "a.lua" },
				tags = { "bug", "risk" },
				lines = { "TODO: fix" },
				code_blocks = { { language = "lua", lines = {} } },
			},
		})

		assert.equals(1, analysis.entry_count)
		assert.equals(1, analysis.task_count)
		assert.equals("bug+risk", analysis.tag_pairs[1].key)
		assert.truthy(table.concat(insights.recommendations(analysis), "\n"):match("Memo"))
	end)
end)

describe("review", function()
	it("builds a review pack from memo entries", function()
		local lines = review.pack({
			{
				date = "2026-05-09",
				time = "10:00",
				project = "p",
				location = { text = "a.lua", path = "a.lua" },
				tags = { "bug" },
				lines = { "memo: bug #bug" },
				summary = "bug #bug",
			},
		})

		local text = table.concat(lines, "\n")
		assert.truthy(text:match("Memo Review Pack"))
		assert.truthy(text:match("Bug%-tagged entries: 1"))
	end)
end)

describe("dedupe", function()
	it("finds duplicate entries by normalized location and summary", function()
		local entries = {
			{ location = { text = "a.lua:1" }, lines = { "memo: same" }, summary = "same" },
			{ location = { text = "a.lua:1" }, lines = { "memo: same" }, summary = "same" },
			{ location = { text = "b.lua:1" }, lines = { "memo: different" }, summary = "different" },
		}
		local groups = dedupe.find(entries)

		assert.equals(1, #groups)
		assert.equals(2, #groups[1].entries)
	end)
end)

describe("git_context", function()
	it("formats git snapshot markdown", function()
		local lines = git_context.markdown({
			root = "/repo",
			branch = "main",
			status = { " M lua/a.lua" },
			changed_files = { "lua/a.lua" },
			diff_stat = { " lua/a.lua | 1 +" },
		})
		local text = table.concat(lines, "\n")

		assert.truthy(text:match("Git Context"))
		assert.truthy(text:match("Branch: main"))
		assert.truthy(text:match("lua/a.lua"))
	end)
end)

describe("completion", function()
	it("completes collection names from defaults and config", function()
		local names = completion.collection_names({
			collections = {
				custom = { query = "tag:custom" },
			},
		}, "c")

		assert.equals("custom", names[1])
	end)

	it("completes prompt kind arguments", function()
		local args = completion.prompt_args(nil, "MemoPrompt --kind=d")

		assert.equals("--kind=debug", args[1])
	end)

	it("completes query prefixes", function()
		local args = completion.query_args(nil, "MemoQuery ta")

		assert.equals("tag:", args[1])
	end)
end)

describe("validate", function()
	it("reports valid configuration", function()
		local report = validate.config({
			path = "~/memo.md",
			per_project = false,
			window = { width = 0.6, height = 0.4, border = "rounded" },
			input_window = { width = 0.4, min_width = 30, max_width = 80 },
			capture = { note_label = "memo", include_code = true },
			templates = {},
			collections = {},
		})

		assert.equals("ok", report[1].level)
	end)

	it("warns for invalid collection query", function()
		local report = validate.config({
			collections = {
				bad = {},
			},
		})

		local text = table.concat(validate.markdown(report), "\n")
		assert.truthy(text:match("collections.bad.query"))
	end)
end)

describe("version", function()
	it("returns plugin version metadata", function()
		local info = version.info()

		assert.equals("memo.nvim", info.name)
		assert.truthy(info.version:match("%d+%.%d+%.%d+"))
	end)
end)

describe("config", function()
	it("builds defaults with expanded path", function()
		local cfg = config.build({})

		assert.equals(vim.fn.expand("~/memo.md"), cfg.path)
		assert.equals(false, cfg.per_project)
		assert.equals(0.6, cfg.window.width)
	end)

	it("merges user settings into defaults", function()
		local cfg = config.build({
			path = "~/custom-memo.md",
			window = {
				width = 0.8,
			},
		})

		assert.equals(vim.fn.expand("~/custom-memo.md"), cfg.path)
		assert.equals(0.8, cfg.window.width)
		assert.equals(0.4, cfg.window.height)
	end)
end)
