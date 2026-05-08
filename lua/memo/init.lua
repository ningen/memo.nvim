local M = {}

local config = require("memo.config")
local commands = require("memo.commands")

local current_config = {}

function M.setup(opts)
	current_config = config.build(opts)
	commands.register(current_config)
end

function M.config()
	return current_config
end

return M
