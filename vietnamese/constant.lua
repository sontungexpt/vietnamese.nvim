local M = {}

-- TONE ENUM
local DIACRITIC_TONE_REMOVAL = 0
local DIACRITIC_ACUTE = 1
local DIACRITIC_GRAVE = 2
local DIACRITIC_HOOK = 3
local DIACRITIC_TILDE = 4
local DIACRITIC_DOT = 5
local DIACRITIC_CIRCUMFLEX = 6
local DIACRITIC_BREVE = 7
local DIACRITIC_HORN = 8
local DIACRITIC_HORIZONTAL_STROKE = 9

M = {
	ENUM_DIACRITIC = {
		TONE_REMOVAL = DIACRITIC_TONE_REMOVAL,
		ACUTE = DIACRITIC_ACUTE,
		GRAVE = DIACRITIC_GRAVE,
		HOOK = DIACRITIC_HOOK,
		TILDE = DIACRITIC_TILDE,
		DOT = DIACRITIC_DOT,
		CIRCUMFLEX = DIACRITIC_CIRCUMFLEX,
		BREVE = DIACRITIC_BREVE,
		HORN = DIACRITIC_HORN,
		HORIZONTAL_STROKE = DIACRITIC_HORIZONTAL_STROKE,

		is_tone_removal = function(diacritic)
			return diacritic == DIACRITIC_TONE_REMOVAL
		end,

		is_tone = function(diacritic)
			return diacritic == DIACRITIC_ACUTE
				or diacritic == DIACRITIC_GRAVE
				or diacritic == DIACRITIC_HOOK
				or diacritic == DIACRITIC_TILDE
				or diacritic == DIACRITIC_DOT
		end,
	},
	BASE_VOWEL_PRIORITY = {
		["a"] = 1,
		["ă"] = 2,
		["â"] = 3,

		["e"] = 4,
		["ê"] = 5,

		["i"] = 6,

		["o"] = 7,
		["ô"] = 8,
		["ơ"] = 9,

		["u"] = 10,
		["ư"] = 11,

		["y"] = 12,
	},
	-- [1] is the base vowel
	UTF8_VN_CHAR_DICT = {
		["á"] = { "a", "a", tone = DIACRITIC_ACUTE, up = "Á" },
		["à"] = { "a", "a", tone = DIACRITIC_GRAVE, up = "À" },
		["ả"] = { "a", "a", tone = DIACRITIC_HOOK, up = "Ả" },
		["ã"] = { "a", "a", tone = DIACRITIC_TILDE, up = "Ã" },
		["ạ"] = { "a", "a", tone = DIACRITIC_DOT, up = "Ạ" },

		["ă"] = { "a", "ă", shape = DIACRITIC_BREVE, up = "Ă" },
		["ắ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, up = "Ắ" },
		["ằ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, up = "Ằ" },
		["ẳ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, up = "Ẳ" },
		["ẵ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, up = "Ẵ" },
		["ặ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_DOT, up = "Ặ" },

		["â"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, up = "Â" },
		["ấ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ấ" },
		["ầ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ầ" },
		["ẩ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ẩ" },
		["ẫ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ẫ" },
		["ậ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ậ" },

		["é"] = { "e", "e", tone = DIACRITIC_ACUTE, up = "É" },
		["è"] = { "e", "e", tone = DIACRITIC_GRAVE, up = "È" },
		["ẻ"] = { "e", "e", tone = DIACRITIC_HOOK, up = "Ẻ" },
		["ẽ"] = { "e", "e", tone = DIACRITIC_TILDE, up = "Ẽ" },
		["ẹ"] = { "e", "e", tone = DIACRITIC_DOT, up = "Ẹ" },

		["ê"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, up = "Ê" },
		["ế"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ế" },
		["ề"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ề" },
		["ể"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ể" },
		["ễ"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ễ" },
		["ệ"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ệ" },

		["í"] = { "i", "i", tone = DIACRITIC_ACUTE, up = "Í" },
		["ì"] = { "i", "i", tone = DIACRITIC_GRAVE, up = "Ì" },
		["ỉ"] = { "i", "i", tone = DIACRITIC_HOOK, up = "Ỉ" },
		["ĩ"] = { "i", "i", tone = DIACRITIC_TILDE, up = "Ĩ" },
		["ị"] = { "i", "i", tone = DIACRITIC_DOT, up = "Ị" },

		["ó"] = { "o", "o", tone = DIACRITIC_ACUTE, up = "Ó" },
		["ò"] = { "o", "o", tone = DIACRITIC_GRAVE, up = "Ò" },
		["ỏ"] = { "o", "o", tone = DIACRITIC_HOOK, up = "Ỏ" },
		["õ"] = { "o", "o", tone = DIACRITIC_TILDE, up = "Õ" },
		["ọ"] = { "o", "o", tone = DIACRITIC_DOT, up = "Ọ" },

		["ô"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, up = "Ô" },
		["ố"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ố" },
		["ồ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ồ" },
		["ổ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ổ" },
		["ỗ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ỗ" },
		["ộ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ộ" },

		["ơ"] = { "o", "ơ", shape = DIACRITIC_HORN, up = "Ơ" },
		["ớ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ớ" },
		["ờ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ờ" },
		["ở"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ở" },
		["ỡ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ỡ" },
		["ợ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ợ" },

		["ú"] = { "u", "u", tone = DIACRITIC_ACUTE, up = "Ú" },
		["ù"] = { "u", "u", tone = DIACRITIC_GRAVE, up = "Ù" },
		["ủ"] = { "u", "u", tone = DIACRITIC_HOOK, up = "Ủ" },
		["ũ"] = { "u", "u", tone = DIACRITIC_TILDE, up = "Ũ" },
		["ụ"] = { "u", "u", tone = DIACRITIC_DOT, up = "Ụ" },

		["ư"] = { "u", "ư", shape = DIACRITIC_HORN, up = "Ư" },
		["ứ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ứ" },
		["ừ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ừ" },
		["ử"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ử" },
		["ữ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ữ" },
		["ự"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ự" },

		["ý"] = { "y", "y", tone = DIACRITIC_ACUTE, up = "Ý" },
		["ỳ"] = { "y", "y", tone = DIACRITIC_GRAVE, up = "Ỳ" },
		["ỷ"] = { "y", "y", tone = DIACRITIC_HOOK, up = "Ỷ" },
		["ỹ"] = { "y", "y", tone = DIACRITIC_TILDE, up = "Ỹ" },
		["ỵ"] = { "y", "y", tone = DIACRITIC_DOT, up = "Ỵ" },

		["đ"] = { "d", "d", shape = DIACRITIC_HORIZONTAL_STROKE, up = "Đ" },

		-- uppercase
		["Á"] = { "A", "A", tone = DIACRITIC_ACUTE, lo = "á" },
		["À"] = { "A", "A", tone = DIACRITIC_GRAVE, lo = "à" },
		["Ả"] = { "A", "A", tone = DIACRITIC_HOOK, lo = "ả" },
		["Ã"] = { "A", "A", tone = DIACRITIC_TILDE, lo = "ã" },
		["Ạ"] = { "A", "A", tone = DIACRITIC_DOT, lo = "ạ" },

		["Ă"] = { "A", "Ă", shape = DIACRITIC_BREVE, lo = "ă" },
		["Ắ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, lo = "ắ" },
		["Ằ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, lo = "ằ" },
		["Ẳ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, lo = "ẳ" },
		["Ẵ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, lo = "ẵ" },
		["Ặ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_DOT, lo = "ặ" },

		["Â"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, lo = "â" },
		["Ấ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ấ" },
		["Ầ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ầ" },
		["Ẩ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ẩ" },
		["Ẫ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ẫ" },

		["É"] = { "E", "E", tone = DIACRITIC_ACUTE, lo = "é" },
		["È"] = { "E", "E", tone = DIACRITIC_GRAVE, lo = "è" },
		["Ẻ"] = { "E", "E", tone = DIACRITIC_HOOK, lo = "ẻ" },
		["Ẽ"] = { "E", "E", tone = DIACRITIC_TILDE, lo = "ẽ" },
		["Ẹ"] = { "E", "E", tone = DIACRITIC_DOT, lo = "ẹ" },

		["Ê"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, lo = "ê" },
		["Ế"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ế" },
		["Ề"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ề" },
		["Ể"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ể" },
		["Ễ"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ễ" },
		["Ệ"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ệ" },

		["Í"] = { "I", "I", tone = DIACRITIC_ACUTE, lo = "í" },
		["Ì"] = { "I", "I", tone = DIACRITIC_GRAVE, lo = "ì" },
		["Ỉ"] = { "I", "I", tone = DIACRITIC_HOOK, lo = "ỉ" },
		["Ĩ"] = { "I", "I", tone = DIACRITIC_TILDE, lo = "ĩ" },
		["Ị"] = { "I", "I", tone = DIACRITIC_DOT, lo = "ị" },

		["Ó"] = { "O", "O", tone = DIACRITIC_ACUTE, lo = "ó" },
		["Ò"] = { "O", "O", tone = "TONE_GRAVE", lo = "ò" },
		["Ỏ"] = { "O", "O", tone = DIACRITIC_HOOK, lo = "ỏ" },
		["Õ"] = { "O", "O", tone = DIACRITIC_TILDE, lo = "õ" },
		["Ọ"] = { "O", "O", tone = DIACRITIC_DOT, lo = "ọ" },

		["Ô"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, lo = "ô" },
		["Ố"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ố" },
		["Ồ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ồ" },
		["Ổ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ổ" },
		["Ỗ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ỗ" },
		["Ộ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ộ" },

		["Ơ"] = { "O", "Ơ", shape = DIACRITIC_HORN, lo = "ơ" },
		["Ớ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, lo = "ớ" },
		["Ờ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, lo = "ờ" },
		["Ở"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, lo = "ở" },
		["Ỡ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, lo = "ỡ" },
		["Ợ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, lo = "ợ" },

		["Ú"] = { "U", "U", tone = DIACRITIC_ACUTE, lo = "ú" },
		["Ù"] = { "U", "U", tone = "TONE_GRAVE", lo = "ù" },
		["Ủ"] = { "U", "U", tone = DIACRITIC_HOOK, lo = "ủ" },
		["Ũ"] = { "U", "U", tone = DIACRITIC_TILDE, lo = "ũ" },
		["Ụ"] = { "U", "U", tone = DIACRITIC_DOT, lo = "ụ" },

		["Ư"] = { "U", "Ư", shape = DIACRITIC_HORN, lo = "ư" },
		["Ứ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = "TONE_ACUTE", lo = "ứ" },
		["Ừ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = "TONE_GRAVE", lo = "ừ" },
		["Ử"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = "TONE_HOOK", lo = "ử" },
		["Ữ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = "TONE_TILDE", lo = "ữ" },
		["Ự"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = "TONE_DOT", lo = "ự" },

		["Ý"] = { "Y", "Y", tone = "TONE_ACUTE", lo = "ý" },
		["Ỳ"] = { "Y", "Y", tone = DIACRITIC_GRAVE, lo = "ỳ" },
		["Ỷ"] = { "Y", "Y", tone = DIACRITIC_HOOK, lo = "ỷ" },
		["Ỹ"] = { "Y", "Y", tone = DIACRITIC_TILDE, lo = "ỹ" },
		["Ỵ"] = { "Y", "Y", tone = DIACRITIC_DOT, lo = "ỵ" },

		["Đ"] = { "D", "D", shape = DIACRITIC_HORIZONTAL_STROKE, lo = "đ" },
	},

	DIACRITIC_MAP = {
		a = { "á", "à", "ả", "ã", "ạ", [DIACRITIC_CIRCUMFLEX] = "â", [DIACRITIC_BREVE] = "ă" },
		["ă"] = { "ắ", "ằ", "ẳ", "ẵ", "ặ" },
		["â"] = { "ấ", "ầ", "ẩ", "ẫ", "ậ" },

		e = { "é", "è", "ẻ", "ẽ", "ẹ", [DIACRITIC_CIRCUMFLEX] = "ê" },
		["ê"] = { "ế", "ề", "ể", "ễ", "ệ" },

		i = { "í", "ì", "ỉ", "ĩ", "ị" },

		o = { "ó", "ò", "ỏ", "õ", "ọ", [DIACRITIC_CIRCUMFLEX] = "ô", [DIACRITIC_HORN] = "ơ" },
		["ô"] = { "ố", "ồ", "ổ", "ỗ", "ộ" },
		["ơ"] = { "ớ", "ờ", "ở", "ỡ", "ợ" },

		u = { "ú", "ù", "ủ", "ũ", "ụ", [DIACRITIC_HORN] = "ư" },
		["ư"] = { "ứ", "ừ", "ử", "ữ", "ự" },

		y = { "ý", "ỳ", "ỷ", "ỹ", "ỵ" },

		d = { [DIACRITIC_HORIZONTAL_STROKE] = "đ" },

		A = { "Á", "À", "Ả", "Ã", "Ạ", [DIACRITIC_CIRCUMFLEX] = "Â", [DIACRITIC_BREVE] = "Ă" },
		["Ă"] = { "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ" },
		["Â"] = { "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ" },

		E = { "É", "È", "Ẻ", "Ẽ", "Ẹ", [DIACRITIC_CIRCUMFLEX] = "Ê" },
		["Ê"] = { "Ế", "Ề", "Ể", "Ễ", "Ệ" },

		I = { "Í", "Ì", "Ỉ", "Ĩ", "Ị" },

		O = { "Ó", "Ò", "Ỏ", "Õ", "Ọ", [DIACRITIC_CIRCUMFLEX] = "Ô", [DIACRITIC_HORN] = "Ơ" },
		["Ô"] = { "Ố", "Ồ", "Ổ", "Ỗ", "Ộ" },
		["Ơ"] = { "Ớ", "Ờ", "Ở", "Ỡ", "Ợ" },

		U = { "Ú", "Ù", "Ủ", "Ũ", "Ụ", [DIACRITIC_HORN] = "Ư" },
		["Ư"] = { "Ứ", "Ừ", "Ử", "Ữ", "Ự" },

		Y = { "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ" },

		D = { [DIACRITIC_HORIZONTAL_STROKE] = "Đ" },
	},
	VOWEL_SEQUENCES = {
		"iê",
		"yê",
		"uô",
		"ươ",
		"uâ",
		"uyê",
		"oă",
		"uă",
		"uya",
		"uân",
		"uât",
		"uyn",
		"uych",
		"uỳnh",
		"uênh",
		"uya",
		"uyết",
		"uốt",
		"uột",
		"iêt",
		"yêt",
		"uât",
		"oăt",
		"uyt",
		"uya",
		"oai",
		"oay",
		"oeo",
		"ua",
		"uê",
		"ui",
		"uơ",
		"uy",
		"ai",
		"ao",
		"au",
		"âu",
		"ay",
		"ây",
		"eo",
		"êu",
		"ia",
		"iê",
		"iu",
		"iêu",
		"oa",
		"oă",
		"oe",
		"oi",
		"ôi",
		"ơi",
		"ua",
		"ưa",
		"uê",
		"ui",
		"ưi",
		"uơ",
		"uô",
		"ưu",
		"uy",
	},
	-- ONSET_PATTERN = "ngh|gh|nh|ch|ph|th|tr|qu|ng|gi|kh|[bcdđghklmnpqrstvx]",
	-- VOWEL_PATTERN = "[aăâeêioôơuưyáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]",
	-- CODA_PATTERN = "ch|nh|ng|c|m|n|p|t",
	ONSETS = {
		["b"] = true,
		["c"] = true,
		["ch"] = true,
		["d"] = true,
		["đ"] = true,
		["g"] = true,
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
