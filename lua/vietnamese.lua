local M = {}

--- Setup Vietnamese input
--- @param user_config UserConfig User configuration
M.setup = function(user_config)
	local require = require
	require("vietnamese.config").set_user_config(user_config)
	require("vietnamese.system-ime").setup()
	require("vietnamese.engine").setup()
	require("vietnamese.command")
end

return M
