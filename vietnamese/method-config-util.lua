local util = require("vietnamese.util")
local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local list_contains = vim.list_contains

local M = {}

function M.is_tone_key(key, method_config)
	return method_config.tone_keys[key:lower()] ~= nil
end

function M.is_shape_key(key, method_config)
	key = key:lower()
	for _, v in pairs(method_config.shape_keys) do
		if v[key] then
			return true
		end
	end
	return false
end

function M.is_tone_removal_key(key, method_config)
	return list_contains(method_config.tone_remove_keys, key:lower())
end

--- Get the tone diacritic for a given key and base character.
--- If the key corresponds to a tone diacritic for the base character,
--- @param key string The key pressed by the user.
--- @param base_char string The base character to which the diacritic is applied.
--- @param method_config table The method configuration containing tone keys.
--- @param strict boolean If true, uses the base character as is; if false, uses the level 2 form of the base character.
--- @return 1|2|3|4|5|nil The tone ENUM_DIACRITIC
function M.get_tone_diacritic(key, base_char, method_config, strict)
	base_char = strict and base_char or util.level(base_char, 2)

	local diacritic_map = DIACRITIC_MAP[base_char]
	if diacritic_map then
		local diacritic = method_config.tone_keys[key]
		if diacritic and diacritic_map[diacritic] then
			return diacritic
		end
	end
	return nil
end

--- Get the shape diacritic for a given key and base character.
function M.get_shape(key, base_char, method_config, strict)
	base_char = strict and base_char or util.level(base_char, 1)
	local diacritic_map = DIACRITIC_MAP[base_char]
	if diacritic_map then
		local shape_keys = method_config.shape_keys[base_char:lower()]
		local diacritic = shape_keys and shape_keys[key]
		if diacritic and diacritic_map[diacritic] then
			return diacritic
		end
	end
	return nil
end

--- Get the diacritic for a given key and base character.
function M.get_diacritic(key, base_char, method_config, strict)
	local diacritic = M.get_tone_diacritic(key, base_char, method_config, strict)
		or M.get_shape(key, base_char, method_config, strict)

	if diacritic then
		return diacritic
	elseif
		M.is_tone_removal_key(key, method_config)
		and UTF8_VN_CHAR_DICT[base_char]
		and UTF8_VN_CHAR_DICT[base_char].tone
	then
		return CONSTANT.ENUM_DIACRITIC.TONE_REMOVAL
	end
	return nil
end

function M.is_diacritic_applicable(diacritic_key, applied_char, method_config)
	return M.get_diacritic(diacritic_key, applied_char, method_config) ~= nil
end
return M
