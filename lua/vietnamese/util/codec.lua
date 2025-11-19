local bit = require("bit")
local bnot, band, bor = bit.bnot, bit.band, bit.bor
local char, byte = string.char, string.byte

local M = {}

--- @enum Diacritic
local DIACRITIC = {
	Flat = 0, -- 0b0_000_000_000

	-- Tone (shift << 6)

	Acute = 0x040, -- 0b000001_000_000
	Grave = 0x080, -- 0b000010_000_000
	Hook = 0x0C0, -- 0b000011_000_000
	Tilde = 0x100, -- 0b000100_000_000
	Dot = 0x140, -- 0b000101_000_000

	-- Shape (shift << 3)

	Circumflex = 0x008, -- 0b0_000_001_000
	Breve = 0x010, -- 0b0_000_010_000
	Horn = 0x018, -- 0b0_000_011_000
	Stroke = 0x020, -- 0b0_000_100_000
}

M.DIACRITIC = DIACRITIC

-- local BASE_SHIFT = 0
-- local SHAPE_SHIFT = 3
-- local TONE_SHIFT = 6
-- local CASE_SHIFT = 9

-- 0b0_000_000_111
local BASE_MASK = 0x07
-- 0b0_000_111_000
local SHAPE_MASK = 0x38
-- 0b0_111_000_000
local TONE_MASK = 0x1C0
-- 0b1_000_000_000
local CASE_MASK = 0x200

-- 0b1_111_000_111
local SHAPE_CLEAR = bnot(SHAPE_MASK)

-- 0b1_000_111_111
local TONE_CLEAR = bnot(TONE_MASK)

-- 0b0_111_111_111
local CASE_CLEAR = bnot(CASE_MASK)

-- Encoding layout: [case|tone|shape|base]
-- base (3 bits): a=1, e=2, i=3, o=4, u=5, y=6, d=7
-- shape (3 bits): none=0, circumflex=1, breve=2, horn=3, stroke=4
-- tone (3 bits): none=0, acute=1, grave=2, hook=3, tilde=4, dot=5
-- case (1 bit): 0=lower, 1=upper
local VN_CODEC = {
	----------------------------------------------------------------------
	-- a / ă / â
	----------------------------------------------------------------------
	-- 0b0_000_000_001
	["a"] = 0x001,
	[0x001] = "a",
	-- 0b0_001_000_001
	["á"] = 0x041,
	[0x041] = "á",
	-- 0b0_010_000_001
	["à"] = 0x081,
	[0x081] = "à",
	-- 0b0_011_000_001
	["ả"] = 0x0C1,
	[0x0C1] = "ả",
	-- 0b0_100_000_001
	["ã"] = 0x101,
	[0x101] = "ã",
	-- 0b0_101_000_001
	["ạ"] = 0x141,
	[0x141] = "ạ",

	-- 0b0_000_010_001
	["ă"] = 0x011,
	[0x011] = "ă",

	-- 0b0_001_010_001
	["ắ"] = 0x051,
	[0x051] = "ắ",

	-- 0b0_010_010_001
	["ằ"] = 0x091,
	[0x091] = "ằ",

	-- 0b0_011_010_001
	["ẳ"] = 0x0D1,
	[0x0D1] = "ẳ",

	-- 0b0_100_010_001
	["ẵ"] = 0x111,
	[0x111] = "ẵ",

	-- 0b0_101_010_001
	["ặ"] = 0x151,
	[0x151] = "ặ",

	-- 0b0_000_001_001
	["â"] = 0x009,
	[0x009] = "â",

	-- 0b0_001_001_001
	["ấ"] = 0x049,
	[0x049] = "ấ",

	-- 0b0_010_001_001
	["ầ"] = 0x089,
	[0x089] = "ầ",

	-- 0b0_011_001_001
	["ẩ"] = 0x0C9,
	[0x0C9] = "ẩ",

	-- 0b0_100_001_001
	["ẫ"] = 0x109,
	[0x109] = "ẫ",

	-- 0b0_101_001_001
	["ậ"] = 0x149,
	[0x149] = "ậ",

	----------------------------------------------------------------------
	-- e / ê
	----------------------------------------------------------------------
	-- 0b0_000_000_010
	["e"] = 0x002,
	[0x002] = "e",

	-- 0b0_001_000_010
	["é"] = 0x042,
	[0x042] = "é",

	-- 0b0_010_000_010
	["è"] = 0x082,
	[0x082] = "è",

	-- 0b0_011_000_010
	["ẻ"] = 0x0C2,
	[0x0C2] = "ẻ",

	-- 0b0_100_000_010
	["ẽ"] = 0x102,
	[0x102] = "ẽ",

	-- 0b0_101_000_010
	["ẹ"] = 0x142,
	[0x142] = "ẹ",

	-- 0b0_000_001_010
	["ê"] = 0x00A,
	[0x00A] = "ê",

	-- 0b0_001_001_010
	["ế"] = 0x04A,
	[0x04A] = "ế",

	-- 0b0_010_001_010
	["ề"] = 0x08A,
	[0x08A] = "ề",

	-- 0b0_011_001_010
	["ể"] = 0x0CA,
	[0x0CA] = "ể",

	-- 0b0_100_001_010
	["ễ"] = 0x10A,
	[0x10A] = "ễ",

	-- 0b0_101_001_010
	["ệ"] = 0x14A,
	[0x14A] = "ệ",

	----------------------------------------------------------------------
	-- i
	----------------------------------------------------------------------
	-- 0b0_000_000_011
	["i"] = 0x003,
	[0x003] = "i",
	-- 0b0_001_000_011
	["í"] = 0x043,
	[0x043] = "í",
	-- 0b0_010_000_011
	["ì"] = 0x083,
	[0x083] = "ì",
	-- 0b0_011_000_011
	["ỉ"] = 0x0C3,
	[0x0C3] = "ỉ",
	-- 0b0_100_000_011
	["ĩ"] = 0x103,
	[0x103] = "ĩ",
	-- 0b0_101_000_011
	["ị"] = 0x143,
	[0x143] = "ị",

	----------------------------------------------------------------------
	-- o / ô / ơ
	----------------------------------------------------------------------
	-- 0b0_000_000_100
	["o"] = 0x004,
	[0x004] = "o",
	-- 0b0_001_000_100
	["ó"] = 0x044,
	[0x044] = "ó",
	-- 0b0_010_000_100
	["ò"] = 0x084,
	[0x084] = "ò",
	-- 0b0_011_000_100
	["ỏ"] = 0x0C4,
	[0x0C4] = "ỏ",
	-- 0b0_100_000_100
	["õ"] = 0x104,
	[0x104] = "õ",
	-- 0b0_101_000_100
	["ọ"] = 0x144,
	[0x144] = "ọ",

	-- 0b0_000_001_100
	["ô"] = 0x00C,
	[0x00C] = "ô",
	-- 0b0_001_001_100
	["ố"] = 0x04C,
	[0x04C] = "ố",
	-- 0b0_010_001_100
	["ồ"] = 0x08C,
	[0x08C] = "ồ",
	-- 0b0_011_001_100
	["ổ"] = 0x0CC,
	[0x0CC] = "ổ",
	-- 0b0_100_001_100
	["ỗ"] = 0x10C,
	[0x10C] = "ỗ",
	-- 0b0_101_001_100
	["ộ"] = 0x14C,
	[0x14C] = "ộ",

	-- 0b0_000_011_100
	["ơ"] = 0x01C,
	[0x01C] = "ơ",
	-- 0b0_001_011_100
	["ớ"] = 0x05C,
	[0x05C] = "ớ",
	-- 0b0_010_011_100
	["ờ"] = 0x09C,
	[0x09C] = "ờ",
	-- 0b0_011_011_100
	["ở"] = 0x0DC,
	[0x0DC] = "ở",
	-- 0b0_100_011_100
	["ỡ"] = 0x11C,
	[0x11C] = "ỡ",
	-- 0b0_101_011_100
	["ợ"] = 0x15C,
	[0x15C] = "ợ",

	----------------------------------------------------------------------
	-- u / ư
	----------------------------------------------------------------------
	-- 0b0_000_000_101
	["u"] = 0x005,
	[0x005] = "u",
	-- 0b0_001_000_101
	["ú"] = 0x045,
	[0x045] = "ú",
	-- 0b0_010_000_101
	["ù"] = 0x085,
	[0x085] = "ù",
	-- 0b0_011_000_101
	["ủ"] = 0x0C5,
	[0x0C5] = "ủ",
	-- 0b0_100_000_101
	["ũ"] = 0x105,
	[0x105] = "ũ",
	-- 0b0_101_000_101
	["ụ"] = 0x145,
	[0x145] = "ụ",

	-- 0b0_000_011_101
	["ư"] = 0x01D,
	[0x01D] = "ư",
	-- 0b0_001_011_101
	["ứ"] = 0x05D,
	[0x05D] = "ứ",
	-- 0b0_010_011_101
	["ừ"] = 0x09D,
	[0x09D] = "ừ",
	-- 0b0_011_011_101
	["ử"] = 0x0DD,
	[0x0DD] = "ử",
	-- 0b0_100_011_101
	["ữ"] = 0x11D,
	[0x11D] = "ữ",
	-- 0b0_101_011_101
	["ự"] = 0x15D,
	[0x15D] = "ự",

	----------------------------------------------------------------------
	-- y
	----------------------------------------------------------------------
	-- 0b0_000_000_110
	["y"] = 0x006,
	[0x006] = "y",
	-- 0b0_001_000_110
	["ý"] = 0x046,
	[0x046] = "ý",
	-- 0b0_010_000_110
	["ỳ"] = 0x086,
	[0x086] = "ỳ",
	-- 0b0_011_000_110
	["ỷ"] = 0x0C6,
	[0x0C6] = "ỷ",
	-- 0b0_100_000_110
	["ỹ"] = 0x106,
	[0x106] = "ỹ",
	-- 0b0_101_000_110
	["ỵ"] = 0x146,
	[0x146] = "ỵ",

	----------------------------------------------------------------------
	-- d / đ
	----------------------------------------------------------------------
	-- 0b0_000_000_111
	["d"] = 0x007,
	[0x007] = "d",

	-- 0b0_000_100_111
	["đ"] = 0x027,
	[0x027] = "đ",

	----------------------------------------------------------------------
	-- Uppercase variants (case bit = 1)
	----------------------------------------------------------------------
	-- 0b1_000_000_001
	["A"] = 0x201,
	[0x201] = "A",
	-- 0b1_001_000_001
	["Á"] = 0x241,
	[0x241] = "Á",
	-- 0b1_010_000_001
	["À"] = 0x281,
	[0x281] = "À",
	-- 0b1_011_000_001
	["Ả"] = 0x2C1,
	[0x2C1] = "Ả",
	-- 0b1_100_000_001
	["Ã"] = 0x301,
	[0x301] = "Ã",
	-- 0b1_101_000_001
	["Ạ"] = 0x341,
	[0x341] = "Ạ",

	-- 0b1_000_010_001
	["Ă"] = 0x221,
	[0x221] = "Ă",
	-- 0b1_001_010_001
	["Ắ"] = 0x261,
	[0x261] = "Ắ",
	-- 0b1_010_010_001
	["Ằ"] = 0x2A1,
	[0x2A1] = "Ằ",
	-- 0b1_011_010_001
	["Ẳ"] = 0x2E1,
	[0x2E1] = "Ẳ",
	-- 0b1_100_010_001
	["Ẵ"] = 0x321,
	[0x321] = "Ẵ",
	-- 0b1_101_010_001
	["Ặ"] = 0x361,
	[0x361] = "Ặ",

	-- 0b1_000_001_001
	["Â"] = 0x209,
	[0x209] = "Â",
	-- 0b1_001_001_001
	["Ấ"] = 0x249,
	[0x249] = "Ấ",
	-- 0b1_010_001_001
	["Ầ"] = 0x289,
	[0x289] = "Ầ",
	-- 0b1_011_001_001
	["Ẩ"] = 0x2C9,
	[0x2C9] = "Ẩ",
	-- 0b1_100_001_001
	["Ẫ"] = 0x309,
	[0x309] = "Ẫ",
	-- 0b1_101_001_001
	["Ậ"] = 0x349,
	[0x349] = "Ậ",

	-- 0b1_000_000_010
	["E"] = 0x202,
	[0x202] = "E",
	-- 0b1_001_000_010
	["É"] = 0x242,
	[0x242] = "É",
	-- 0b1_010_000_010
	["È"] = 0x282,
	[0x282] = "È",
	-- 0b1_011_000_010
	["Ẻ"] = 0x2C2,
	[0x2C2] = "Ẻ",
	-- 0b1_100_000_010
	["Ẽ"] = 0x302,
	[0x302] = "Ẽ",
	-- 0b1_101_000_010
	["Ẹ"] = 0x342,
	[0x342] = "Ẹ",

	-- 0b1_000_001_010
	["Ê"] = 0x20A,
	[0x20A] = "Ê",
	-- 0b1_001_001_010
	["Ế"] = 0x24A,
	[0x24A] = "Ế",
	-- 0b1_010_001_010
	["Ề"] = 0x28A,
	[0x28A] = "Ề",
	-- 0b1_011_001_010
	["Ể"] = 0x2CA,
	[0x2CA] = "Ể",
	-- 0b1_100_001_010
	["Ễ"] = 0x30A,
	[0x30A] = "Ễ",
	-- 0b1_101_001_010
	["Ệ"] = 0x34A,
	[0x34A] = "Ệ",

	-- 0b1_000_000_011
	["I"] = 0x203,
	[0x203] = "I",
	-- 0b1_001_000_011
	["Í"] = 0x243,
	[0x243] = "Í",
	-- 0b1_010_000_011
	["Ì"] = 0x283,
	[0x283] = "Ì",
	-- 0b1_011_000_011
	["Ỉ"] = 0x2C3,
	[0x2C3] = "Ỉ",
	-- 0b1_100_000_011
	["Ĩ"] = 0x303,
	[0x303] = "Ĩ",
	-- 0b1_101_000_011
	["Ị"] = 0x343,
	[0x343] = "Ị",

	-- 0b1_000_000_100
	["O"] = 0x204,
	[0x204] = "O",
	-- 0b1_001_000_100
	["Ó"] = 0x244,
	[0x244] = "Ó",
	-- 0b1_010_000_100
	["Ò"] = 0x284,
	[0x284] = "Ò",
	-- 0b1_011_000_100
	["Ỏ"] = 0x2C4,
	[0x2C4] = "Ỏ",
	-- 0b1_100_000_100
	["Õ"] = 0x304,
	[0x304] = "Õ",
	-- 0b1_101_000_100
	["Ọ"] = 0x344,
	[0x344] = "Ọ",

	-- 0b1_000_001_100
	["Ô"] = 0x20C,
	[0x20C] = "Ô",
	-- 0b1_001_001_100
	["Ố"] = 0x24C,
	[0x24C] = "Ố",
	-- 0b1_010_001_100
	["Ồ"] = 0x28C,
	[0x28C] = "Ồ",
	-- 0b1_011_001_100
	["Ổ"] = 0x2CC,
	[0x2CC] = "Ổ",
	-- 0b1_100_001_100
	["Ỗ"] = 0x30C,
	[0x30C] = "Ỗ",
	-- 0b1_101_001_100
	["Ộ"] = 0x34C,
	[0x34C] = "Ộ",

	-- 0b1_000_011_100
	["Ơ"] = 0x21C,
	[0x21C] = "Ơ",
	-- 0b1_001_011_100
	["Ớ"] = 0x25C,
	[0x25C] = "Ớ",
	-- 0b1_010_011_100
	["Ờ"] = 0x29C,
	[0x29C] = "Ờ",
	-- 0b1_011_011_100
	["Ở"] = 0x2DC,
	[0x2DC] = "Ở",
	-- 0b1_100_011_100
	["Ỡ"] = 0x31C,
	[0x31C] = "Ỡ",
	-- 0b1_101_011_100
	["Ợ"] = 0x35C,
	[0x35C] = "Ợ",

	-- 0b1_000_000_101
	["U"] = 0x205,
	[0x205] = "U",
	-- 0b1_001_000_101
	["Ú"] = 0x245,
	[0x245] = "Ú",
	-- 0b1_010_000_101
	["Ù"] = 0x285,
	[0x285] = "Ù",
	-- 0b1_011_000_101
	["Ủ"] = 0x2C5,
	[0x2C5] = "Ủ",
	-- 0b1_100_000_101
	["Ũ"] = 0x305,
	[0x305] = "Ũ",
	-- 0b1_101_000_101
	["Ụ"] = 0x345,
	[0x345] = "Ụ",

	-- 0b1_000_011_101
	["Ư"] = 0x21D,
	[0x21D] = "Ư",
	-- 0b1_001_011_101
	["Ứ"] = 0x25D,
	[0x25D] = "Ứ",
	-- 0b1_010_011_101
	["Ừ"] = 0x29D,
	[0x29D] = "Ừ",
	-- 0b1_011_011_101
	["Ử"] = 0x2DD,
	[0x2DD] = "Ử",
	-- 0b1_100_011_101
	["Ữ"] = 0x31D,
	[0x31D] = "Ữ",
	-- 0b1_101_011_101
	["Ự"] = 0x35D,
	[0x35D] = "Ự",

	-- 0b1_000_000_110
	["Y"] = 0x206,
	[0x206] = "Y",

	-- 0b1_001_000_110
	["Ý"] = 0x246,
	[0x246] = "Ý",

	-- 0b1_010_000_110
	["Ỳ"] = 0x286,
	[0x286] = "Ỳ",

	-- 0b1_011_000_110
	["Ỷ"] = 0x2C6,
	[0x2C6] = "Ỷ",

	-- 0b1_100_000_110
	["Ỹ"] = 0x306,
	[0x306] = "Ỹ",

	-- 0b1_101_000_110
	["Ỵ"] = 0x346,
	[0x346] = "Ỵ",

	-- 0b1_000_000_111
	["D"] = 0x207,
	[0x207] = "D",

	-- 0b1_000_100_111
	["Đ"] = 0x227,
	[0x227] = "Đ",
}
local DCODE = VN_CODEC["d"]

--- Check if a character is uppercase
--- @param c string The character to checks
--- @return boolean True if the character is uppercase, false otherwise
M.is_lower = function(c)
	local code = VN_CODEC[c]
	if code then
		--- @cast code integer
		return band(code, CASE_MASK) == 0
	end

	local b = byte(c)
	return b > 64 and b < 91
end

--- Convert a character to lowercase
--- @param c string: The character to convert
--- @return string: The lowercase version of the character
M.lower_char = function(c)
	local len = #c
	if len == 1 then
		local b = byte(c)
		-- Convert uppercase ASCII to lowercase
		return b > 64 and b < 91 and char(b + 32) or c
	elseif len == 2 or len == 3 then
		local code = VN_CODEC[c]
		---@diagnostic disable-next-line: return-type-mismatch, param-type-mismatch
		return code and VN_CODEC[band(code, CASE_CLEAR)] or c
	elseif len == 0 or len == 4 then
		return c
	end
	error("Invalid character length: " .. len .. " for character: " .. c)
end

--- Check if a character is uppercase
--- @param c string The character to checks
--- @return boolean True if the character is uppercase, false otherwise
M.is_upper = function(c)
	local code = VN_CODEC[c]
	if code then
		--- @cast code integer
		return band(code, CASE_MASK) ~= 0
	end
	local b = byte(c)
	return b > 64 and b < 91
end

--- Convert a character to uppercase
--- @param c string: The character to Convert
--- @return string upper The uppercase version of the characters
M.upper_char = function(c)
	local len = #c
	if len == 1 then
		local b = byte(c)
		return b > 96 and b < 123 and char(b - 32) or c
	elseif len == 2 or len == 3 then
		local code = VN_CODEC[c]
		---@diagnostic disable-next-line: return-type-mismatch, param-type-mismatch
		return code and VN_CODEC[bor(code, CASE_MASK)] or c
	elseif len == 0 or len == 4 then
		return c
	end
	error("Invalid character length: " .. len .. " for character: " .. c)
end

--- Get the base of a Vietnamese character in lowercase
--- @param c string The character to check
--- @return string base The base of the character (always lowercase)
local base = function(c)
	local code = VN_CODEC[c]
	---@cast code integer
	---@diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[band(code, BASE_MASK)] or c
end
M.base = base

--- Get the base of a Vietnamese character with the case is preserved
--- @param c string The character to check
--- @return string base The base of the character (with the case preserved)
M.base_with_case = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	--- @diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[band(code, bor(BASE_MASK, CASE_MASK))] or c:lower()
end

--- Check if a character has a tone
--- @param c string The character to check
--- @return boolean had True if the character has a tone, false otherwise
M.has_tone = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	return code and band(code, TONE_MASK) ~= 0 or false
end

--- Get the tone mark of a Vietnamese character
--- @param c string The character to check
--- @return Diacritic tone The tone mark of the character
M.tone = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	return code and band(code, TONE_MASK) or DIACRITIC.Flat
end

--- Strip the tone mark of a Vietnamese character
--- @param c string The character to strip the tone mark from
--- @return string removed_tone_char The character without the tone mark (level 1 character), or the original character if no tone mark was find
M.strip_tone = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	---@diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[band(code, TONE_CLEAR)] or c
end

--- Strip the tone from a character
--- @param c string The character to strip the tone from
--- @return string removed_tone_char The character without the tone mark (level 1 character), or the original character if no tone mark was find
--- @return Diacritic removed_tone The tone if it was stripped, or DIACRITIC.Flat if no tone was found
M.strip_tone2 = function(c)
	local code = VN_CODEC[c]
	if not code then
		return c, DIACRITIC.Flat
	end
	--- @cast code integer
	local tone = band(code, TONE_MASK)
	--- @cast tone Diacritic
	---@diagnostic disable-next-line: return-type-mismatch
	return (tone == 0 and c or VN_CODEC[band(code, TONE_CLEAR)]), tone
end

--- Check if a character has a shape
--- @param c string The character to check
--- @return boolean had True if the character has a shape, false otherwise
M.has_shape = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	return code and band(code, SHAPE_MASK) ~= 0 or false
end

--- Get the shape of a Vietnamese character
--- @param c string The character to check
--- @return Diacritic shape The shape of the character
M.shape = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	return code and band(code, SHAPE_MASK) or DIACRITIC.Flat
end

--- Strip the shape of a Vietnamese character
--- @param c string The character to strip the shape from
--- @return string removed_shape_char The character without the shape (level 1 character), or the original character if no shape was find
M.strip_shape = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	---@diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[band(code, SHAPE_CLEAR)] or c
end

--- Strip the shape from a Vietnamese character
--- @param c string The character to strip the shape from
--- @return string removed_shape_char The character without the shape (level 1 character), or the original character if no shape was find_vowel_seq_bounds
--- @return Diacritic stripped_shape The shape of the character if it exists, or nil if notify
M.strip_shape2 = function(c)
	local code = VN_CODEC[c]
	if not code then
		return c, DIACRITIC.Flat
	end
	--- @cast code integer
	local shape = band(code, SHAPE_MASK)
	--- @cast shape Diacritic
	---@diagnostic disable-next-line: return-type-mismatch
	return (shape == 0 and c or VN_CODEC[band(code, SHAPE_CLEAR)]), shape
end

--- Check if a Vietnamese character has a diacritic
--- @param c string The character to check
--- @param diacritic Diacritic The diacritic to check for
--- @return boolean had True if the character has the diacritic, false otherwise
M.diacritic_mergeable = function(c, diacritic)
	local code = VN_CODEC[c]
	--- @cast code integer
	--- 1. Convert to base because all tone is valid if it's is a vowel but shape is only addable in
	--- base value
	--- 2. Try add diacritic to base value
	--- 3. If it's a valid character, return true
	return code and VN_CODEC[bor(band(code, BASE_MASK), diacritic)] ~= nil or false
end

--- Add a diacritic to a Vietnamese character
--- @param c string The character to add the diacritic to
--- @param diacritic Diacritic The diacritic to add
--- @param strip_shape_too? boolean Whether to strip the shape of the character when diacritic is `DIACRITIC.Flat`
--- @return string c The character with the diacritic added
M.merge_diacritic = function(c, diacritic, strip_shape_too)
	-- Remove diacritic
	if diacritic == DIACRITIC.Flat then
		return strip_shape_too and base(c) or M.strip_tone(c)
	end
	local code = VN_CODEC[c]
	--- @cast code integer
	--- < 33 means it's shape and we remove the current diacritic before adding new one
	--- @diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[bor(band(code, diacritic < 33 and SHAPE_CLEAR or TONE_CLEAR), diacritic)] or c
end

--- Unpack a Vietnamese character into its base character, shape, and tone
--- @param c string The character to unpack
--- @return string base_char The base character of the character
--- @return Diacritic shape The shape of the character
--- @return Diacritic tone The tone of the character
M.unpack_char = function(c)
	local code = VN_CODEC[c]
	if not code then
		return c, DIACRITIC.Flat, DIACRITIC.Flat
	end
	--- @cast code integer
	--- @diagnostic disable-next-line: return-type-mismatch
	return VN_CODEC[band(code, BASE_MASK)], band(code, SHAPE_MASK), band(code, TONE_MASK)
end

--- Strip the tone and lower Vietnamese character
--- @param c string The character to strip the tone and case from
--- @return string removed_tone_case_char The character without the tone mark (level 1 character), or the original character if no tone mark was find
M.strip_tone_case = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	---@diagnostic disable-next-line: return-type-mismatch
	return code and VN_CODEC[band(code, band(TONE_CLEAR, CASE_CLEAR))] or c:lower()
end

--- Check if a character is "d" or "đ" or "D" or "Đ"
--- @param c string The character to check
--- @return boolean is_dD True if the character is "d" or "đ" or "D" or "Đ", false otherwise
M.is_dD = function(c)
	return c == "d" or c == "đ" or c == "D" or c == "Đ"
end

--- Check if a character is a Vietnamese vowel
--- @param c string The character to check
--- @return boolean is_vowel True if the character is a Vietnamese vowel, false otherwise
M.is_vn_vowel = function(c)
	local code = VN_CODEC[c]
	--- @cast code integer
	--- convert đ, Đ, D to d and check
	return code and band(code, BASE_MASK) ~= DCODE or false
end

--- Check if a character is a Vietnamese character
--- @param c string The character to check
--- @return boolean is_vietnamese_char True if the character is a Vietnamese character, false otherwise
M.is_vn_char = function(c)
	local b1, b2 = byte(c, 1, 2)
	return b2 == nil and (
			(b1 > 96 and b1 < 123) -- a-z
			or (b1 > 64 and b1 < 91) -- A-Z
		) or VN_CODEC[c] ~= nil -- is special vn chars like ư or ẻ ...
end

return M
