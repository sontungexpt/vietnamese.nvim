local Diacritic = require("vietnamese.constant").Diacritic

local M = {
	tone_keys = {
		["1"] = Diacritic.Acute,
		["2"] = Diacritic.Grave,
		["3"] = Diacritic.Hook,
		["4"] = Diacritic.Tilde,
		["5"] = Diacritic.Dot,
	},
	tone_removal_keys = {
		["0"] = true,
	},
	shape_keys = {
		["6"] = {
			["a"] = Diacritic.Circumflex,
			["e"] = Diacritic.Circumflex,
			["o"] = Diacritic.Circumflex,
		},

		["7"] = {
			["u"] = Diacritic.Horn,
			["o"] = Diacritic.Horn,
		},

		["8"] = {
			["a"] = Diacritic.Breve,
		},

		["9"] = {
			["d"] = Diacritic.HorizontalStroke,
		},
	},
	char_map = {},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:match("[0-9]")
	end,
}

return M
