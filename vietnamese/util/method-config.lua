local util = require("vietnamese.util")
local ipairs = ipairs
local level = util.level

local CONSTANT = require("vietnamese.constant")
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP

local M = {}

function M.is_tone_key(key, method_config)
	return method_config.tone_keys[key:lower()] ~= nil
end

function M.is_shape_key(key, method_config)
	return method_config.shape_keys[key:lower()] ~= nil
end

--- Check if a key is a tone removal key.
--- This function checks if the key is in the list of tone removal keys defined in the method configuration.
--- @param key string The key pressed by the user.
--- @param method_config table The method configuration containing tone removal keys.
--- @return boolean True if the key is a tone removal key, false otherwise.
function M.is_tone_removal_key(key, method_config)
	return method_config.tone_removal_keys[key:lower()]
end

--- Get the tone diacritic for a given key and base character.
--- If the key corresponds to a tone diacritic for the base character,
--- @param key string The key pressed by the user.
--- @param affected_char string The base character to which the diacritic is applied.
--- @param method_config table The method configuration containing tone keys.
--- @param strict boolean|nil If true, uses the base character as is; if false, uses the level 2 form of the base character.
--- @return Diacritic|nil tone The tone ENUM_DIACRITIC
local function get_tone_diacritic(key, affected_char, method_config, strict)
	local tone = method_config.tone_keys[key:lower()]
	if not tone then
		return nil
	end

	local tone_map = DIACRITIC_MAP[strict and affected_char or level(affected_char, 2)]
	if tone_map and tone_map[tone] then
		return tone
	end
	return nil
end
M.get_tone_diacritic = get_tone_diacritic

function M.has_multi_shape_effects(key, method_config)
	local shape_map = method_config.shape_keys[key:lower()]
	if not shape_map then
		return false
	end
	local k, _ = next(shape_map)
	return next(shape_map, k) ~= nil
end

--- Get the shape diacritic for a given key and base character.
--- This function checks if the key corresponds to a shape diacritic for the base character.
--- @param key string The key pressed by the user.
--- @param affected_char string The base character to which the diacritic is applied.
--- @param method_config table The method configuration containing shape keys.
--- @param strict boolean|nil If true, uses the base character as is; if false, uses the level 1 form of the base character.
--- @return Diacritic|nil shape The shape ENUM_DIACRITIC
local function get_shape_diacritic(key, affected_char, method_config, strict)
	--- check existence of shape_keys in method_config
	local shape_map = method_config.shape_keys[key:lower()]
	if not shape_map then
		return nil
	end

	affected_char = strict and affected_char or util.level(affected_char, 1)
	local diacritic_map = DIACRITIC_MAP[affected_char]
	if not diacritic_map then
		return nil
	end

	local shape = shape_map[affected_char:lower()]
	return shape and diacritic_map[shape] and shape or nil
end
M.get_shape_diacritic = get_shape_diacritic

--- Get the diacritic for a given key and base character.
function M.get_diacritic(key, base_char, method_config, strict)
	local diacritic = get_tone_diacritic(key, base_char, method_config, strict)
		or get_shape_diacritic(key, base_char, method_config, strict)

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
