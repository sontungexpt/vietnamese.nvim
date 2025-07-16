local Diacritic = require("vietnamese.constant").Diacritic

---@type MethodConfig
local M = {
	tone_keys = {
		["'"] = Diacritic.Acute,
		["`"] = Diacritic.Grave,
		["?"] = Diacritic.Hook,
		["~"] = Diacritic.Tilde,
		["."] = Diacritic.Dot,
	},
	tone_removal_keys = {
		["0"] = true,
	},
	shape_keys = {
		["^"] = {
			a = Diacritic.Circumflex,
			e = Diacritic.Circumflex,
			o = Diacritic.Circumflex,
		},
		["("] = {
			a = Diacritic.Breve,
		},
		["+"] = {
			o = Diacritic.Horn,
			u = Diacritic.Horn,
		},
		["d"] = {
			d = Diacritic.HorizontalStroke,
		},
	},
	char_map = {},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:lower():match("[`'?~.'%-j^(d+]") ~= nil
	end,
}

return M
