local M = {}

local snacks = require("memo.snacks")
local telescope = require("memo.telescope")

local function prefer_snacks()
	return snacks.available()
end

function M.entries(cfg, opts)
	if prefer_snacks() then
		return snacks.entries(cfg, opts)
	end
	return telescope.entries(cfg, opts)
end

function M.search(cfg, query)
	if prefer_snacks() then
		return snacks.search(cfg, query)
	end
	return telescope.search(cfg, query)
end

function M.tags(cfg)
	if prefer_snacks() then
		return snacks.tags(cfg)
	end
	return telescope.tags(cfg)
end

return M
