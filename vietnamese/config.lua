local type = type
local SUPPORTED_METHODS = require("vietnamese.constant").SUPPORTED_METHODS
local METHOD_CONFIG_PATH = "vietnamese.method."

local M = {}
local current_method_config = nil

local default_config = {
	enabled = true,
	input_method = "telex", -- Default input method
	excluded = {
		filetypes = { "help" }, -- File types to exclude
		buftypes = { "nowrite", "quickfix", "prompt" }, -- Buffer types to excludek
	},
	custom_methods = {}, -- Custom input methods
}

M.is_enabled = function()
	return default_config.enabled
end

M.set_ennabled = function(enabled)
	default_config.enabled = enabled
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
	current_method_config = nil -- Reset cached method config
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
	if current_method_config then
		--- use cache for fastest
		return current_method_config
	end

	local current_method = default_config.input_method

	local method_config = SUPPORTED_METHODS[current_method] and require(METHOD_CONFIG_PATH .. current_method)
		or default_config.custom_methods[current_method]

	if type(method_config) ~= "table" then
		require("vietnamese.notifier").error(
			"Invalid method configuration for '" .. current_method .. "'. Please check your configuration."
		)
		method_config = require(METHOD_CONFIG_PATH .. next(SUPPORTED_METHODS)) -- Fallback to default method
	end

	current_method_config = method_config

	return method_config
end

function M.is_excluded_filetype(filetype)
	if not filetype or type(filetype) ~= "string" then
		return false
	end

	local excludes = default_config.excluded.filetypes or {}
	return vim.tbl_contains(excludes, filetype)
end

M.is_excluded = function(filetype, buftype)
	local excluded = default_config.excluded or {}
	if type(filetype) == "string" then
		if vim.tbl_contains(excluded.filetypes or {}, filetype) then
			return true
		end
	end

	if type(buftype) == "string" then
		if vim.tbl_contains(excluded.buftypes or {}, buftype) then
			return true
		end
	end
	return false
end

function M.is_excluded_buftype(buftype)
	if not buftype or type(buftype) ~= "string" then
		return false
	end

	local excludes = default_config.excluded.buftypes or {}
	return vim.tbl_contains(excludes, buftype)
end

function M.get_support_methods()
	return vim.list_extend(vim.tbl_keys(SUPPORTED_METHODS), vim.tbl_keys(default_config.custom_methods))
end

return M
