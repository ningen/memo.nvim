local actions = require("memo.actions")

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
