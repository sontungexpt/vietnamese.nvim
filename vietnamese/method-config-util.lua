local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local list_contains = vim.list_contains

local M = {}

function M.is_tone_key(key_c, method_config)
	return method_config.tone_map[key_c:lower()] ~= nil
end
function M.is_shape_diacritic_key(key_c, method_config)
	key_c = key_c:lower()
	for _, v in pairs(method_config.shape_diacritic_map) do
		if v[key_c] then
			return true
		end
	end
	return false
end

function M.is_tone_removal(key_c, method_config)
	return list_contains(method_config.tone_removals, key_c:lower())
end

function M.tone_diacritic(diacritic_key, char, method_config)
	local diacritic_map = DIACRITIC_MAP[char]

	local diacritic = method_config.tone_map[diacritic_key]

	if diacritic and diacritic_map[diacritic] then
		return diacritic
	end

	return nil
end

function M.shape_diacritic(diacritic_key, char, method_config)
	local diacritic_map = DIACRITIC_MAP[char]
	if diacritic_map then
		local shape_diacritic_map = method_config.shape_diacritic_map[char:lower()]
		local diacritic = shape_diacritic_map and shape_diacritic_map[diacritic_key]
		if diacritic and diacritic_map[diacritic] then
			return diacritic
		end
	end
	return nil
end

function M.diacritic(diacritic_key, char, method_config)
	local diacritic = M.tone_diacritic(diacritic_key, char, method_config)
		or M.shape_diacritic(diacritic_key, char, method_config)
	if diacritic then
		return diacritic
	elseif
		list_contains(method_config.tone_removals, diacritic_key)
		and UTF8_VN_CHAR_DICT[char]
		and UTF8_VN_CHAR_DICT[char].tone
	then
		return CONSTANT.ENUM_DIACRITIC.REMOVAL
	end
	return nil
end

function M.is_diacritic_applicable(diacritic_key, applied_char, method_config)
	return M.diacritic(diacritic_key, applied_char, method_config) ~= nil
end
return M
