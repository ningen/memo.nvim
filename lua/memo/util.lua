local M = {}

function M.get_context()
	local filename = vim.fn.expand("%:t")
	if filename == "" then
		filename = "（no file）"
	end

	local filepath = vim.fn.expand("%:p:h")
	local result = vim.fn.systemlist("git -C " .. vim.fn.shellescape(filepath) .. " rev-parse --show-toplevel")
	local git_root = vim.v.shell_error == 0 and result[1] or nil
	local project = git_root and vim.fn.fnamemodify(git_root, ":t") or "（no git）"

	return filename, project, git_root
end

function M.resolve_memo_path(git_root, cfg)
	if cfg.per_project and git_root then
		return git_root .. "/.memo.md"
	end
	return cfg.path or vim.fn.expand("~/memo.md")
end

function M.make_header(filename, project)
	local date = os.date("%Y-%m-%d %H:%M")
	return {
		"",
		"---",
		"## " .. date .. " | " .. project .. " | " .. filename,
		"",
	}
end

function M.make_location(filepath, git_root, line1, line2)
	local path = filepath ~= "" and filepath or "（no file）"

	if git_root and filepath:sub(1, #git_root + 1) == git_root .. "/" then
		path = filepath:sub(#git_root + 2)
	end

	if line1 and line2 then
		if line1 == line2 then
			return path .. ":" .. line1
		end
		return path .. ":" .. line1 .. "-" .. line2
	end

	return path
end

function M.make_code_block(lines, filetype)
	local block = { "```" .. (filetype or "") }
	vim.list_extend(block, lines)
	vim.list_extend(block, { "```", "" })
	return block
end

function M.make_capture(location, project, note, lines, filetype, opts)
	opts = opts or {}
	local note_label = opts.note_label or "memo"
	local include_code = opts.include_code ~= false
	local capture = M.make_header(location, project)

	if note and note ~= "" then
		vim.list_extend(capture, { note_label .. ": " .. note, "" })
	end

	if include_code and lines and #lines > 0 then
		vim.list_extend(capture, M.make_code_block(lines, filetype))
	end

	return capture
end

function M.extract_last_entry(lines)
	local start = nil

	for i = #lines, 1, -1 do
		if lines[i] == "---" then
			start = i
			if i > 1 and lines[i - 1] == "" then
				start = i - 1
			end
			break
		end
	end

	if not start then
		return lines
	end

	local entry = {}
	for i = start, #lines do
		table.insert(entry, lines[i])
	end
	return entry
end

function M.is_task_line(line)
	return line:match("%f[%w]TODO%f[%W]")
		or line:match("%f[%w]FIXME%f[%W]")
		or line:match("^%s*%- %[[ xX]%]")
end

function M.extract_tags(line)
	local tags = {}
	for tag in line:gmatch("#([%w_-]+)") do
		table.insert(tags, tag)
	end
	return tags
end

function M.prune_blank_lines(lines, max_blank)
	max_blank = max_blank or 2
	local pruned = {}
	local blank_count = 0

	for _, line in ipairs(lines) do
		if line == "" then
			blank_count = blank_count + 1
			if blank_count <= max_blank then
				table.insert(pruned, line)
			end
		else
			blank_count = 0
			table.insert(pruned, line)
		end
	end

	return pruned
end

return M
