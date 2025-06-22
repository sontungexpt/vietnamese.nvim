local M = {}
local default_config = {
	enabled = true,
	input_method = "telex", -- Default input method
	custom_methods = {}, -- Custom input methods
}

M.is_enabled = function()
	return default_config.enabled
end

M.toggle_enabled = function()
	default_config.enabled = not default_config.enabled
	return default_config.enabled
end

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
