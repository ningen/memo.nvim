local M = {}

local collections = require("memo.collections")
local prompt = require("memo.prompt")
local templates = require("memo.templates")

local function starts_with(value, prefix)
	return value:sub(1, #prefix) == prefix
end

local function filter(items, lead)
	local out = {}
	lead = lead or ""
	for _, item in ipairs(items or {}) do
		if starts_with(item, lead) then
			table.insert(out, item)
		end
	end
	return out
end

function M.collection_names(cfg, lead)
	return filter(collections.names(collections.merge(cfg and cfg.collections or {})), lead)
end

function M.prompt_args(_, cmdline)
	local words = {}
	for word in tostring(cmdline or ""):gmatch("%S+") do
		table.insert(words, word)
	end
	local lead = words[#words] or ""
	local candidates = {
		"--tag=",
		"--date=",
		"--project=",
		"--path=",
		"--limit=",
	}
	for _, kind in ipairs(prompt.available()) do
		table.insert(candidates, "--kind=" .. kind)
	end
	return filter(candidates, lead)
end

function M.template_names(cfg, lead)
	return filter(templates.names(templates.merge(cfg and cfg.templates or {})), lead)
end

function M.query_args(_, cmdline)
	local words = {}
	for word in tostring(cmdline or ""):gmatch("%S+") do
		table.insert(words, word)
	end
	local lead = words[#words] or ""
	return filter({
		"tag:",
		"notag:",
		"date:",
		"before:",
		"after:",
		"project:",
		"path:",
		"limit:",
	}, lead)
end

return M
