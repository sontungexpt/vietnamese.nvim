local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local list_contains = vim.list_contains

local M = {}

function M.is_tone_key(key, method_config)
	return method_config.tone_keys[key:lower()] ~= nil
end

function M.is_shape_diacritic_key(key, method_config)
	key = key:lower()
	for _, v in pairs(method_config.shape_diacritic_keys) do
		if v[key] then
			return true
		end
	end
	return false
end

function M.is_tone_remove_key(key, method_config)
	return list_contains(method_config.tone_remove_keys, key:lower())
end

function M.get_tone_diacritic(key, base_char, method_config)
	local diacritic_map = DIACRITIC_MAP[base_char]
	if diacritic_map then
		local diacritic = method_config.tone_keys[key]
		if diacritic and diacritic_map[diacritic] then
			return diacritic
		end
	end
	return nil
end

function M.get_shape_diacritic(key, base_char, method_config)
	local diacritic_map = DIACRITIC_MAP[base_char]
	if diacritic_map then
		local shape_diacritic_keys = method_config.shape_diacritic_keys[base_char:lower()]
		local diacritic = shape_diacritic_keys and shape_diacritic_keys[key]
		if diacritic and diacritic_map[diacritic] then
			return diacritic
		end
	end
	return nil
end

function M.get_diacritic(key, base_char, method_config)
	local diacritic = M.get_tone_diacritic(key, base_char, method_config)
		or M.get_shape_diacritic(key, base_char, method_config)

	if diacritic then
		return diacritic
	elseif
		M.is_tone_remove_key(key, method_config)
		and UTF8_VN_CHAR_DICT[base_char]
		and UTF8_VN_CHAR_DICT[base_char].tone
	then
		return CONSTANT.ENUM_DIACRITIC.REMOVE
	end
	return nil
end

function M.is_diacritic_applicable(diacritic_key, applied_char, method_config)
	return M.get_diacritic(diacritic_key, applied_char, method_config) ~= nil
end
return M
