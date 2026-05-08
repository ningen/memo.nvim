local M = {}

local parser = require("memo.parser")

local CHECKBOX = "^(%s*%- %[)([ xX])(%]%s+)(.*)$"

function M.parse_line(line, lnum, memo_path)
	local prefix, mark, suffix, text = line:match(CHECKBOX)
	if prefix then
		return {
			kind = "checkbox",
			done = mark:lower() == "x",
			text = text,
			lnum = lnum,
			memo_path = memo_path,
			prefix = prefix,
			suffix = suffix,
		}
	end

	local keyword, rest = line:match("%f[%w](TODO)%f[%W]%s*:?%s*(.*)$")
	if not keyword then
		keyword, rest = line:match("%f[%w](FIXME)%f[%W]%s*:?%s*(.*)$")
	end
	if keyword then
		return {
			kind = keyword:lower(),
			done = false,
			text = rest ~= "" and rest or line,
			lnum = lnum,
			memo_path = memo_path,
		}
	end

	return nil
end

function M.collect(lines, memo_path)
	local tasks = {}
	local current_entry = nil
	for lnum, line in ipairs(lines or {}) do
		local header = parser.parse_header(line)
		if header then
			current_entry = header
		end
		local task = M.parse_line(line, lnum, memo_path)
		if task then
			task.entry = current_entry
			table.insert(tasks, task)
		end
	end
	return tasks
end

function M.toggle_line(line)
	local prefix, mark, suffix, text = line:match(CHECKBOX)
	if not prefix then
		return line, false
	end
	local next_mark = mark:lower() == "x" and " " or "x"
	return prefix .. next_mark .. suffix .. text, true
end

function M.summary(tasks)
	local total = #tasks
	local done = 0
	local open = 0
	local by_kind = {}
	for _, task in ipairs(tasks or {}) do
		if task.done then
			done = done + 1
		else
			open = open + 1
		end
		by_kind[task.kind] = (by_kind[task.kind] or 0) + 1
	end
	return {
		total = total,
		done = done,
		open = open,
		by_kind = by_kind,
	}
end

function M.markdown(tasks)
	local summary = M.summary(tasks)
	local lines = {
		"# Memo Tasks",
		"",
		"- Total: " .. summary.total,
		"- Open: " .. summary.open,
		"- Done: " .. summary.done,
		"",
	}

	for _, task in ipairs(tasks or {}) do
		local status = task.done and "x" or " "
		local where = task.memo_path .. ":" .. task.lnum
		table.insert(lines, "- [" .. status .. "] " .. task.text .. " (" .. where .. ")")
	end

	return lines
end

return M
