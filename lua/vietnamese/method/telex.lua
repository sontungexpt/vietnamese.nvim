local DIACRITIC = require("vietnamese.util.codec").DIACRITIC

---@type MethodConfig
local M = {
	tone_keys = {
		["s"] = DIACRITIC.Acute,
		["f"] = DIACRITIC.Grave,
		["r"] = DIACRITIC.Hook,
		["x"] = DIACRITIC.Tilde,
		["j"] = DIACRITIC.Dot,
	},
	tone_removal_keys = {
		["z"] = true,
	},
	shape_keys = {
		-- a = { a = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.BREVE },
		-- e = { e = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.CIRCUMFLEX },
		-- o = { o = ENUM_DIACRITIC.CIRCUMFLEX, w = ENUM_DIACRITIC.HORN },
		-- u = { u = ENUM_DIACRITIC.HORN, w = ENUM_DIACRITIC.HORN },
		-- d = { d = ENUM_DIACRITIC.HORIZONTAL_STROKE },

		w = {
			a = DIACRITIC.Breve,
			o = DIACRITIC.Horn,
			u = DIACRITIC.Horn,
			e = DIACRITIC.Circumflex,
		},

		a = {
			a = DIACRITIC.Circumflex,
		},

		e = {
			e = DIACRITIC.Circumflex,
		},

		o = {
			o = DIACRITIC.Circumflex,
		},

		d = {
			d = DIACRITIC.Stroke,
		},
	},
	char_map = {
		[""] = { w = "ư", W = "Ư" },
	},

	-- Check if a character is a valid input character to make a Vietnamese character
	is_diacritic_pressed = function(char)
		return char:lower():match("[sfrxjzawdeo]") ~= nil
	end,
}

return M
