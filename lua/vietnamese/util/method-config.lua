local Codec = require("vietnamese.util.codec")
local DIACRITIC = Codec.DIACRITIC

local M = {}

--- This function checks if the key is in the list of tone keys defined in the method configuration.
--- @param key string The key pressed by the user.
--- @param method_config MethodConfig The method configuration containing tone keys.
--- @return boolean is_tone_key True if the key is a tone key, false otherwise.
function M.is_tone_key(key, method_config)
	return method_config.tone_keys[key:lower()] ~= nil
end

--- This function checks if the key is in the list of shape keys defined in the method configuration.
--- @param key string The key pressed by the user.
--- @param method_config MethodConfig The method configuration containing shape keys.
--- @return boolean is_shape True if the key is a shape key, false otherwise.
function M.is_shape_key(key, method_config)
	return method_config.shape_keys[key:lower()] ~= nil
end

--- Check if a key is a tone removal key.
--- This function checks if the key is in the list of tone removal keys defined in the method configuration.
--- @param key string The key pressed by the user.
--- @param method_config MethodConfig The method configuration containing tone removal keys.
--- @return boolean is_tone_removal_key True if the key is a tone removal key, false otherwise.
local function is_tone_removal_key(key, method_config)
	return method_config.tone_removal_keys[key:lower()]
end
M.is_tone_removal_key = is_tone_removal_key

--- Get the tone diacritic for a given key and base character.
--- If the key corresponds to a tone diacritic for the base character,
--- @param key string The key pressed by the user.
--- @param affected_char string The base character to which the diacritic is applied.
--- @param method_config MethodConfig The method configuration containing tone keys.
--- @return Diacritic|nil tone The tone ENUM_DIACRITIC
local function key_to_tone(key, affected_char, method_config)
	local tone = method_config.tone_keys[key:lower()]
	--- All vowels can come with a tone
	return tone and Codec.is_vn_vowel(affected_char) and tone or nil
end
M.key_to_tone = key_to_tone

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
--- @param method_config MethodConfig The method configuration containing shape keys.
--- @return Diacritic|nil shape The shape ENUM_DIACRITIC
local function key_to_shape(key, affected_char, method_config)
	--- check existence of shape_keys in method_config
	local shape_map = method_config.shape_keys[key:lower()]
	--- Get the shape diacritic defined for the base character
	local shape = shape_map and shape_map[Codec.base_lower(affected_char)] or nil
	--- If the key corresponds to a shape diacritic for the base character
	return (shape and Codec.diacritic_mergeable(affected_char, shape)) and shape or nil
end
M.key_to_shape = key_to_shape

--- Get the diacritic for a given key and base character.
--- This function checks if the key corresponds to a tone or shape diacritic for the base character.
--- @param key string The key pressed by the user.
--- @param affected_char string The base character to which the diacritic is applied.
--- @param method_config MethodConfig The method configuration containing tone and shape keys.
--- @return Diacritic|nil diacritic The diacritic ENUM_DIACRITIC
function M.key_to_diacritic(key, affected_char, method_config)
	local diacritic = key_to_tone(key, affected_char, method_config) or key_to_shape(key, affected_char, method_config)

	if diacritic then
		return diacritic
	elseif is_tone_removal_key(key, method_config) and Codec.has_tone(affected_char) then
		return DIACRITIC.Flat
	end
	return nil
end

function M.is_diacritic_applicable(diacritic_key, applied_char, method_config)
	return M.key_to_diacritic(diacritic_key, applied_char, method_config) ~= nil
end

function M.validate_config(method_config)
	local notifier = require("vietnamese.notifier")

	if type(method_config) ~= "table" then
		notifier.error("Method configuration must be a table.")
		return false
	end
	-- tone key and shape key must be different
	for key, _ in pairs(method_config.tone_keys) do
		if method_config.shape_keys[key] then
			notifier.error("Key '" .. key .. "' is both a tone key and a shape key in the method configuration.")
			return false
		end
	end
	for key, _ in pairs(method_config.shape_keys) do
		if method_config.tone_keys[key] then
			notifier.error("Key '" .. key .. "' is both a shape key and a tone key in the method configuration.")
			return false
		end
	end

	for key, _ in pairs(method_config.tone_removal_keys) do
		if method_config.tone_keys[key] then
			notifier.error("Key '" .. key .. "' is both a tone removal key and a tone key in the method configuration.")
			return false
		elseif method_config.shape_keys[key] then
			notifier.error(
				"Key '" .. key .. "' is both a tone removal key and a shape key in the method configuration."
			)
			return false
		end
	end

	-- if u or o is map with horn, then both u o is map for that key
	for key, shape_map in pairs(method_config.shape_keys) do
		if shape_map["u"] == DIACRITIC.Horn and shape_map["o"] ~= DIACRITIC.Horn then
			notifier.error(
				"Both 'u' and 'o' must be mapped to the same Horn for key '" .. key .. "' in the method configuration."
			)
			return false
		elseif shape_map["o"] == DIACRITIC.Horn and shape_map["u"] ~= DIACRITIC.Horn then
			notifier.error(
				"Both 'u' and 'o' must be mapped to the same Horn for key '" .. key .. "' in the method configuration."
			)
			return false
		end
	end

	return true
end

return M
