local fn, api = vim.fn, vim.api
local split = fn.split
local nvim_buf_get_text = api.nvim_buf_get_text
local tbl_concat = table.concat

local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY
local ENUM_DIACRITIC = CONSTANT.ENUM_DIACRITIC

local M = {}

--- Reverse a table in place
--- @param tbl table: Table to reverse
--- @param len number: Optional length of the table to reverse (default is #tbl)
--- @return table: Reversed table
M.reverse_list = function(tbl, len)
	len = len or #tbl
	if len < 2 then
		return tbl
	end

	for i = 1, math.floor(len / 2) do
		tbl[i], tbl[len - i + 1] = tbl[len - i + 1], tbl[i]
	end
	return tbl
end

function M.lower(word)
	local chars = split(word, "\\zs")
	for i = 1, #chars do
		local c = chars[i]
		chars[i] = UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].lo or c:lower()
	end
	return tbl_concat(chars)
end

function M.upper(word)
	local chars = split(word, "\\zs")
	for i = 1, #chars do
		local c = chars[i]
		chars[i] = UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].up or c:upper()
	end
	return tbl_concat(chars)
end

--- Check if a character is a Vietnamese vowel
--- @param c string The character to check
--- @param strict boolean|nil If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @return boolean True if the character is a Vietnamese vowel, false otherwise
function M.is_vietnamese_vowel(c, strict)
	assert(c, "c must not be nil")
	c = strict and M.lower(c) or M.level(M.lower(c), 2)
	return BASE_VOWEL_PRIORITY[c] ~= nil
end

function M.is_level1_vowel(c)
	return c:match("^[aeiouyAEIOUY]$") ~= nil
end

--- Check if a character is a Vietnamese character
--- @param char string The character to check
--- @return boolean True if the character is a Vietnamese character, false otherwise
function M.is_vietnamese_char(char)
	if char == nil or char == "" then
		return false
	elseif UTF8_VN_CHAR_DICT[char] ~= nil then
		return true
	end
	return char:match("^%a$") ~= nil
end

--- Get the level of a Vietnamese character
--- @param c string The character to check
--- @param level 1|2 The level to check (1 or 2)
--- @return string The character at the specified level, or the original character if not found
M.level = function(c, level)
	assert(c, "c must not be nil")
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c][level] or c
end

--- Check if a character has a tone
--- @param c string The character to check
--- @return boolean True if the character has a tone, false otherwise
M.has_tone_marked = function(c)
	return UTF8_VN_CHAR_DICT[c] ~= nil and UTF8_VN_CHAR_DICT[c].tone ~= nil
end

--- Attach a tone to a level 2 Vietnamese character
--- @param lv2_c string The level 2 character to attach the tone to
--- @param tone ENUM_DIACRITIC The tone to attach_tone_to_lv2_char
--- @return string The character with the attached tone, or the original character if no tone was found
--- @return boolean True if the tone was successfully attached, false otherwise
M.merge_tone_to_lv2_vowel = function(lv2_c, tone)
	assert(lv2_c ~= nil, "c must not be nil")
	assert(tone ~= nil, "tone must not be nil")
	local tone_map = DIACRITIC_MAP[lv2_c]

	if not tone_map then
		-- not a valid char
		return lv2_c, false
	end
	local result = tone_map[tone]
	return result or lv2_c, result ~= nil
end

--- Merge a diacritic into a character
--- @param c string The character to merge the diacritic into
--- @param diacritic string The diacritic to merge
--- @param force boolean|nil If true, forces the merge even if the diacritic is not applicable
--- @return string The character with the merged diacritic, or the original character if no merge was possible
--- @return ENUM_DIACRITIC|nil The original diacritic if it was replaced, or nil if no replace was possible
M.merge_diacritic = function(c, diacritic, force)
	assert(c ~= nil, "c must not be nil")
	assert(diacritic ~= nil, "diacritic must not be nil")
	if ENUM_DIACRITIC.is_tone_removal(diacritic) then
		return M.strip_tone(c)
	end
	local is_tone = ENUM_DIACRITIC.is_tone(diacritic)
	local lv1, lv2, shape, tone = M.decompose_char(c)
	if is_tone then
		local tone_map = DIACRITIC_MAP[lv2]
		if not tone_map then
			-- not a valid char
			return c, nil
		elseif not force and tone then
			-- had tone already, return original character
			return c, nil
		end
		-- return c if is d char
		return tone_map[diacritic] or c, tone
	end
	local shape_map = DIACRITIC_MAP[lv1]
	if not shape_map then
		-- not a valid char
		return c, nil
	elseif not force and shape then
		--- had shape already, return original character
		return c, nil
	end
	local shaped = shape_map[diacritic]
	if not shaped then
		-- not a valid diacritic for this char
		return c, nil
	elseif tone and DIACRITIC_MAP[shaped] and DIACRITIC_MAP[shaped][tone] then
		-- restore the tone if it exists
		return DIACRITIC_MAP[shaped][tone], shape
	end
	return shaped, shape
end

M.unique_tone_marked = function(chars, chars_size, i, j)
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")
	i = i and i > 0 and i or 1
	j = j and j < chars_size and j or chars_size

	local count = 0
	for k = i, j do
		local c = chars[k]
		if M.has_tone_marked(c) then
			count = count + 1
		end
		if count > 1 then
			return false
		end
	end
	return true
end

--- Strip the tone from a character
--- @param c string The character to strip the tone from
--- @return string The character without the tone (lv2 char), or the original character if no tone was found
--- @return ENUM_DIACRITIC|nil The tone if it was stripped, or nil if no tone was found
M.strip_tone = function(c)
	local dict = UTF8_VN_CHAR_DICT[c]
	if not dict then
		return c, nil
	end
	return dict[2], dict.tone
end

M.strip_diacritics = function(c)
	local dict = UTF8_VN_CHAR_DICT[c]
	if not dict then
		return c, nil, nil
	end
	return dict[1], dict.shape, dict.tone
end

--- Check if at least one character in the list is a Vietnamese vowel
--- @param chars table the list of characters to check
--- @return boolean true if at least one character is a vowel, false otherwise
function M.some_vowels(chars, chars_size, strict)
	for i = 1, chars_size do
		local c = chars[i]
		if M.is_vietnamese_vowel(c, strict) then
			return true
		end
	end
	return false
end

--- Check if all characters from i to j are vowels
--- @param chars table The character table
--- @param chars_size integer The size of the character table
--- @param i integer The starting index (1-based)
--- @param j integer The ending index (1-based)
--- @return boolean True if all characters are vowels, false otherwise
function M.all_vowels(chars, chars_size, strict, i, j)
	assert(chars, "chars must not be nil")
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")

	i = i and i > 0 and i or 1
	j = j and j < chars_size and j or chars_size

	for k = i, j do
		if not M.is_vietnamese_vowel(chars[k], strict) then
			return false
		end
	end
	return true
end

function M.get_repetition_time_vowel(char, rejected_accent)
	if M.is_vietnamese_vowel(char, rejected_accent) then
		return math.maxinteger
	end
	local level1_c = M.level(char, 1)
	if level1_c == "o" or level1_c == "u" then
		return 2
	end
	return 1
end

function M.is_exceeded_vowel_repetition_time(chars, chars_size, i, j)
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")
	i = i and i > 0 and i or 1
	j = j and j < chars_size and j or chars_size

	local repeat_time = {}
	for k = i, j do
		local level1_c = M.level(chars[k], 1)
		local repetition_times = (repeat_time[level1_c] or 0) + 1
		if repetition_times > M.get_repetition_time_vowel(level1_c) then
			return true
		end
		repeat_time[level1_c] = repetition_times
	end
	return false
end

--- Decompose a Vietnamese character into its base character, diacritic, shape diacritic, and tone
--- @param c string The character to decompose_char
--- @return string The base character at level 1
--- @return string The character at level 2
--- @return ENUM_DIACRITIC|nil The shape diacritic if it exists, or nil if not
--- @return ENUM_DIACRITIC|nil The tone if it exists, or nil if not
function M.decompose_char(c)
	assert(c, "c must not be nil")
	local dict = UTF8_VN_CHAR_DICT[c]
	if not dict then
		return c, c, nil, nil
	end
	return dict[1], dict[2], dict.shape, dict.tone
end

function M.copy_list(list)
	local copy = {}
	for i = 1, #list do
		copy[i] = list[i]
	end
	return copy
end

--- Get the byte offset of a column in a row of buffers
--- @param bufnr number: Buffer number
--- @param row0based number: Line number (0-based)
--- @param col0based number: Column number (0-based)
--- @return number: Byte offset of the column in the line
function M.col_to_byteoffset(bufnr, row0based, col0based)
	--- byteoffset is start from 0
	local byteoffset = #(nvim_buf_get_text(bufnr, row0based, 0, row0based, col0based, {})[1] or "")
	return byteoffset
end

return M
