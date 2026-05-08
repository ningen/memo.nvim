local M = {}

local function issue(level, path, message)
	return {
		level = level,
		path = path,
		message = message,
	}
end

local function type_name(value)
	local t = type(value)
	if t == "nil" then
		return "nil"
	end
	return t
end

local function expect(report, cfg, path, expected)
	local value = cfg
	for part in path:gmatch("[^.]+") do
		if type(value) ~= "table" then
			table.insert(report, issue("warn", path, "expected " .. expected .. ", got " .. type_name(value)))
			return
		end
		value = value[part]
	end
	if value ~= nil and type(value) ~= expected then
		table.insert(report, issue("warn", path, "expected " .. expected .. ", got " .. type_name(value)))
	end
end

function M.config(cfg)
	cfg = cfg or {}
	local report = {}

	expect(report, cfg, "path", "string")
	expect(report, cfg, "per_project", "boolean")
	expect(report, cfg, "window.width", "number")
	expect(report, cfg, "window.height", "number")
	expect(report, cfg, "window.border", "string")
	expect(report, cfg, "input_window.width", "number")
	expect(report, cfg, "input_window.min_width", "number")
	expect(report, cfg, "input_window.max_width", "number")
	expect(report, cfg, "capture.note_label", "string")
	expect(report, cfg, "capture.include_code", "boolean")
	expect(report, cfg, "templates", "table")
	expect(report, cfg, "collections", "table")

	if cfg.input_window and cfg.input_window.min_width and cfg.input_window.max_width then
		if cfg.input_window.min_width > cfg.input_window.max_width then
			table.insert(report, issue("warn", "input_window", "min_width is greater than max_width"))
		end
	end

	if cfg.collections then
		for name, collection in pairs(cfg.collections) do
			if type(collection) ~= "table" then
				table.insert(report, issue("warn", "collections." .. name, "collection must be a table"))
			elseif type(collection.query) ~= "string" then
				table.insert(report, issue("warn", "collections." .. name .. ".query", "collection query must be a string"))
			end
		end
	end

	if cfg.templates then
		for name, template in pairs(cfg.templates) do
			if type(template) ~= "table" then
				table.insert(report, issue("warn", "templates." .. name, "template must be a list of lines"))
			end
		end
	end

	if #report == 0 then
		table.insert(report, issue("ok", "config", "configuration looks valid"))
	end

	return report
end

function M.markdown(report)
	local lines = {
		"# Memo Config Validation",
		"",
	}
	for _, item in ipairs(report or {}) do
		table.insert(lines, "- " .. item.level .. " `" .. item.path .. "`: " .. item.message)
	end
	return lines
end

return M
