local M = {}

local index = require("memo.index")
local links = require("memo.links")

local function ok(message)
	return {
		level = "ok",
		message = message,
	}
end

local function warn(message)
	return {
		level = "warn",
		message = message,
	}
end

function M.check(cfg)
	local report = {}
	local paths = index.memo_paths(cfg)
	if #paths == 0 then
		table.insert(report, warn("No memo paths are configured"))
	else
		table.insert(report, ok("Configured memo paths: " .. #paths))
	end

	local loaded = index.load(cfg)
	if #loaded.files == 0 then
		table.insert(report, warn("No readable memo files found"))
	else
		table.insert(report, ok("Readable memo files: " .. #loaded.files))
	end

	if #loaded.entries == 0 then
		table.insert(report, warn("No structured memo entries found"))
	else
		table.insert(report, ok("Structured memo entries: " .. #loaded.entries))
	end

	local broken = links.broken(loaded.entries)
	if #broken > 0 then
		table.insert(report, warn("Broken source references: " .. #broken))
	else
		table.insert(report, ok("No broken source references detected"))
	end

	local has_telescope = pcall(require, "telescope")
	if has_telescope then
		table.insert(report, ok("Telescope is available"))
	else
		table.insert(report, warn("Telescope is not available; use quickfix commands instead"))
	end

	return report
end

function M.to_markdown(report)
	local lines = {
		"# Memo Health",
		"",
	}

	for _, item in ipairs(report or {}) do
		table.insert(lines, "- " .. item.level .. ": " .. item.message)
	end

	return lines
end

return M
