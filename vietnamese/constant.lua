local M = {}

--- @enum Diacritic
local Diacritic = {
	Flat = DIACRITIC_FLAT,
	ACUTE = DIACRITIC_ACUTE,
	Grave = DIACRITIC_GRAVE,
	Hook = DIACRITIC_HOOK,
	Tildle = DIACRITIC_TILDE,
	Dot = DIACRITIC_DOT,
	Circumflex = DIACRITIC_CIRCUMFLEX,
	Breve = DIACRITIC_BREVE,
	Horn = DIACRITIC_HORN,
	HorizontalStroke = DIACRITIC_HORIZONTAL_STROKE,

	--- Check if the diacritic is flat (no tone)
	--- @param diacritic Diacritic
	--- @return boolean
	is_flat = function(diacritic)
		return diacritic == DIACRITIC_FLAT
	end,
	--- Check if the diacritic is a tone
	--- @param diacritic Diacritic
	--- @return boolean
	is_tone = function(diacritic)
		return diacritic > DIACRITIC_FLAT and diacritic < DIACRITIC_CIRCUMFLEX
	end,
	--- Check if the diacritic is a shape
	--- @param diacritic Diacritic
	--- @return boolean
	is_shape = function(diacritic)
		return diacritic > DIACRITIC_DOT
	end,
}
local DIACRITIC_FLAT = Diacritic.Flat
local DIACRITIC_ACUTE = Diacritic.ACUTE
local DIACRITIC_GRAVE = Diacritic.Grave
local DIACRITIC_HOOK = Diacritic.Hook
local DIACRITIC_TILDE = Diacritic.Tildle
local DIACRITIC_DOT = Diacritic.Dot
local DIACRITIC_CIRCUMFLEX = Diacritic.Circumflex
local DIACRITIC_BREVE = Diacritic.Breve
local DIACRITIC_HORN = Diacritic.Horn
local DIACRITIC_HORIZONTAL_STROKE = Diacritic.HorizontalStroke

M = {
	Diacritic = Diacritic,
	--- @type table<string, number>
	--- VOWEL_ACCENT_PRIORITY maps Vietnamese vowels with accents to their priority.
	VOWEL_PRIORITY = {
		["ơ"] = 1,
		["ê"] = 2,

		["ă"] = 3,
		["ô"] = 4,
		["â"] = 5,
		["ư"] = 6,

		["a"] = 7,
		["o"] = 8,
		["e"] = 9,

		["i"] = 10,
		["u"] = 11,

		["y"] = 12,
	},
	--- @type table<string, { [1]: string, [2]: string?, [3]: string?, tone?: Diacritic, shape?: Diacritic, up: string, lo: string }>
	--- UTF8_VN_CHAR_DICT maps a Vietnamese character with tone/diacritic
	--- to its components: [base, shape, tone], and optionally a tone enum.
	UTF8_VNCHAR_COMPONENT = {
		["á"] = { "a", "a", tone = DIACRITIC_ACUTE, up = "Á", lo = "á" },
		["à"] = { "a", "a", tone = DIACRITIC_GRAVE, up = "À", lo = "à" },
		["ả"] = { "a", "a", tone = DIACRITIC_HOOK, up = "Ả", lo = "ả" },
		["ã"] = { "a", "a", tone = DIACRITIC_TILDE, up = "Ã", lo = "ã" },
		["ạ"] = { "a", "a", tone = DIACRITIC_DOT, up = "Ạ", lo = "ạ" },

		["ă"] = { "a", "ă", shape = DIACRITIC_BREVE, up = "Ă", lo = "ă" },
		["ắ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, up = "Ắ", lo = "ắ" },
		["ằ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, up = "Ằ", lo = "ằ" },
		["ẳ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, up = "Ẳ", lo = "ẳ" },
		["ẵ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, up = "Ẵ", lo = "ẵ" },
		["ặ"] = { "a", "ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_DOT, up = "Ặ", lo = "ặ" },

		["â"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, up = "Â", lo = "â" },
		["ấ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ấ", lo = "ấ" },
		["ầ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ầ", lo = "ầ" },
		["ẩ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ẩ", lo = "ẩ" },
		["ẫ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ẫ", lo = "ẫ" },
		["ậ"] = { "a", "â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ậ", lo = "ậ" },

		["é"] = { "e", "e", tone = DIACRITIC_ACUTE, up = "É", lo = "é" },
		["è"] = { "e", "e", tone = DIACRITIC_GRAVE, up = "È", lo = "è" },
		["ẻ"] = { "e", "e", tone = DIACRITIC_HOOK, up = "Ẻ", lo = "ẻ" },
		["ẽ"] = { "e", "e", tone = DIACRITIC_TILDE, up = "Ẽ", lo = "ẽ" },
		["ẹ"] = { "e", "e", tone = DIACRITIC_DOT, up = "Ẹ", lo = "ẹ" },

		["ê"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, up = "Ê", lo = "ê" },
		["ế"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ế", lo = "ế" },
		["ề"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ề", lo = "ề" },
		["ể"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ể", lo = "ể" },
		["ễ"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ễ", lo = "ễ" },
		["ệ"] = { "e", "ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ệ", lo = "ệ" },

		["í"] = { "i", "i", tone = DIACRITIC_ACUTE, up = "Í", lo = "í" },
		["ì"] = { "i", "i", tone = DIACRITIC_GRAVE, up = "Ì", lo = "ì" },
		["ỉ"] = { "i", "i", tone = DIACRITIC_HOOK, up = "Ỉ", lo = "ỉ" },
		["ĩ"] = { "i", "i", tone = DIACRITIC_TILDE, up = "Ĩ", lo = "ĩ" },
		["ị"] = { "i", "i", tone = DIACRITIC_DOT, up = "Ị", lo = "ị" },

		["ó"] = { "o", "o", tone = DIACRITIC_ACUTE, up = "Ó", lo = "ó" },
		["ò"] = { "o", "o", tone = DIACRITIC_GRAVE, up = "Ò", lo = "ò" },
		["ỏ"] = { "o", "o", tone = DIACRITIC_HOOK, up = "Ỏ", lo = "ỏ" },
		["õ"] = { "o", "o", tone = DIACRITIC_TILDE, up = "Õ", lo = "õ" },
		["ọ"] = { "o", "o", tone = DIACRITIC_DOT, up = "Ọ", lo = "ọ" },

		["ô"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, up = "Ô", lo = "ô" },
		["ố"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, up = "Ố", lo = "ố" },
		["ồ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, up = "Ồ", lo = "ồ" },
		["ổ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, up = "Ổ", lo = "ổ" },
		["ỗ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, up = "Ỗ", lo = "ỗ" },
		["ộ"] = { "o", "ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, up = "Ộ", lo = "ộ" },

		["ơ"] = { "o", "ơ", shape = DIACRITIC_HORN, up = "Ơ", lo = "ơ" },
		["ớ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ớ", lo = "ớ" },
		["ờ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ờ", lo = "ờ" },
		["ở"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ở", lo = "ở" },
		["ỡ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ỡ", lo = "ỡ" },
		["ợ"] = { "o", "ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ợ", lo = "ợ" },

		["ú"] = { "u", "u", tone = DIACRITIC_ACUTE, up = "Ú" },
		["ù"] = { "u", "u", tone = DIACRITIC_GRAVE, up = "Ù" },
		["ủ"] = { "u", "u", tone = DIACRITIC_HOOK, up = "Ủ" },
		["ũ"] = { "u", "u", tone = DIACRITIC_TILDE, up = "Ũ" },
		["ụ"] = { "u", "u", tone = DIACRITIC_DOT, up = "Ụ" },

		["ư"] = { "u", "ư", shape = DIACRITIC_HORN, up = "Ư", lo = "ư" },
		["ứ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, up = "Ứ", lo = "ứ" },
		["ừ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, up = "Ừ", lo = "ừ" },
		["ử"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, up = "Ử", lo = "ử" },
		["ữ"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, up = "Ữ", lo = "ữ" },
		["ự"] = { "u", "ư", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, up = "Ự", lo = "ự" },

		["ý"] = { "y", "y", tone = DIACRITIC_ACUTE, up = "Ý", lo = "ý" },
		["ỳ"] = { "y", "y", tone = DIACRITIC_GRAVE, up = "Ỳ", lo = "ỳ" },
		["ỷ"] = { "y", "y", tone = DIACRITIC_HOOK, up = "Ỷ", lo = "ỷ" },
		["ỹ"] = { "y", "y", tone = DIACRITIC_TILDE, up = "Ỹ", lo = "ỹ" },
		["ỵ"] = { "y", "y", tone = DIACRITIC_DOT, up = "Ỵ", lo = "ỵ" },

		["đ"] = { "d", "d", shape = DIACRITIC_HORIZONTAL_STROKE, up = "Đ", lo = "đ" },

		-- uppercase
		["Á"] = { "A", "A", tone = DIACRITIC_ACUTE, lo = "á", up = "Á" },
		["À"] = { "A", "A", tone = DIACRITIC_GRAVE, lo = "à", up = "À" },
		["Ả"] = { "A", "A", tone = DIACRITIC_HOOK, lo = "ả", up = "Ả" },
		["Ã"] = { "A", "A", tone = DIACRITIC_TILDE, lo = "ã", up = "Ã" },
		["Ạ"] = { "A", "A", tone = DIACRITIC_DOT, lo = "ạ", up = "Ạ" },

		["Ă"] = { "A", "Ă", shape = DIACRITIC_BREVE, lo = "ă", up = "Ă" },
		["Ắ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_ACUTE, lo = "ắ", up = "Ắ" },
		["Ằ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_GRAVE, lo = "ằ", up = "Ằ" },
		["Ẳ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_HOOK, lo = "ẳ", up = "Ẳ" },
		["Ẵ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_TILDE, lo = "ẵ", up = "Ẵ" },
		["Ặ"] = { "A", "Ă", shape = DIACRITIC_BREVE, tone = DIACRITIC_DOT, lo = "ặ", up = "Ặ" },

		["Â"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, lo = "â", up = "Â" },
		["Ấ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ấ", up = "Ấ" },
		["Ầ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ầ", up = "Ầ" },
		["Ẩ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ẩ", up = "Ẩ" },
		["Ẫ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ẫ", up = "Ẫ" },
		["Ậ"] = { "A", "Â", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ậ", up = "Ậ" },

		["É"] = { "E", "E", tone = DIACRITIC_ACUTE, lo = "é", up = "É" },
		["È"] = { "E", "E", tone = DIACRITIC_GRAVE, lo = "è", up = "È" },
		["Ẻ"] = { "E", "E", tone = DIACRITIC_HOOK, lo = "ẻ", up = "Ẻ" },
		["Ẽ"] = { "E", "E", tone = DIACRITIC_TILDE, lo = "ẽ", up = "Ẽ" },
		["Ẹ"] = { "E", "E", tone = DIACRITIC_DOT, lo = "ẹ", up = "Ẹ" },

		["Ê"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, lo = "ê", up = "Ê" },
		["Ế"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ế", up = "Ế" },
		["Ề"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ề", up = "Ề" },
		["Ể"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ể", up = "Ể" },
		["Ễ"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ễ", up = "Ễ" },
		["Ệ"] = { "E", "Ê", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ệ", up = "Ệ" },

		["Í"] = { "I", "I", tone = DIACRITIC_ACUTE, lo = "í", up = "Í" },
		["Ì"] = { "I", "I", tone = DIACRITIC_GRAVE, lo = "ì", up = "Ì" },
		["Ỉ"] = { "I", "I", tone = DIACRITIC_HOOK, lo = "ỉ", up = "Ỉ" },
		["Ĩ"] = { "I", "I", tone = DIACRITIC_TILDE, lo = "ĩ", up = "Ĩ" },
		["Ị"] = { "I", "I", tone = DIACRITIC_DOT, lo = "ị", up = "Ị" },

		["Ó"] = { "O", "O", tone = DIACRITIC_ACUTE, lo = "ó", up = "Ó" },
		["Ò"] = { "O", "O", tone = DIACRITIC_GRAVE, lo = "ò", up = "Ò" },
		["Ỏ"] = { "O", "O", tone = DIACRITIC_HOOK, lo = "ỏ", up = "Ỏ" },
		["Õ"] = { "O", "O", tone = DIACRITIC_TILDE, lo = "õ", up = "Õ" },
		["Ọ"] = { "O", "O", tone = DIACRITIC_DOT, lo = "ọ", up = "Ọ" },

		["Ô"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, lo = "ô", up = "Ô" },
		["Ố"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_ACUTE, lo = "ố", up = "Ố" },
		["Ồ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_GRAVE, lo = "ồ", up = "Ồ" },
		["Ổ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_HOOK, lo = "ổ", up = "Ổ" },
		["Ỗ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_TILDE, lo = "ỗ", up = "Ỗ" },
		["Ộ"] = { "O", "Ô", shape = DIACRITIC_CIRCUMFLEX, tone = DIACRITIC_DOT, lo = "ộ", up = "Ộ" },

		["Ơ"] = { "O", "Ơ", shape = DIACRITIC_HORN, lo = "ơ", up = "Ơ" },
		["Ớ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, lo = "ớ", up = "Ớ" },
		["Ờ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, lo = "ờ", up = "Ờ" },
		["Ở"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, lo = "ở", up = "Ở" },
		["Ỡ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, lo = "ỡ", up = "Ỡ" },
		["Ợ"] = { "O", "Ơ", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, lo = "ợ", up = "Ợ" },

		["Ú"] = { "U", "U", tone = DIACRITIC_ACUTE, lo = "ú", up = "Ú" },
		["Ù"] = { "U", "U", tone = DIACRITIC_GRAVE, lo = "ù", up = "Ù" },
		["Ủ"] = { "U", "U", tone = DIACRITIC_HOOK, lo = "ủ", up = "Ủ" },
		["Ũ"] = { "U", "U", tone = DIACRITIC_TILDE, lo = "ũ", up = "Ũ" },
		["Ụ"] = { "U", "U", tone = DIACRITIC_DOT, lo = "ụ", up = "Ụ" },

		["Ư"] = { "U", "Ư", shape = DIACRITIC_HORN, lo = "ư", up = "Ư" },
		["Ứ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = DIACRITIC_ACUTE, lo = "ứ", up = "Ứ" },
		["Ừ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = DIACRITIC_GRAVE, lo = "ừ", up = "Ừ" },
		["Ử"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = DIACRITIC_HOOK, lo = "ử", up = "Ử" },
		["Ữ"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = DIACRITIC_TILDE, lo = "ữ", up = "Ữ" },
		["Ự"] = { "U", "Ư", shape = DIACRITIC_HORN, tone = DIACRITIC_DOT, lo = "ự", up = "Ự" },

		["Ý"] = { "Y", "Y", tone = DIACRITIC_ACUTE, lo = "ý", up = "Ý" },
		["Ỳ"] = { "Y", "Y", tone = DIACRITIC_GRAVE, lo = "ỳ", up = "Ỳ" },
		["Ỷ"] = { "Y", "Y", tone = DIACRITIC_HOOK, lo = "ỷ", up = "Ỷ" },
		["Ỹ"] = { "Y", "Y", tone = DIACRITIC_TILDE, lo = "ỹ", up = "Ỹ" },
		["Ỵ"] = { "Y", "Y", tone = DIACRITIC_DOT, lo = "ỵ", up = "Ỵ" },

		["Đ"] = { "D", "D", shape = DIACRITIC_HORIZONTAL_STROKE, up = "Đ", lo = "đ" },
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
	--- @type table<string, {[1]: number?}|boolean>
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
		["oo"] = { 0 },
		["oi"] = { 0 },
		["ôi"] = { 0 },
		["ơi"] = { 0 },
		["oe"] = { 0 },
		["oeo"] = { 1 },

		["ua"] = { 0 },
		["uao"] = { 1 },
		["ưa"] = { 0 },
		["uă"] = { 1 },
		["uâ"] = { 1 },
		["uây"] = { 1 },
		["ue"] = { 1 },
		["uê"] = { 1 },
		["ui"] = { 0 },
		["ưi"] = { 0 },
		["uy"] = { 0 },
		["uyu"] = { 1 },
		["uya"] = { 1 },

		["uye"] = false, -- transitional, not a valid vowel
		["uyê"] = { 2 },

		["uu"] = false, -- transitional, not a valid vowel
		["ưu"] = { 1 },

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
