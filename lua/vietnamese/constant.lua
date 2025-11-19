local M = {}

M = {
	--- @type table<string, number>
	--- VOWEL_ACCENT_PRIORITY maps Vietnamese vowels with accents to their priority.
	VOWEL_PRIORITY = {
		["ơ"] = 0,
		["ê"] = 1,

		["ă"] = 2,
		["ô"] = 3,
		["â"] = 4,
		["ư"] = 5,

		["a"] = 6,
		["o"] = 7,
		["e"] = 8,

		["i"] = 9,
		["u"] = 10,

		["y"] = 11,
	},
	--- @type table<string, {[0]: number?}|boolean>
	VOWEL_SEQS = {
		-- a
		["ai"] = { 0 },
		["ao"] = { 0 },
		["au"] = { 0 },
		["âu"] = { 0 },
		["ay"] = { 0 },
		["ây"] = { 0 },

		["ia"] = { 0 },
		["ie"] = false, --transitional, not a valid vowel
		["iê"] = { 1 },
		["iu"] = { 0 },
		["iêu"] = { 1 },

		["ye"] = false, -- transitional, not a valid vowel
		["yê"] = { 1 },
		["yêu"] = { 1 },

		["eo"] = { 0 },

		["eu"] = false, -- transitional, not a valid vowel
		["êu"] = { 0 },

		["oa"] = { 1 },
		["oă"] = { 1 },
		["oay"] = { 1 },
		["oai"] = { 1 },
		["oau"] = { 1 },
		["oao"] = { 1 },
		["oo"] = false,
		["oi"] = { 0 },
		["ôi"] = { 0 },
		["ơi"] = { 0 },
		["oe"] = { 1 },
		["oeo"] = { 1 },

		["ua"] = { 0 },
		["uao"] = { 1 },
		["ưa"] = { 0 },
		["uâ"] = { 1 },
		["uây"] = { 1 },
		["ue"] = false,
		["uê"] = { 1 },
		["ui"] = { 0 },
		["ưi"] = { 0 },
		["uy"] = { 1 },
		["uyu"] = { 1 },
		["uya"] = { 1 },

		["uye"] = false, -- transitional, not a valid vowel
		["uyê"] = { 2 },

		["uu"] = false, -- transitional, not a valid vowel
		["ưu"] = { 0 },

		["uo"] = false, -- transitional, not a valid vowel
		["uô"] = { 1 },
		["uôi"] = { 1 },

		["ưo"] = false, -- transitional, not a valid vowel
		["uơ"] = { 1 },
		["ươ"] = { 1 },

		["uoi"] = false, -- transitional, not a valid vowel
		["uơi"] = false, -- transitional, not a valid vowel
		["ưoi"] = false, -- transitional, not a valid vowel
		["ươi"] = { 1 },

		["uou"] = false, -- transitional, not a valid vowel
		["uơu"] = false, -- transitional, not a valid vowel
		["ưou"] = false, -- transitional, not a valid vowel
		["ươu"] = { 1 },
	},
	ONSETS = {
		["b"] = true,
		["c"] = true,
		["ch"] = true,
		["z"] = true, -- teen language replace d or gi
		["d"] = true,
		["đ"] = true,
		["g"] = true,
		["j"] = true, --teen type for gi
		["gh"] = true,
		["gi"] = true,
		["h"] = true,
		["k"] = true,
		["kh"] = true,
		["l"] = true,
		["m"] = true,
		["n"] = true,
		["ng"] = true,
		["ngh"] = true,
		["nh"] = true,
		["p"] = true,
		["f"] = true, -- teen language replace ph
		["ph"] = true,
		["qu"] = true,
		["r"] = true,
		["s"] = true,
		["t"] = true,
		["th"] = true,
		["tr"] = true,
		["v"] = true,
		["x"] = true,
		[""] = true, -- empty onset
	},
	CODAS = {
		["c"] = true,
		["ch"] = true,
		["m"] = true,
		["n"] = true,
		["ng"] = true,
		["nh"] = true,
		["p"] = true,
		["t"] = true,
		[""] = true, -- empty coda
	},
}

return M
