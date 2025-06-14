local CONSTANT = require("vietnamese.constant")
local M = {
	tone_map = {
		["s"] = CONSTANT.TONE_ACUTE_INDEX,
		["f"] = CONSTANT.TONE_GRAVE_INDEX,
		["r"] = CONSTANT.TONE_HOOK_INDEX,
		["x"] = CONSTANT.TONE_TILDE_INDEX,
		["j"] = CONSTANT.TONE_DOT_INDEX,
	},
	tone_removals = { "z" },
	diacritic_map = {
		a = { a = CONSTANT.DIACRITIC_CIRCUMFLEX, w = CONSTANT.DIACRITIC_BREVE },
		e = { e = CONSTANT.DIACRITIC_CIRCUMFLEX, w = CONSTANT.DIACRITIC_CIRCUMFLEX },
		o = { o = CONSTANT.DIACRITIC_CIRCUMFLEX, w = CONSTANT.DIACRITIC_HORN },
		u = { u = CONSTANT.DIACRITIC_HORN, w = CONSTANT.DIACRITIC_HORN },
		d = { d = CONSTANT.DIACRITIC_HORIZONTAL_STROKE },

		-- 	A = { a = "Â", w = "Ă" },
		-- 	E = { e = "Ê", w = "Ê" },
		-- 	O = { o = "Ô", w = "Ơ" },
		-- 	U = { u = "Ư", w = "Ư" },
		-- 	D = { d = "Đ" },
	},
	char_map = {
		[""] = { w = "ư", W = "Ư" },
	},

	-- Check if a character is a valid input character to make a Vietnamese character
	--
	is_moderator_char = function(char)
		return char:lower():match("[sfrxjzawdeou]")
	end,
}

return M
