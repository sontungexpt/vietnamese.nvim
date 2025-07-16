local Diacritic = require("vietnamese.constant").Diacritic

---@type MethodConfig
local M = {
	tone_keys = {
		["s"] = Diacritic.Acute,
		["f"] = Diacritic.Grave,
		["r"] = Diacritic.Hook,
		["x"] = Diacritic.Tilde,
		["j"] = Diacritic.Dot,
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
			a = Diacritic.Breve,
			o = Diacritic.Horn,
			u = Diacritic.Horn,
			e = Diacritic.Circumflex,
		},

		a = {
			a = Diacritic.Circumflex,
		},

		e = {
			e = Diacritic.Circumflex,
		},

		o = {
			o = Diacritic.Circumflex,
		},

		d = {
			d = Diacritic.HorizontalStroke,
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
