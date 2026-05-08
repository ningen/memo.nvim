local util = require("memo.util")
local parser = require("memo.parser")

describe("make_header", function()
	it("returns 4 lines", function()
		local lines = util.make_header("test.lua", "myproject")
		assert.equals(4, #lines)
	end)

	it("starts and ends with empty lines", function()
		local lines = util.make_header("test.lua", "myproject")
		assert.equals("", lines[1])
		assert.equals("", lines[4])
	end)

	it("contains separator and metadata in line 3", function()
		local lines = util.make_header("test.lua", "myproject")
		assert.equals("---", lines[2])
		assert.truthy(lines[3]:match("myproject"))
		assert.truthy(lines[3]:match("test.lua"))
	end)

	it("includes a date in YYYY-MM-DD format", function()
		local lines = util.make_header("a.lua", "proj")
		assert.truthy(lines[3]:match("%d%d%d%d%-%d%d%-%d%d"))
	end)
end)

describe("make_location", function()
	it("uses a path relative to git root with selected line range", function()
		local location = util.make_location("/repo/lua/memo/init.lua", "/repo", 12, 20)
		assert.equals("lua/memo/init.lua:12-20", location)
	end)

	it("uses a single line suffix when start and end are the same", function()
		local location = util.make_location("/repo/lua/memo/init.lua", "/repo", 12, 12)
		assert.equals("lua/memo/init.lua:12", location)
	end)

	it("keeps the full path outside git root", function()
		local location = util.make_location("/tmp/scratch.lua", "/repo", 1, 2)
		assert.equals("/tmp/scratch.lua:1-2", location)
	end)
end)

describe("make_code_block", function()
	it("wraps lines in fenced code block with filetype", function()
		local block = util.make_code_block({ "local x = 1" }, "lua")
		assert.equals("```lua", block[1])
		assert.equals("local x = 1", block[2])
		assert.equals("```", block[3])
		assert.equals("", block[4])
	end)

	it("uses empty fence when filetype is nil", function()
		local block = util.make_code_block({ "line" }, nil)
		assert.equals("```", block[1])
	end)

	it("preserves all lines", function()
		local block = util.make_code_block({ "a", "b", "c" }, "python")
		assert.equals("```python", block[1])
		assert.equals("a", block[2])
		assert.equals("b", block[3])
		assert.equals("c", block[4])
		assert.equals("```", block[5])
		assert.equals("", block[6])
	end)
end)

describe("make_capture", function()
	it("includes note and source code block", function()
		local capture = util.make_capture("lua/memo/init.lua:1", "memo.nvim", "check this", { "local x = 1" }, "lua")
		assert.truthy(capture[3]:match("memo.nvim"))
		assert.truthy(capture[3]:match("lua/memo/init.lua:1"))
		assert.equals("memo: check this", capture[5])
		assert.equals("```lua", capture[7])
		assert.equals("local x = 1", capture[8])
	end)

	it("allows an empty note", function()
		local capture = util.make_capture("lua/memo/init.lua:1", "memo.nvim", "", { "local x = 1" }, "lua")
		assert.equals("```lua", capture[5])
		assert.equals("local x = 1", capture[6])
	end)

	it("allows custom note labels", function()
		local capture = util.make_capture("lua/memo/init.lua:1", "memo.nvim", "check this", {}, "lua", {
			note_label = "note",
		})
		assert.equals("note: check this", capture[5])
	end)

	it("can omit source code", function()
		local capture = util.make_capture("lua/memo/init.lua:1", "memo.nvim", "check this", { "local x = 1" }, "lua", {
			include_code = false,
		})
		assert.equals(nil, capture[7])
	end)
end)

describe("extract_last_entry", function()
	it("returns the last separator-delimited entry", function()
		local entry = util.extract_last_entry({
			"",
			"---",
			"## first",
			"",
			"",
			"---",
			"## second",
			"memo: keep",
		})

		assert.equals("", entry[1])
		assert.equals("---", entry[2])
		assert.equals("## second", entry[3])
		assert.equals("memo: keep", entry[4])
	end)

	it("returns all lines when no separator exists", function()
		local entry = util.extract_last_entry({ "one", "two" })
		assert.equals("one", entry[1])
		assert.equals("two", entry[2])
	end)
end)

describe("is_task_line", function()
	it("matches TODO, FIXME, and checkbox lines", function()
		assert.truthy(util.is_task_line("TODO: write tests"))
		assert.truthy(util.is_task_line("FIXME handle nil"))
		assert.truthy(util.is_task_line("- [ ] follow up"))
		assert.truthy(util.is_task_line("- [x] done"))
	end)

	it("does not match ordinary lines", function()
		assert.falsy(util.is_task_line("methodology note"))
		assert.falsy(util.is_task_line("plain memo"))
	end)
end)

describe("extract_tags", function()
	it("returns hashtag names", function()
		local tags = util.extract_tags("memo #bug #idea-1 #area_ui")

		assert.equals("bug", tags[1])
		assert.equals("idea-1", tags[2])
		assert.equals("area_ui", tags[3])
	end)
end)

describe("prune_blank_lines", function()
	it("keeps at most two consecutive blank lines by default", function()
		local lines = util.prune_blank_lines({ "a", "", "", "", "b", "", "", "c" })

		assert.equals(7, #lines)
		assert.equals("a", lines[1])
		assert.equals("", lines[2])
		assert.equals("", lines[3])
		assert.equals("b", lines[4])
	end)
end)

describe("parser", function()
	it("parses memo entries with metadata", function()
		local entries = parser.parse_entries({
			"",
			"---",
			"## 2026-05-09 12:30 | memo.nvim | lua/memo/init.lua:10-12",
			"",
			"memo: remember this #idea",
			"",
			"```lua",
			"local x = 1",
			"```",
			"",
		})

		assert.equals(1, #entries)
		assert.equals("2026-05-09", entries[1].date)
		assert.equals("12:30", entries[1].time)
		assert.equals("memo.nvim", entries[1].project)
		assert.equals("lua/memo/init.lua", entries[1].location.path)
		assert.equals(10, entries[1].location.line1)
		assert.equals(12, entries[1].location.line2)
		assert.equals("remember this #idea", entries[1].note.text)
		assert.equals("idea", entries[1].tags[1])
		assert.equals("lua", entries[1].code_blocks[1].language)
	end)

	it("filters entries by tag, date, and text", function()
		local entries = parser.parse_entries({
			"## 2026-05-09 10:00 | p | a.lua",
			"memo: alpha #one",
			"## 2026-05-10 10:00 | p | b.lua",
			"memo: beta #two",
		})

		assert.equals(1, #parser.find_by_tag(entries, "one"))
		assert.equals(1, #parser.find_by_date(entries, "2026-05-10"))
		assert.equals(1, #parser.find_by_text(entries, "beta"))
	end)
end)

describe("resolve_memo_path", function()
	it("returns configured path when per_project is false", function()
		local path = util.resolve_memo_path("/repo", { per_project = false, path = "/tmp/memo.md" })
		assert.equals("/tmp/memo.md", path)
	end)

	it("returns per-project path when per_project is true and git_root exists", function()
		local path = util.resolve_memo_path("/repo", { per_project = true, path = "/tmp/memo.md" })
		assert.equals("/repo/.memo.md", path)
	end)

	it("falls back to configured path when per_project is true but git_root is nil", function()
		local path = util.resolve_memo_path(nil, { per_project = true, path = "/tmp/memo.md" })
		assert.equals("/tmp/memo.md", path)
	end)
end)
