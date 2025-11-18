local DIACRITIC = require("vietnamese.util.codec").DIACRITIC

---@type MethodConfig
local M = {
	tone_keys = {
		["'"] = DIACRITIC.Acute,
		["`"] = DIACRITIC.Grave,
		["?"] = DIACRITIC.Hook,
		["~"] = DIACRITIC.Tilde,
		["."] = DIACRITIC.Dot,
	},
	tone_removal_keys = {
		["0"] = true,
	},
	shape_keys = {
		["^"] = {
			a = DIACRITIC.Circumflex,
			e = DIACRITIC.Circumflex,
			o = DIACRITIC.Circumflex,
		},
		["("] = {
			a = DIACRITIC.Breve,
		},
		["+"] = {
			o = DIACRITIC.Horn,
			u = DIACRITIC.Horn,
		},
		["d"] = {
			d = DIACRITIC.Stroke,
		},
	},
	char_map = {},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:lower():match("[`'?~.'0^(+d]") ~= nil
	end,
}

return M
