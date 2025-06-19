local fn, api = vim.fn, vim.api
local split = fn.split
local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY
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

function M.is_vietnamese_vowel(c, not_accepted_accent)
	c = not_accepted_accent and M.lower(c) or M.downgrade_to_level2(M.lower(c))
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

M.has_tone_mark = function(c)
	return UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].tone ~= nil
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

return M
