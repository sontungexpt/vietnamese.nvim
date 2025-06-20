local fn = vim.fn
local split = fn.split
local tbl_concat = table.concat

local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY

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

function M.is_vietnamese_vowel(c, rejected_accent)
	c = rejected_accent and M.lower(c) or M.downgrade_to_level2(M.lower(c))
	return BASE_VOWEL_PRIORITY[c] ~= nil
end

function M.is_level1_vowel(c)
	return c:match("^[aeiouyAEIOUY]$") ~= nil
end

function M.is_vietnamese_char(char)
	if char == "" then
		return false
	elseif UTF8_VN_CHAR_DICT[char] ~= nil then
		return true
	end
	return char:match("^%a$") ~= nil
end

M.downgrade_to_level1 = function(c)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c][1] or c
end

M.downgrade = function(c, level)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c][level] or c
end

M.downgrade_to_level2 = function(c)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c][2] or c
end

M.has_tone = function(c)
	return UTF8_VN_CHAR_DICT[c] ~= nil and UTF8_VN_CHAR_DICT[c].tone ~= nil
end

M.combine_diacritic = function(c, diacritic)
	local diacritic_map = DIACRITIC_MAP[c]
	if not diacritic_map then
		return nil
	end
	return diacritic_map[diacritic] or nil
end

M.strip_tone = function(c)
	local dict = UTF8_VN_CHAR_DICT[c]
	if not dict then
		return c, nil
	end
	return dict[2], dict.tone
end

--- Check if at least one character in the list is a Vietnamese vowel
--- @param chars table the list of characters to check
--- @return boolean true if at least one character is a vowel, false otherwise
function M.some_vowels(chars)
	for _, c in ipairs(chars) do
		if M.is_vietnamese_vowel(c) then
			return true
		end
	end
	return false
end

function M.get_repetition_time_vowel(char, rejected_accent)
	if M.is_vietnamese_vowel(char, rejected_accent) then
		return math.maxinteger
	end
	local level1_c = M.downgrade_to_level1(char)
	if level1_c == "o" or level1_c == "u" then
		return 2
	end
	return 1
end

function M.is_exceed_repetition_vowel(chars, i, j)
	i = i and i > 0 and i or 1
	local len = #chars
	j = j and j < len and j or len

	local repeat_time = {}
	for k = i, j do
		local level1_c = M.downgrade_to_level1(chars[k])
		local new_repeat_time = (repeat_time[level1_c] or 0) + 1
		if new_repeat_time > M.get_repetition_time_vowel(level1_c) then
			return true
		end
		repeat_time[level1_c] = new_repeat_time
	end
	return false
end

function M.copy_list(list)
	local copy = {}
	for i = 1, #list do
		copy[i] = list[i]
	end
	return copy
end

return M
