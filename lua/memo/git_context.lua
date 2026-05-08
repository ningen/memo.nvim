local M = {}

local function run(args, cwd)
	local cmd = { "git" }
	for _, arg in ipairs(args) do
		table.insert(cmd, arg)
	end
	local result = vim.system(cmd, {
		cwd = cwd or vim.fn.getcwd(),
		text = true,
	}):wait()
	if result.code ~= 0 then
		return nil, result.stderr
	end
	return result.stdout or ""
end

local function split_lines(text)
	local lines = {}
	for line in tostring(text or ""):gmatch("([^\n]*)\n?") do
		if line == "" and #lines > 0 and text:sub(-1) ~= "\n" then
			break
		end
		table.insert(lines, line)
	end
	if #lines == 1 and lines[1] == "" then
		return {}
	end
	return lines
end

function M.root()
	local out = run({ "rev-parse", "--show-toplevel" })
	if not out then
		return nil
	end
	return (out:gsub("%s+$", ""))
end

function M.branch(cwd)
	local out = run({ "branch", "--show-current" }, cwd)
	if not out then
		return "(unknown)"
	end
	local branch = out:gsub("%s+$", "")
	if branch == "" then
		return "(detached)"
	end
	return branch
end

function M.status(cwd)
	local out = run({ "status", "--short" }, cwd)
	return split_lines(out or "")
end

function M.changed_files(cwd)
	local out = run({ "diff", "--name-only", "HEAD" }, cwd)
	return split_lines(out or "")
end

function M.diff(cwd, opts)
	opts = opts or {}
	local args = { "diff" }
	if opts.staged then
		table.insert(args, "--cached")
	end
	if opts.stat then
		table.insert(args, "--stat")
	end
	if opts.limit then
		table.insert(args, "--unified=" .. opts.limit)
	end
	local out = run(args, cwd)
	return split_lines(out or "")
end

function M.snapshot(cwd)
	local root = cwd or M.root() or vim.fn.getcwd()
	return {
		root = root,
		branch = M.branch(root),
		status = M.status(root),
		changed_files = M.changed_files(root),
		diff_stat = M.diff(root, { stat = true }),
	}
end

function M.markdown(snapshot)
	local lines = {
		"# Git Context",
		"",
		"- Root: " .. (snapshot.root or "(unknown)"),
		"- Branch: " .. (snapshot.branch or "(unknown)"),
		"",
		"## Status",
		"",
	}

	if #(snapshot.status or {}) == 0 then
		table.insert(lines, "(clean)")
	else
		for _, line in ipairs(snapshot.status) do
			table.insert(lines, "```text")
			table.insert(lines, line)
			table.insert(lines, "```")
		end
	end

	table.insert(lines, "")
	table.insert(lines, "## Changed Files")
	table.insert(lines, "")
	if #(snapshot.changed_files or {}) == 0 then
		table.insert(lines, "(none)")
	else
		for _, file in ipairs(snapshot.changed_files) do
			table.insert(lines, "- " .. file)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "## Diff Stat")
	table.insert(lines, "")
	if #(snapshot.diff_stat or {}) == 0 then
		table.insert(lines, "(none)")
	else
		table.insert(lines, "```text")
		for _, line in ipairs(snapshot.diff_stat) do
			table.insert(lines, line)
		end
		table.insert(lines, "```")
	end

	return lines
end

return M
