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
