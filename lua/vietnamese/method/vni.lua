local ENUM_DIACRITIC = require("vietnamese.constant").Diacritic

local M = {
	tone_keys = {
		["1"] = ENUM_DIACRITIC.Acute,
		["2"] = ENUM_DIACRITIC.Grave,
		["3"] = ENUM_DIACRITIC.Hook,
		["4"] = ENUM_DIACRITIC.Tilde,
		["5"] = ENUM_DIACRITIC.Dot,
	},
	tone_removal_keys = {
		"0",
		["0"] = true,
	},
	shape_keys = {
		["6"] = {
			["a"] = ENUM_DIACRITIC.Circumflex,
			["e"] = ENUM_DIACRITIC.Circumflex,
			["o"] = ENUM_DIACRITIC.Circumflex,
		},

		["7"] = {
			["u"] = ENUM_DIACRITIC.Horn,
			["o"] = ENUM_DIACRITIC.Horn,
		},

		["8"] = {
			["a"] = ENUM_DIACRITIC.Breve,
		},

		["9"] = {
			["d"] = ENUM_DIACRITIC.HorizontalStroke,
		},
	},
	char_map = {},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:match("[0-9]")
	end,
}

return M
