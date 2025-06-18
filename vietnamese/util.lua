local fn, api = vim.fn, vim.api
local split = fn.split
local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local tbl_concat = table.concat

local M = {}

-- function M.iterate_utf8_string(str)
-- 	local len = strcharlen(str)
-- 	local i = 0

-- 	return function()
-- 		if i < len then
-- 			local c = strcharpart(str, i, 1)
-- 			i = i + 1
-- 			return c, i - 1
-- 		end
-- 	end
-- end

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

function M.is_vietnamese_vowel(c)
	if DIACRITIC_MAP[c] == nil then
		return false
	elseif c == "d" or c == "D" then
		return false
	end
	return true
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

M.downgrade_to_level2 = function(c)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c][2] or c
end

M.has_tone_mark = function(c)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].tone ~= nil
end

M.remove_tone_mark = function(c)
	local dict = UTF8_VN_CHAR_DICT[c]
	local curr_tone = dict and dict.tone
	if curr_tone then
		return dict[2], curr_tone
	end
	return c
end

return M
