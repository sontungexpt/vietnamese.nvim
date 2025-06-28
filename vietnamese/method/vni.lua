local ENUM_DIACRITIC = require("vietnamese.constant").Diacritic

local M = {
	tone_keys = {
		["1"] = ENUM_DIACRITIC.Acute,
		["2"] = ENUM_DIACRITIC.Grave,
		["3"] = ENUM_DIACRITIC.Hook,
		["4"] = ENUM_DIACRITIC.Tildle,
		["5"] = ENUM_DIACRITIC.Dot,
	},
	tone_removal_keys = { "z" },
	shape_keys = {
		a = { a = ENUM_DIACRITIC.Circumflex, w = ENUM_DIACRITIC.Breve },
		e = { e = ENUM_DIACRITIC.Circumflex, w = ENUM_DIACRITIC.Circumflex },
		o = { o = ENUM_DIACRITIC.Circumflex, w = ENUM_DIACRITIC.Horn },
		u = { u = ENUM_DIACRITIC.Horn, w = ENUM_DIACRITIC.Horn },
		d = { d = ENUM_DIACRITIC.HorizontalStroke },
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
