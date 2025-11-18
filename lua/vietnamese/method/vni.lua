local DIACRITIC = require("vietnamese.util.codec").DIACRITIC

local M = {
	tone_keys = {
		["1"] = DIACRITIC.Acute,
		["2"] = DIACRITIC.Grave,
		["3"] = DIACRITIC.Hook,
		["4"] = DIACRITIC.Tilde,
		["5"] = DIACRITIC.Dot,
	},
	tone_removal_keys = {
		["0"] = true,
	},
	shape_keys = {
		["6"] = {
			["a"] = DIACRITIC.Circumflex,
			["e"] = DIACRITIC.Circumflex,
			["o"] = DIACRITIC.Circumflex,
		},

		["7"] = {
			["u"] = DIACRITIC.Horn,
			["o"] = DIACRITIC.Horn,
		},

		["8"] = {
			["a"] = DIACRITIC.Breve,
		},

		["9"] = {
			["d"] = DIACRITIC.Stroke,
		},
	},
	char_map = {},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:match("[0-9]")
	end,
}

return M
