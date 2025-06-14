local CONSTANT = require("vietnamese.constant")
local M = {
	tone_chars = "12345",
	tone_map = {
		s = CONSTANT.TONE_ACUTE_INDEX,
		f = CONSTANT.TONE_GRAVE_INDEX,
		r = CONSTANT.TONE_HOOK_INDEX,
		x = CONSTANT.TONE_TILDE_INDEX,
		j = CONSTANT.TONE_DOT_INDEX,
	},
	tone_removal = { "z" },
}

return M

-- -- Telex input method
-- input_methods.telex = {
-- 	is_input_char = function(char)
-- 		return char:match("[a-z]") or char:match("[sfrxj]")
-- 	end,

-- 	apply_tones = function(text)
-- 		local tone_char, tone_index, count
-- 		local tone_keys = TONE_CHARS.telex

-- 		-- Find tone character and its positions
-- 		local positions = {}
-- 		for i = #text, 1, -1 do
-- 			local c = text:sub(i, i)
-- 			if tone_keys:find(c) then
-- 				tone_char = c
-- 				tone_index = TONE_MAP.telex[c]
-- 				table.insert(positions, i)
-- 			end
-- 		end

-- 		if not tone_char then
-- 			return text
-- 		end
-- 		count = #positions

-- 		-- Remove all tone characters
-- 		local base_text = text:gsub("[" .. tone_keys .. "]", "")

-- 		-- Handle tone removal (double press)
-- 		if count > 1 then
-- 			return base_text .. string.rep(tone_char, count)
-- 		end

-- 		-- Apply tone to the appropriate vowel
-- 		local main_vowel = M.find_main_vowel(base_text)

-- 		if not main_vowel or not TONE_PLACEMENT[main_vowel] then
-- 			return text
-- 		end

-- 		local accented = TONE_PLACEMENT[main_vowel][tone_index]
-- 		return base_text:gsub(main_vowel, accented, 1)
-- 	end,
-- }

-- -- VNI input method
-- input_methods.vni = {
-- 	is_input_char = function(char)
-- 		return char:match("[a-z]") or char:match("%d")
-- 	end,

-- 	apply_tones = function(text)
-- 		local tone_char, tone_index, count
-- 		local tone_keys = TONE_CHARS.vni

-- 		-- Find tone character and its positions
-- 		local positions = {}
-- 		for i = #text, 1, -1 do
-- 			local c = text:sub(i, i)
-- 			if tone_keys:find(c) then
-- 				tone_char = c
-- 				tone_index = TONE_MAP.vni[c]
-- 				table.insert(positions, i)
-- 			end
-- 		end

-- 		if not tone_char then
-- 			return text
-- 		end
-- 		count = #positions

-- 		-- Remove all tone characters
-- 		local base_text = text:gsub("[" .. tone_keys .. "]", "")

-- 		-- Handle tone removal (double press)
-- 		if count > 1 and positions[#positions] == positions[#positions - 1] + 1 then
-- 			return base_text
-- 		end

-- 		-- Apply tone to the appropriate vowel
-- 		local main_vowel = M.find_main_vowel(base_text)
-- 		if not main_vowel or not TONE_PLACEMENT[main_vowel] then
-- 			return base_text
-- 		end

-- 		local accented = TONE_PLACEMENT[main_vowel][tone_index]
-- 		return base_text:gsub(main_vowel, accented, 1)
-- 	end,
-- }
