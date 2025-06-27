local util = require("vietnamese.util")

local CONSTANT = require("vietnamese.constant")
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP

local M = {}

function M.is_tone_key(key, method_config)
	return method_config.tone_keys[key:lower()] ~= nil
end

function M.is_shape_key(key, method_config)
	return method_config.shape_keys[key:lower()] ~= nil

	-- key =  key:lower()
	-- for _, v in pairs(method_config.shape_keys) do if v[key] then
	-- 		return true
	-- 	end
	-- end
	-- return false
end

--- Check if a key is a tone removal key.
--- This function checks if the key is in the list of tone removal keys defined in the method configuration.
--- @param key string The key pressed by the user.
--- @param method_config table The method configuration containing tone removal keys.
--- @return boolean True if the key is a tone removal key, false otherwise.
function M.is_tone_removal_key(key, method_config)
	for _, v in ipairs(method_config.tone_removal_keys) do
		if v == key:lower() then
			return true
		end
	end
	return false
end

--- Get the tone diacritic for a given key and base character.
--- If the key corresponds to a tone diacritic for the base character,
--- @param key string The key pressed by the user.
--- @param base_char string The base character to which the diacritic is applied.
--- @param method_config table The method configuration containing tone keys.
--- @param strict boolean|nil If true, uses the base character as is; if false, uses the level 2 form of the base character.
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

function M.has_multi_shape_effects(key, method_config)
	local shape_map = method_config.shape_keys[key:lower()]
	if not shape_map then
		return false
	end
	local k, _ = next(shape_map)
	return next(shape_map, k) ~= nil
end

--- Get the shape diacritic for a given key and base character.
function M.get_shape_diacritic(key, base_char, method_config, strict)
	--- check existence of shape_keys in method_config
	local shape_map = method_config.shape_keys[key:lower()]
	if not shape_map then
		return nil
	end

	base_char = strict and base_char or util.level(base_char, 1)
	local diacritic = shape_map[util.lower(base_char)]
	if not diacritic then
		return nil
	end

	-- check the valid diacritic in DIACRITIC_MAP
	local diacritic_map = DIACRITIC_MAP[base_char]
	if not diacritic_map or not diacritic_map[diacritic] then
		return nil
	end

	return diacritic

	-- base_char = strict and base_char or util.level(base_char, 1)
	-- local diacritic_map = DIACRITIC_MAP[base_char]
	-- if diacritic_map then
	-- 	local shape_keys = method_config.shape_keys[util.lower(base_char)]
	-- 	local diacritic = shape_keys and shape_keys[key]
	-- 	if diacritic and diacritic_map[diacritic] then
	-- 		return diacritic
	-- 	end
	-- end
	-- return nil
end

--- Get the diacritic for a given key and base character.
function M.get_diacritic(key, base_char, method_config, strict)
	local diacritic = M.get_tone_diacritic(key, base_char, method_config, strict)
		or M.get_shape_diacritic(key, base_char, method_config, strict)

	if diacritic then
		return diacritic
	elseif M.is_tone_removal_key(key, method_config) and util.has_tone_marked(base_char) then
		return CONSTANT.Diacritic.Flat
	end
	return nil
end

function M.is_diacritic_applicable(diacritic_key, applied_char, method_config)
	return M.get_diacritic(diacritic_key, applied_char, method_config) ~= nil
end
return M
