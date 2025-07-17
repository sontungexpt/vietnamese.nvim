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

local curr_method_config = nil

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

M.toggle_enabled = function()
	return M.set_enabled(not default_config.enabled)
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

M.set_user_config = function(user_config)
	merge_user_config(default_config, user_config)
end

M.get_config = function()
	return default_config
end

function M.get_method_config()
	if not curr_method_config then
		local current_method = default_config.input_method

		curr_method_config = vim.list_contains(SUPPORTED_METHODS, current_method)
				and require(METHOD_CONFIG_PATH .. current_method)
			or default_config.custom_methods[current_method]

		if type(curr_method_config) ~= "table" then
			require("vietnamese.notifier").error(
				"Invalid method configuration for '" .. current_method .. "'. Please check your configuration."
			)
			curr_method_config = require(METHOD_CONFIG_PATH .. SUPPORTED_METHODS[1]) -- Fallback
		end
	end

	return curr_method_config
end

function M.is_excluded_filetype(filetype)
	return type(filetype) == "string" and vim.list_contains(default_config.excluded.filetypes, filetype)
end

function M.is_excluded_buftype(buftype)
	return type(buftype) == "string" and vim.list_contains(default_config.excluded.buftypes, buftype)
end

function M.get_support_methods()
	return vim.list_extend(vim.deepcopy(SUPPORTED_METHODS), vim.tbl_keys(default_config.custom_methods))
end

return M
