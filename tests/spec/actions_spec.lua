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
