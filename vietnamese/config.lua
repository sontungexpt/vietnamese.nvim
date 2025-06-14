local M = {}
local default_config = {
	input_method = "telex", -- Default input method
	custom_methods = {}, -- Custom input methods
}

function M.set_input_method(method)
	default_config.input_method = method
end

function M.set_user_config(user_config)
	if type(user_config) == "table" then
		for key, value in pairs(user_config) do
			default_config[key] = value
		end
	end
	return default_config
end

M.get_config = function()
	return default_config
end

return M
