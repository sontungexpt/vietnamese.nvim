local type = type
local SUPPORTED_METHODS = require("vietnamese.constant").SUPPORTED_METHODS
local METHOD_CONFIG_PATH = "vietnamese.method."

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

function M.get_input_method()
	return default_config.input_method
end

function M.set_input_method(method)
	default_config.input_method = method or "telex"
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

function M.get_method_config()
	local current_method = default_config.input_method

	local method_config = SUPPORTED_METHODS[current_method] and require(METHOD_CONFIG_PATH .. current_method)
		or default_config.custom_methods[current_method]

	if type(method_config) ~= "table" then
		require("vietnamese.notifier").error(
			"Invalid method configuration for '" .. current_method .. "'. Please check your configuration."
		)
		return nil
	end

	return method_config
end

function M.get_support_methods()
	return vim.list_extend(vim.tbl_keys(SUPPORTED_METHODS), vim.tbl_keys(default_config.custom_methods))
end

return M
