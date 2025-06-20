local M = {}

M.setup = function(user_config)
	local config = require("vietnamese.config").set_user_config(user_config)
	require("vietnamese.engine").setup(config)
end

return M
