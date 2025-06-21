local ENUM_DIACRITIC = require("vietnamese.constant").ENUM_DIACRITIC

local M = {
	tone_keys = {
		["1"] = ENUM_DIACRITIC.ACUTE,
		["2"] = ENUM_DIACRITIC.GRAVE,
		["3"] = ENUM_DIACRITIC.HOOK,
		["4"] = ENUM_DIACRITIC.TILDE,
		["5"] = ENUM_DIACRITIC.DOT,
	},
	tone_remove_keys = { "z" },
	shape_keys = {
		a = { a = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.BREVE },
		e = { e = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.CIRCUMFLEX },
		o = { o = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.HORN },
		u = { u = ENUM_DIACRITIC.HORN, w = ENUM_DIACRITIC.HORN },
		d = { d = ENUM_DIACRITIC.HORIZONTAL_STROKE },
	},
	char_map = {
		[""] = { w = "ư", W = "Ư" },
	},

	-- Check if a character is a valid input character to make a Vietnamese character
	--
	is_diacritic_pressed = function(char)
		return char:lower():match("[sfrxjzawdeou]") ~= nil
	end,
}

return M
