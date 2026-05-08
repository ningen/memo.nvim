local actions = require("memo.actions")
local index = require("memo.index")
local format = require("memo.format")

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
