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

function M.make_capture(location, project, note, lines, filetype)
	local capture = M.make_header(location, project)

	if note and note ~= "" then
		vim.list_extend(capture, { "memo: " .. note, "" })
	end

	if lines and #lines > 0 then
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

return M
