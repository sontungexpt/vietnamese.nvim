local fn, api = vim.fn, vim.api
local strcharpart, strcharlen = fn.strcharpart, fn.strcharlen
local CONSTANT = require("vietnamese.constant")
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local tbl_concat = table.concat

local M = {}

function M.iterate_utf8_string(str)
	local len = strcharlen(str)
	local i = 0

	return function()
		if i < len then
			local c = strcharpart(str, i, 1)
			i = i + 1
			return c, i - 1
		end
	end
end

function M.lower(word)
	local word_len = strcharlen(word)
	if word_len == 1 then
		return UTF8_VN_CHAR_DICT[word] and UTF8_VN_CHAR_DICT[word].lo or word:lower()
	end

	local result = {}
	for i = 0, strcharlen(word) - 1 do
		local c = strcharpart(word, i, 1)
		result[i] = UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].lo or c:lower()
	end
	return tbl_concat(result)
end

function M.upper(word)
	local word_len = strcharlen(word)
	if word_len == 1 then
		return UTF8_VN_CHAR_DICT[word] and UTF8_VN_CHAR_DICT[word].up or word:upper()
	end

	local result = {}
	for i = 0, strcharlen(word) - 1 do
		local c = strcharpart(word, i, 1)
		result[i] = UTF8_VN_CHAR_DICT[c] and UTF8_VN_CHAR_DICT[c].up or c:upper()
	end
	return tbl_concat(result)
end

function M.is_vietnamese_vowel(c)
	if DIACRITIC_MAP[c] == nil then
		return false
	elseif c == "d" or c == "D" then
		return false
	end
	return true
end

function M.is_vietnamese_char(char)
	if char == "" then
		return false
	elseif UTF8_VN_CHAR_DICT[char] ~= nil then
		return true
	end
	return char:match("^%a$") ~= nil
end

return M
