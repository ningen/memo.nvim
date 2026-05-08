local buffer = require("memo.buffer")

describe("append_lines", function()
	local buf

	before_each(function()
		buf = vim.api.nvim_create_buf(false, true)
		buffer.reset()
	end)

	after_each(function()
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("appends lines to empty buffer and returns last line number", function()
		-- nvim_create_buf starts with 1 empty line (line_count = 1)
		local last = buffer.append_lines(buf, { "line1", "line2" })
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.equals(3, last)
		assert.equals("", lines[1])
		assert.equals("line1", lines[2])
		assert.equals("line2", lines[3])
	end)

	it("appends after existing content", function()
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "existing" })
		local last = buffer.append_lines(buf, { "new" })
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.equals(2, last)
		assert.equals("existing", lines[1])
		assert.equals("new", lines[2])
	end)

	it("handles empty lines table", function()
		-- buffer starts with 1 empty line, so last = 1 + 0 = 1
		local last = buffer.append_lines(buf, {})
		assert.equals(1, last)
	end)
end)

describe("get_or_create", function()
	local tmpfile

	before_each(function()
		tmpfile = vim.fn.tempname() .. ".md"
		buffer.reset()
	end)

	after_each(function()
		vim.fn.delete(tmpfile)
	end)

	it("returns a valid buffer", function()
		local b = buffer.get_or_create(tmpfile)
		assert.truthy(vim.api.nvim_buf_is_valid(b))
	end)

	it("returns the same buffer on repeated calls", function()
		local b1 = buffer.get_or_create(tmpfile)
		local b2 = buffer.get_or_create(tmpfile)
		assert.equals(b1, b2)
	end)
end)
