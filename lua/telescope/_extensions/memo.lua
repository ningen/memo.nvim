local telescope = require("telescope")
local actions = require("memo.telescope")

return telescope.register_extension({
	exports = {
		entries = actions.entries,
		search = actions.search,
		tags = actions.tags,
	},
})
