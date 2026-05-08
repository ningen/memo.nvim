local M = {}

local parser = require("memo.parser")

local function split_entries(lines)
	local entries = parser.parse_entries(lines)
	local ranges = {}
	for _, entry in ipairs(entries) do
		table.insert(ranges, {
			start_lnum = entry.start_lnum,
			end_lnum = entry.end_lnum,
			entry = entry,
		})
	end
	return ranges
end

local function append_range(out, lines, start_lnum, end_lnum)
	for i = start_lnum, end_lnum do
		table.insert(out, lines[i])
	end
end

local function before_date(entry, date)
	if not entry.date then
		return false
	end
	return entry.date < date
end

function M.plan(lines, date)
	local ranges = split_entries(lines)
	local archive_lines = {}
	local keep_lines = {}
	local cursor = 1
	local archived = 0

	for _, range in ipairs(ranges) do
		if cursor < range.start_lnum then
			append_range(keep_lines, lines, cursor, range.start_lnum - 1)
		end

		if before_date(range.entry, date) then
			append_range(archive_lines, lines, range.start_lnum, range.end_lnum)
			archived = archived + 1
		else
			append_range(keep_lines, lines, range.start_lnum, range.end_lnum)
		end
		cursor = range.end_lnum + 1
	end

	if cursor <= #lines then
		append_range(keep_lines, lines, cursor, #lines)
	end

	return {
		keep_lines = keep_lines,
		archive_lines = archive_lines,
		archived = archived,
	}
end

function M.archive_file(memo_path, date, archive_path)
	if vim.fn.filereadable(memo_path) == 0 then
		return {
			archived = 0,
			error = "memo file does not exist",
		}
	end

	local lines = vim.fn.readfile(memo_path)
	local planned = M.plan(lines, date)
	if planned.archived == 0 then
		return planned
	end

	archive_path = archive_path or (memo_path .. ".archive.md")
	local existing = {}
	if vim.fn.filereadable(archive_path) == 1 then
		existing = vim.fn.readfile(archive_path)
		if #existing > 0 and existing[#existing] ~= "" then
			table.insert(existing, "")
		end
	end
	vim.list_extend(existing, planned.archive_lines)

	vim.fn.writefile(planned.keep_lines, memo_path)
	vim.fn.writefile(existing, archive_path)
	planned.archive_path = archive_path
	return planned
end

return M
