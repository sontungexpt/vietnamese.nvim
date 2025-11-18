local type = type
local vim_bo = vim.bo

local METHOD_CONFIG_PATH = "vietnamese.method."
local SUPPORTED_METHODS = {
	"telex", -- Telex input method
	"vni", -- VNI input method
	"viqr", -- VIQR input method
}

---@enum OrthographyStragegy
local OrthographyStragegy = {
	MODERN = "modern", -- Modern tone strategy
	OLD = "old", -- Old tone strategy
}

local M = {
	OrthographyStragegy = OrthographyStragegy, -- Export ToneStrategy for external use
}

local active_method_config = nil

---@type Config
local default_config = {
	enabled = true,
	-- "old" | "modern"
	orthography = OrthographyStragegy.MODERN, -- Default tone strategy
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

M.get_orthography_stragegy = function()
	return default_config.orthography
end

--- Set the tone strategy for Vietnamese input
--- @param strategy OrthographyStragegy The tone strategy to set
M.set_orthography_stragegy = function(strategy)
	default_config.orthography = strategy
end

--- Check if Vietnamese input is enabled
--- @return boolean enabled True if Vietnamese input is enabled, false otherwise
M.is_enabled = function()
	return default_config.enabled
end

--- Check if a buffer is enabled for Vietnamese input
--- @param  bufnr integer Buffer number to Check
--- @return boolean True if the buffer is enabled, false otherwise
M.is_buf_enabled = function(bufnr)
	local bo = vim_bo[bufnr]
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

M.set_enabled = function(enabled)
	default_config.enabled = enabled
	if enabled then
		-- disable system IME if it was enabled
		require("vietnamese.system-ime").disable()
	else
		require("vietnamese.system-ime").enable()
	end
	return enabled
end

--- Toggle Vietnamese input
--- @return boolean enabled True if Vietnamese input is enabled, false otherwise
M.toggle_enabled = function()
	return M.set_enabled(not default_config.enabled)
end

function M.get_input_method()
	return default_config.input_method
end

function M.set_input_method(method)
	default_config.input_method = method or "telex"
	active_method_config = nil -- Reset cached method config
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
		for _, value in ipairs(overrides) do
			defaults[#defaults + 1] = value
		end
	end

	-- Deep merge dictionary-like tables
	for key, value in pairs(overrides) do
		defaults[key] = merge_user_config(defaults[key], value)
	end

	return defaults
end

--- Merge user config into the default config
M.set_user_config = function(user_config)
	merge_user_config(default_config, user_config)
end

M.get_config = function()
	return default_config
end

function M.get_method_config()
	if active_method_config then
		return active_method_config
	end

	local active_method = default_config.input_method
	if vim.list_contains(SUPPORTED_METHODS, active_method) then
		active_method_config = require(METHOD_CONFIG_PATH .. active_method)
	else
		local custom_config = default_config.custom_methods[active_method]
		active_method_config = require("vietnamese.util.method-config").validate_config(custom_config) and custom_config
			or require(METHOD_CONFIG_PATH .. SUPPORTED_METHODS[1]) -- Fallback to first supported method
	end

	return active_method_config
end

--- Get a list of all supported input methods
--- @return string[]
function M.get_support_methods()
	return vim.list_extend(vim.deepcopy(SUPPORTED_METHODS), vim.tbl_keys(default_config.custom_methods))
end

return M
