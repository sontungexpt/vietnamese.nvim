local type = type

local METHOD_CONFIG_PATH = "vietnamese.method."
local SUPPORTED_METHODS = {
	telex = true,
	vni = true,
}

local M = {}
local curr_method_config = nil

local default_config = {
	enabled = true,
	input_method = "telex", -- Default input method
	excluded = {
		filetypes = {
			"nvimtree", -- File types to exclude
			"help",
		}, -- File types to exclude
		buftypes = {
			"nowrite",
			"quickfix",
			"prompt",
		}, -- Buffer types to excludek
	},
	custom_methods = {}, -- Custom input methods
}

M.is_enabled = function()
	return default_config.enabled
end

--- Check if a buffer is enabled for Vietnamese input
--- @param  bufnr integer Buffer number to Check
--- @return boolean True if the buffer is enabled, false otherwise
M.is_buf_enabled = function(bufnr)
	local bo = vim.bo[bufnr]
	local filetype, buftype = bo.filetype, bo.buftype
	local excluded = default_config.excluded or {}
	for _, ft in ipairs(excluded.filetypes or {}) do
		if filetype == ft then
			return false
		end
	end
	for _, bt in ipairs(excluded.buftypes or {}) do
		if buftype == bt then
			return false
		end
	end

	return true
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
	curr_method_config = nil -- Reset cached method config
end

local function merge_user_config(defaults, overrides)
	-- Handle nil cases immediately
	if overrides == nil then
		return defaults
	elseif defaults == nil then
		return overrides
	end

	local default_type = type(defaults)
	local override_type = type(overrides)

	-- Handle type mismatch
	if default_type ~= override_type then
		return defaults
	-- Handle non-tables
	elseif default_type ~= "table" then
		return overrides
	end

	-- Handle array-like tables
	if defaults[1] ~= nil then
		return overrides
	end

	-- Deep merge dictionary-like tables
	for key, value in pairs(overrides) do
		defaults[key] = merge_user_config(defaults[key], value)
	end

	return defaults
end
M.set_user_config = function(user_config)
	merge_user_config(default_config, user_config)
end

M.get_config = function()
	return default_config
end

function M.get_method_config()
	if curr_method_config then
		--- use cache for fastest
		return curr_method_config
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

	curr_method_config = method_config

	return method_config
end

function M.is_excluded_filetype(filetype)
	if not filetype or type(filetype) ~= "string" then
		return false
	end

	local excludes = default_config.excluded.filetypes or {}
	return vim.tbl_contains(excludes, filetype)
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
