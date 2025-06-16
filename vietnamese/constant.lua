local M = {}

-- TONE ENUM
--
local DIACRITIC_ACUTE = 1
local DIACRITIC_GRAVE = 2
local DIACRITIC_HOOK = 3
local DIACRITIC_TILDE = 4
local DIACRITIC_DOT = 5
local DIACRITIC_CIRCUMFLEX = 6
local DIACRITIC_BREVE = 7
local DIACRITIC_HORN = 8
local DIACRITIC_HORIZONTAL_STROKE = 9

M.ENUM_DIACRITIC = {
	ACUTE = DIACRITIC_ACUTE,
	GRAVE = DIACRITIC_GRAVE,
	HOOK = DIACRITIC_HOOK,
	TILDE = DIACRITIC_TILDE,
	DOT = DIACRITIC_DOT,
	CIRCUMFLEX = DIACRITIC_CIRCUMFLEX,
	BREVE = DIACRITIC_BREVE,
	HORN = DIACRITIC_HORN,
	HORIZONTAL_STROKE = DIACRITIC_HORIZONTAL_STROKE,

	is_tone = function(diacritic)
		return diacritic == DIACRITIC_ACUTE
			or diacritic == DIACRITIC_GRAVE
			or diacritic == DIACRITIC_HOOK
			or diacritic == DIACRITIC_TILDE
			or diacritic == DIACRITIC_DOT
	end,
}

-- local sort_descending_by_strlen = function(a, b)
-- 	return #a > #b
-- end

M = {
	BASE_VOWELS = {
		["a"] = 1,
		["o"] = 2,
		["e"] = 3,
		["u"] = 4,
		["i"] = 5,
		["y"] = 6,
	},
	-- [1] is the base vowel
	UTF8_VN_CHAR_DICT = {
		["á"] = { "a", tone = DIACRITIC_ACUTE, up = "Á" },
		["à"] = { "a", tone = DIACRITIC_GRAVE, up = "À" },
		["ả"] = { "a", tone = DIACRITIC_HOOK, up = "Ả" },
		["ã"] = { "a", tone = DIACRITIC_TILDE, up = "Ã" },
		["ạ"] = { "a", tone = DIACRITIC_DOT, up = "Ạ" },

		["ă"] = { "a", diacritic = DIACRITIC_BREVE, up = "Ă" },
		["ắ"] = { "a", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, up = "Ắ" },
		["ằ"] = { "a", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, up = "Ằ" },
		["ẳ"] = { "a", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, up = "Ẳ" },
		["ẵ"] = { "a", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, up = "Ẵ" },
		["ặ"] = { "a", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_DOT, up = "Ặ" },

		["â"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, up = "Â" },
		["ấ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ấ" },
		["ầ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ầ" },
		["ẩ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ẩ" },
		["ẫ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ẫ" },
		["ậ"] = { "a", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ậ" },

		["é"] = { "e", tone = DIACRITIC_ACUTE, up = "É" },
		["è"] = { "e", tone = DIACRITIC_GRAVE, up = "È" },
		["ẻ"] = { "e", tone = DIACRITIC_HOOK, up = "Ẻ" },
		["ẽ"] = { "e", tone = DIACRITIC_TILDE, up = "Ẽ" },
		["ẹ"] = { "e", tone = DIACRITIC_DOT, up = "Ẹ" },

		["ê"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, up = "Ê" },
		["ế"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ế" },
		["ề"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ề" },
		["ể"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ể" },
		["ễ"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ễ" },
		["ệ"] = { "e", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ệ" },

		["í"] = { "i", tone = DIACRITIC_ACUTE, up = "Í" },
		["ì"] = { "i", tone = DIACRITIC_GRAVE, up = "Ì" },
		["ỉ"] = { "i", tone = DIACRITIC_HOOK, up = "Ỉ" },
		["ĩ"] = { "i", tone = DIACRITIC_TILDE, up = "Ĩ" },
		["ị"] = { "i", tone = DIACRITIC_DOT, up = "Ị" },

		["ó"] = { "o", tone = DIACRITIC_ACUTE, up = "Ó" },
		["ò"] = { "o", tone = DIACRITIC_GRAVE, up = "Ò" },
		["ỏ"] = { "o", tone = DIACRITIC_HOOK, up = "Ỏ" },
		["õ"] = { "o", tone = DIACRITIC_TILDE, up = "Õ" },
		["ọ"] = { "o", tone = DIACRITIC_DOT, up = "Ọ" },

		["ô"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, up = "Ô" },
		["ố"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ố" },
		["ồ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ồ" },
		["ổ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ổ" },
		["ỗ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ỗ" },
		["ộ"] = { "o", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ộ" },

		["ơ"] = { "o", diacritic = DIACRITIC_HORN, up = "Ơ" },
		["ớ"] = { "o", diacritic = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ớ" },
		["ờ"] = { "o", diacritic = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ờ" },
		["ở"] = { "o", diacritic = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ở" },
		["ỡ"] = { "o", diacritic = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ỡ" },
		["ợ"] = { "o", diacritic = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ợ" },

		["ú"] = { "u", tone = DIACRITIC_ACUTE, up = "Ú" },
		["ù"] = { "u", tone = DIACRITIC_GRAVE, up = "Ù" },
		["ủ"] = { "u", tone = DIACRITIC_HOOK, up = "Ủ" },
		["ũ"] = { "u", tone = DIACRITIC_TILDE, up = "Ũ" },
		["ụ"] = { "u", tone = DIACRITIC_DOT, up = "Ụ" },

		["ư"] = { "u", diacritic = DIACRITIC_HORN, up = "Ư" },
		["ứ"] = { "u", diacritic = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ứ" },
		["ừ"] = { "u", diacritic = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ừ" },
		["ử"] = { "u", diacritic = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ử" },
		["ữ"] = { "u", diacritic = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ữ" },
		["ự"] = { "u", diacritic = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ự" },

		["ý"] = { "y", tone = DIACRITIC_ACUTE, up = "Ý" },
		["ỳ"] = { "y", tone = DIACRITIC_GRAVE, up = "Ỳ" },
		["ỷ"] = { "y", tone = DIACRITIC_HOOK, up = "Ỷ" },
		["ỹ"] = { "y", tone = DIACRITIC_TILDE, up = "Ỹ" },
		["ỵ"] = { "y", tone = DIACRITIC_DOT, up = "Ỵ" },

		["đ"] = { "d", diacritic = DIACRITIC_HORIZONTAL_STROKE, up = "Đ" },

		-- uppercase
		["Á"] = { "A", tone = DIACRITIC_ACUTE, lo = "á" },
		["À"] = { "A", tone = DIACRITIC_GRAVE, lo = "à" },
		["Ả"] = { "A", tone = DIACRITIC_HOOK, lo = "ả" },
		["Ã"] = { "A", tone = DIACRITIC_TILDE, lo = "ã" },
		["Ạ"] = { "A", tone = DIACRITIC_DOT, lo = "ạ" },

		["Ă"] = { "A", diacritic = DIACRITIC_BREVE, lo = "ă" },
		["Ắ"] = { "A", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, lo = "ắ" },
		["Ằ"] = { "A", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, lo = "ằ" },
		["Ẳ"] = { "A", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, lo = "ẳ" },
		["Ẵ"] = { "A", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, lo = "ẵ" },
		["Ặ"] = { "A", diacritic = DIACRITIC_BREVE, tone = DIACRITIC_DOT, lo = "ặ" },

		["Â"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, lo = "â" },
		["Ấ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ấ" },
		["Ầ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ầ" },
		["Ẩ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ẩ" },
		["Ẫ"] = { "A", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ẫ" },

		["É"] = { "E", tone = DIACRITIC_ACUTE, lo = "é" },
		["È"] = { "E", tone = DIACRITIC_GRAVE, lo = "è" },
		["Ẻ"] = { "E", tone = DIACRITIC_HOOK, lo = "ẻ" },
		["Ẽ"] = { "E", tone = DIACRITIC_TILDE, lo = "ẽ" },
		["Ẹ"] = { "E", tone = DIACRITIC_DOT, lo = "ẹ" },

		["Ê"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, lo = "ê" },
		["Ế"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ế" },
		["Ề"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ề" },
		["Ể"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ể" },
		["Ễ"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ễ" },
		["Ệ"] = { "E", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ệ" },

		["Í"] = { "I", tone = DIACRITIC_ACUTE, lo = "í" },
		["Ì"] = { "I", tone = DIACRITIC_GRAVE, lo = "ì" },
		["Ỉ"] = { "I", tone = DIACRITIC_HOOK, lo = "ỉ" },
		["Ĩ"] = { "I", tone = DIACRITIC_TILDE, lo = "ĩ" },
		["Ị"] = { "I", tone = DIACRITIC_DOT, lo = "ị" },

		["Ó"] = { "O", tone = DIACRITIC_ACUTE, lo = "ó" },
		["Ò"] = { "O", tone = "TONE_GRAVE", lo = "ò" },
		["Ỏ"] = { "O", tone = DIACRITIC_HOOK, lo = "ỏ" },
		["Õ"] = { "O", tone = DIACRITIC_TILDE, lo = "õ" },
		["Ọ"] = { "O", tone = DIACRITIC_DOT, lo = "ọ" },

		["Ô"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, lo = "ô" },
		["Ố"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ố" },
		["Ồ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ồ" },
		["Ổ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ổ" },
		["Ỗ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ỗ" },
		["Ộ"] = { "O", diacritic = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ộ" },

		["Ơ"] = { "O", diacritic = DIACRITIC_HORN, lo = "ơ" },
		["Ớ"] = { "O", diacritic = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, lo = "ớ" },
		["Ờ"] = { "O", diacritic = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, lo = "ờ" },
		["Ở"] = { "O", diacritic = DIACRITIC_HORN, tone = DIACRITIC_HOOK, lo = "ở" },
		["Ỡ"] = { "O", diacritic = DIACRITIC_HORN, tone = DIACRITIC_TILDE, lo = "ỡ" },
		["Ợ"] = { "O", diacritic = DIACRITIC_HORN, tone = DIACRITIC_DOT, lo = "ợ" },

		["Ú"] = { "U", tone = DIACRITIC_ACUTE, lo = "ú" },
		["Ù"] = { "U", tone = "TONE_GRAVE", lo = "ù" },
		["Ủ"] = { "U", tone = DIACRITIC_HOOK, lo = "ủ" },
		["Ũ"] = { "U", tone = DIACRITIC_TILDE, lo = "ũ" },
		["Ụ"] = { "U", tone = DIACRITIC_DOT, lo = "ụ" },

		["Ư"] = { "U", diacritic = DIACRITIC_HORN, lo = "ư" },
		["Ứ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_ACUTE", lo = "ứ" },
		["Ừ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_GRAVE", lo = "ừ" },
		["Ử"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_HOOK", lo = "ử" },
		["Ữ"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_TILDE", lo = "ữ" },
		["Ự"] = { "U", diacritic = DIACRITIC_HORN, tone = "TONE_DOT", lo = "ự" },

		["Ý"] = { "Y", tone = "TONE_ACUTE", lo = "ý" },
		["Ỳ"] = { "Y", tone = DIACRITIC_GRAVE, lo = "ỳ" },
		["Ỷ"] = { "Y", tone = DIACRITIC_HOOK, lo = "ỷ" },
		["Ỹ"] = { "Y", tone = DIACRITIC_TILDE, lo = "ỹ" },
		["Ỵ"] = { "Y", tone = DIACRITIC_DOT, lo = "ỵ" },

		["Đ"] = { "D", diacritic = DIACRITIC_HORIZONTAL_STROKE, lo = "đ" },
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
