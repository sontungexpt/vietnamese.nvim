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
	local shape = shape_map and shape_map[Codec.base(affected_char)] or nil
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

--- Validate the method configuration.
--- @param method_config MethodConfig The method configuration to validate.
--- @return boolean valid True if the method configuration is valid, false otherwise.
function M.validate_config(method_config)
	local notifier = require("vietnamese.notifier")
	if type(method_config) ~= "table" then
		notifier.error("Method configuration must be a table.")
		return false
	end

	local tone_keys = method_config.tone_keys or {}
	local shape_keys = method_config.shape_keys or {}
	local tone_rmv_keys = method_config.tone_removal_keys or {}

	----------------------------------------------------------------------
	-- 1. Check duplicate keys among tone_keys, shape_keys, tone_rmv_keys
	----------------------------------------------------------------------

	-- check tone vs shape
	for key in pairs(tone_keys) do
		if shape_keys[key] then
			notifier.error("Key '" .. key .. "' is both a tone key and a shape key.")
			return false
		end
	end

	-- check tone_rmv vs tone + shape
	for key in pairs(tone_rmv_keys) do
		if tone_keys[key] then
			notifier.error("Key '" .. key .. "' is both a tone removal key and a tone key.")
			return false
		end
		if shape_keys[key] then
			notifier.error("Key '" .. key .. "' is both a tone removal key and a shape key.")
			return false
		end
	end

	----------------------------------------------------------------------
	-- 2. Optimize Horn rule check for u / o
	----------------------------------------------------------------------
	for key, m in pairs(shape_keys) do
		local u = m["u"]
		local o = m["o"]
		-- If either u or o is mapped to Horn
		if u == DIACRITIC.Horn or o == DIACRITIC.Horn then
			if not (u == DIACRITIC.Horn and o == DIACRITIC.Horn) then
				notifier.error("Both 'u' and 'o' must be mapped to Horn for key '" .. key .. "'.")
				return false
			end
		end
	end

	return true
end

return M
