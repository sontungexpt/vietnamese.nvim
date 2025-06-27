local require = require
local M = {}

M.setup = function(user_config)
	require("vietnamese.config").set_user_config(user_config)
	require("vietnamese.engine").setup()
	require("vietnamese.command")
end

-- happy emojiA: 😊

return M
