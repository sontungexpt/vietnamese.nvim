local M = {}

-- TONE ENUM
local TONE_ACUTE = 1
local TONE_GRAVE = 2
local TONE_HOOK = 3
local TONE_TILDE = 4
local TONE_DOT = 5

M.ENUM_TONE = {
	ACUTE = TONE_ACUTE,
	GRAVE = TONE_GRAVE,
	HOOK = TONE_HOOK,
	TILDE = TONE_TILDE,
	DOT = TONE_DOT,
}

-- DIACRITIC ENUM
-- Start from ten to separate from TONE enum when comparing
local DIACRITIC_CIRCUMFLEX = 6
local DIACRITIC_BREVE = 7
local DIACRITIC_HORN = 8
local DIACRITIC_HORIZONTAL_STROKE = 9

M.ENUM_DIACRITIC = {
	CIRCUMFLEX = DIACRITIC_CIRCUMFLEX,
	BREVE = DIACRITIC_BREVE,
	HORN = DIACRITIC_HORN,
	HORIZONTAL_STROKE = DIACRITIC_HORIZONTAL_STROKE,
}

-- local sort_descending_by_strlen = function(a, b)
-- 	return #a > #b
-- end

M = {
	BASE_VOWELS = {
		"a",
		"o",
		"e",
		"u",
		"i",
		"y",
		["a"] = true,
		["o"] = true,
		["e"] = true,
		["u"] = true,
		["i"] = true,
		["y"] = true,
	},
	-- [1] is the base vowel
	UTF8_VN_CHAR_DICT = {
		["á"] = { "a", tone = TONE_ACUTE, up = "Á" },
		["à"] = { "a", tone = TONE_GRAVE, up = "À" },
		["ả"] = { "a", tone = TONE_HOOK, up = "Ả" },
		["ã"] = { "a", tone = TONE_TILDE, up = "Ã" },
		["ạ"] = { "a", tone = TONE_DOT, up = "Ạ" },

		["ă"] = { "a", diacritic = DIACRITIC_BREVE, up = "Ă" },
		["ắ"] = { "a", diacritic = DIACRITIC_BREVE, tone = TONE_ACUTE, up = "Ắ" },
		["ằ"] = { "a", diacritic = DIACRITIC_BREVE, tone = TONE_GRAVE, up = "Ằ" },
		["ẳ"] = { "a", diacritic = DIACRITIC_BREVE, tone = TONE_HOOK, up = "Ẳ" },
		["ẵ"] = { "a", diacritic = DIACRITIC_BREVE, tone = TONE_TILDE, up = "Ẵ" },
		["ặ"] = { "a", diacritic = DIACRITIC_BREVE, tone = TONE_DOT, up = "Ặ" },

		["â"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, up = "Â" },
		["ấ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, up = "Ấ" },
		["ầ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, up = "Ầ" },
		["ẩ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, up = "Ẩ" },
		["ẫ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, up = "Ẫ" },
		["ậ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_DOT, up = "Ậ" },

		["é"] = { "e", tone = TONE_ACUTE, up = "É" },
		["è"] = { "e", tone = TONE_GRAVE, up = "È" },
		["ẻ"] = { "e", tone = TONE_HOOK, up = "Ẻ" },
		["ẽ"] = { "e", tone = TONE_TILDE, up = "Ẽ" },
		["ẹ"] = { "e", tone = TONE_DOT, up = "Ẹ" },

		["ê"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, up = "Ê" },
		["ế"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, up = "Ế" },
		["ề"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, up = "Ề" },
		["ể"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, up = "Ể" },
		["ễ"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, up = "Ễ" },
		["ệ"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_DOT, up = "Ệ" },

		["í"] = { "i", tone = TONE_ACUTE, up = "Í" },
		["ì"] = { "i", tone = TONE_GRAVE, up = "Ì" },
		["ỉ"] = { "i", tone = TONE_HOOK, up = "Ỉ" },
		["ĩ"] = { "i", tone = TONE_TILDE, up = "Ĩ" },
		["ị"] = { "i", tone = TONE_DOT, up = "Ị" },

		["ó"] = { "o", tone = TONE_ACUTE, up = "Ó" },
		["ò"] = { "o", tone = TONE_GRAVE, up = "Ò" },
		["ỏ"] = { "o", tone = TONE_HOOK, up = "Ỏ" },
		["õ"] = { "o", tone = TONE_TILDE, up = "Õ" },
		["ọ"] = { "o", tone = TONE_DOT, up = "Ọ" },

		["ô"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, up = "Ô" },
		["ố"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, up = "Ố" },
		["ồ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, up = "Ồ" },
		["ổ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, up = "Ổ" },
		["ỗ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, up = "Ỗ" },
		["ộ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_DOT, up = "Ộ" },

		["ơ"] = { "o", diacritic = DIACRITIC_HORN, up = "Ơ" },
		["ớ"] = { "o", diacritic = DIACRITIC_HORN, tone = TONE_ACUTE, up = "Ớ" },
		["ờ"] = { "o", diacritic = DIACRITIC_HORN, tone = TONE_GRAVE, up = "Ờ" },
		["ở"] = { "o", diacritic = DIACRITIC_HORN, tone = TONE_HOOK, up = "Ở" },
		["ỡ"] = { "o", diacritic = DIACRITIC_HORN, tone = TONE_TILDE, up = "Ỡ" },
		["ợ"] = { "o", diacritic = DIACRITIC_HORN, tone = TONE_DOT, up = "Ợ" },

		["ú"] = { "u", tone = TONE_ACUTE, up = "Ú" },
		["ù"] = { "u", tone = TONE_GRAVE, up = "Ù" },
		["ủ"] = { "u", tone = TONE_HOOK, up = "Ủ" },
		["ũ"] = { "u", tone = TONE_TILDE, up = "Ũ" },
		["ụ"] = { "u", tone = TONE_DOT, up = "Ụ" },

		["ư"] = { "u", diacritic = DIACRITIC_HORN, up = "Ư" },
		["ứ"] = { "u", diacritic = DIACRITIC_HORN, tone = TONE_ACUTE, up = "Ứ" },
		["ừ"] = { "u", diacritic = DIACRITIC_HORN, tone = TONE_GRAVE, up = "Ừ" },
		["ử"] = { "u", diacritic = DIACRITIC_HORN, tone = TONE_HOOK, up = "Ử" },
		["ữ"] = { "u", diacritic = DIACRITIC_HORN, tone = TONE_TILDE, up = "Ữ" },
		["ự"] = { "u", diacritic = DIACRITIC_HORN, tone = TONE_DOT, up = "Ự" },

		["ý"] = { "y", tone = TONE_ACUTE, up = "Ý" },
		["ỳ"] = { "y", tone = TONE_GRAVE, up = "Ỳ" },
		["ỷ"] = { "y", tone = TONE_HOOK, up = "Ỷ" },
		["ỹ"] = { "y", tone = TONE_TILDE, up = "Ỹ" },
		["ỵ"] = { "y", tone = TONE_DOT, up = "Ỵ" },

		["đ"] = { "d", diacritic = DIACRITIC_HORIZONTAL_STROKE, up = "Đ" },

		-- uppercase
		["Á"] = { "A", tone = TONE_ACUTE, lo = "á" },
		["À"] = { "A", tone = TONE_GRAVE, lo = "à" },
		["Ả"] = { "A", tone = TONE_HOOK, lo = "ả" },
		["Ã"] = { "A", tone = TONE_TILDE, lo = "ã" },
		["Ạ"] = { "A", tone = TONE_DOT, lo = "ạ" },

		["Ă"] = { "A", diacritic = DIACRITIC_BREVE, lo = "ă" },
		["Ắ"] = { "A", diacritic = DIACRITIC_BREVE, tone = TONE_ACUTE, lo = "ắ" },
		["Ằ"] = { "A", diacritic = DIACRITIC_BREVE, tone = TONE_GRAVE, lo = "ằ" },
		["Ẳ"] = { "A", diacritic = DIACRITIC_BREVE, tone = TONE_HOOK, lo = "ẳ" },
		["Ẵ"] = { "A", diacritic = DIACRITIC_BREVE, tone = TONE_TILDE, lo = "ẵ" },
		["Ặ"] = { "A", diacritic = DIACRITIC_BREVE, tone = TONE_DOT, lo = "ặ" },

		["Â"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, lo = "â" },
		["Ấ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, lo = "ấ" },
		["Ầ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, lo = "ầ" },
		["Ẩ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, lo = "ẩ" },
		["Ẫ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, lo = "ẫ" },

		["É"] = { "E", tone = TONE_ACUTE, lo = "é" },
		["È"] = { "E", tone = TONE_GRAVE, lo = "è" },
		["Ẻ"] = { "E", tone = TONE_HOOK, lo = "ẻ" },
		["Ẽ"] = { "E", tone = TONE_TILDE, lo = "ẽ" },
		["Ẹ"] = { "E", tone = TONE_DOT, lo = "ẹ" },

		["Ê"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, lo = "ê" },
		["Ế"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, lo = "ế" },
		["Ề"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, lo = "ề" },
		["Ể"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, lo = "ể" },
		["Ễ"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, lo = "ễ" },
		["Ệ"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_DOT, lo = "ệ" },

		["Í"] = { "I", tone = TONE_ACUTE, lo = "í" },
		["Ì"] = { "I", tone = TONE_GRAVE, lo = "ì" },
		["Ỉ"] = { "I", tone = TONE_HOOK, lo = "ỉ" },
		["Ĩ"] = { "I", tone = TONE_TILDE, lo = "ĩ" },
		["Ị"] = { "I", tone = TONE_DOT, lo = "ị" },

		["Ó"] = { "O", tone = TONE_ACUTE, lo = "ó" },
		["Ò"] = { "O", tone = "TONE_GRAVE", lo = "ò" },
		["Ỏ"] = { "O", tone = TONE_HOOK, lo = "ỏ" },
		["Õ"] = { "O", tone = TONE_TILDE, lo = "õ" },
		["Ọ"] = { "O", tone = TONE_DOT, lo = "ọ" },

		["Ô"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, lo = "ô" },
		["Ố"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_ACUTE, lo = "ố" },
		["Ồ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_GRAVE, lo = "ồ" },
		["Ổ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_HOOK, lo = "ổ" },
		["Ỗ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_TILDE, lo = "ỗ" },
		["Ộ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = TONE_DOT, lo = "ộ" },

		["Ơ"] = { "O", diacritic = DIACRITIC_HORN, lo = "ơ" },
		["Ớ"] = { "O", diacritic = DIACRITIC_HORN, tone = TONE_ACUTE, lo = "ớ" },
		["Ờ"] = { "O", diacritic = DIACRITIC_HORN, tone = TONE_GRAVE, lo = "ờ" },
		["Ở"] = { "O", diacritic = DIACRITIC_HORN, tone = TONE_HOOK, lo = "ở" },
		["Ỡ"] = { "O", diacritic = DIACRITIC_HORN, tone = TONE_TILDE, lo = "ỡ" },
		["Ợ"] = { "O", diacritic = DIACRITIC_HORN, tone = TONE_DOT, lo = "ợ" },

		["Ú"] = { "U", tone = TONE_ACUTE, lo = "ú" },
		["Ù"] = { "U", tone = "TONE_GRAVE", lo = "ù" },
		["Ủ"] = { "U", tone = TONE_HOOK, lo = "ủ" },
		["Ũ"] = { "U", tone = TONE_TILDE, lo = "ũ" },
		["Ụ"] = { "U", tone = TONE_DOT, lo = "ụ" },

		["Ư"] = { "U", diacritic = DIACRITIC_HORN, lo = "ư" },
		["Ứ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_ACUTE", lo = "ứ" },
		["Ừ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_GRAVE", lo = "ừ" },
		["Ử"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_HOOK", lo = "ử" },
		["Ữ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_TILDE", lo = "ữ" },
		["Ự"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_DOT", lo = "ự" },

		["Ý"] = { "Y", tone = "TONE_ACUTE", lo = "ý" },
		["Ỳ"] = { "Y", tone = TONE_GRAVE, lo = "ỳ" },
		["Ỷ"] = { "Y", tone = TONE_HOOK, lo = "ỷ" },
		["Ỹ"] = { "Y", tone = TONE_TILDE, lo = "ỹ" },
		["Ỵ"] = { "Y", tone = TONE_DOT, lo = "ỵ" },

		["Đ"] = { "D", diacritic = DIACRITIC_HORIZONTAL_STROKE, lo = "đ" },
	},

	TONE_PLACEMENT = {
		a = { "á", "à", "ả", "ã", "ạ" },
		["ă"] = { "ắ", "ằ", "ẳ", "ẵ", "ặ" },
		["â"] = { "ấ", "ầ", "ẩ", "ẫ", "ậ" },

		e = { "é", "è", "ẻ", "ẽ", "ẹ" },
		["ê"] = { "ế", "ề", "ể", "ễ", "ệ" },

		i = { "í", "ì", "ỉ", "ĩ", "ị" },

		o = { "ó", "ò", "ỏ", "õ", "ọ" },
		["ô"] = { "ố", "ồ", "ổ", "ỗ", "ộ" },
		["ơ"] = { "ớ", "ờ", "ở", "ỡ", "ợ" },

		u = { "ú", "ù", "ủ", "ũ", "ụ" },
		["ư"] = { "ứ", "ừ", "ử", "ữ", "ự" },

		y = { "ý", "ỳ", "ỷ", "ỹ", "ỵ" },

		A = { "Á", "À", "Ả", "Ã", "Ạ" },
		["Ă"] = { "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ" },
		["Â"] = { "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ" },

		E = { "É", "È", "Ẻ", "Ẽ", "Ẹ" },
		["Ê"] = { "Ế", "Ề", "Ể", "Ễ", "Ệ" },

		I = { "Í", "Ì", "Ỉ", "Ĩ", "Ị" },

		O = { "Ó", "Ò", "Ỏ", "Õ", "Ọ" },
		["Ô"] = { "Ố", "Ồ", "Ổ", "Ỗ", "Ộ" },
		["Ơ"] = { "Ớ", "Ờ", "Ở", "Ỡ", "Ợ" },

		U = { "Ú", "Ù", "Ủ", "Ũ", "Ụ" },
		["Ư"] = { "Ứ", "Ừ", "Ử", "Ữ", "Ự" },

		Y = { "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ" },

		D = { "Đ" },
	},

	DIACRITIC_MAP = {
		a = { [DIACRITIC_CIRCUMFLEX] = "â", [DIACRITIC_BREVE] = "ă" },
		e = { [DIACRITIC_CIRCUMFLEX] = "ê" },
		o = { [DIACRITIC_CIRCUMFLEX] = "ô", [DIACRITIC_HORN] = "ơ" },
		u = { [DIACRITIC_HORN] = "ư" },
		d = { [DIACRITIC_HORIZONTAL_STROKE] = "đ" },

		-- uppercase
		A = { [DIACRITIC_CIRCUMFLEX] = "Â", [DIACRITIC_BREVE] = "Ă" },
		E = { [DIACRITIC_CIRCUMFLEX] = "Ê" },
		O = { [DIACRITIC_CIRCUMFLEX] = "Ô", [DIACRITIC_HORN] = "Ơ" },
		U = { [DIACRITIC_HORN] = "Ư" },
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
		"b",
		"c",
		"ch",
		"d",
		"đ",
		"g",
		"gh",
		"gi",
		"h",
		"k",
		"kh",
		"l",
		"m",
		"n",
		"ng",
		"ngh",
		"nh",
		"p",
		"ph",
		"qu",
		"r",
		"s",
		"t",
		"th",
		"tr",
		"v",
		"x",
		"",
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
		"c",
		"ch",
		"m",
		"n",
		"ng",
		"nh",
		"p",
		"t",
		"",
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
