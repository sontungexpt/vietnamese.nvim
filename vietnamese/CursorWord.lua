local CONSTANT = require("vietnamese.constant")

local ONSETS = CONSTANT.ONSETS
local CODAS = CONSTANT.CODAS

local MAX_VOWEL_CLUSTERS_LENGTH = 3
local MAX_CODA_CLUSTERS_LENGTH = 2
local MAX_CONSONANT_CLUSTERS_LENGTH = 3
-- local ENUM_DIACRITIC = CONSTANT.ENUM_DIACRITIC
-- local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
-- local TONE_PLACEMENT = CONSTANT.TONE_PLACEMENT
-- local VOWEL_SEQUENCES = CONSTANT.VOWEL_SEQUENCES
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY

local util = require("vietnamese.util")
local method_config_util = require("vietnamese.method-config-util")

---@class CursorWord
---@field private chars table A table of characters representing the word
---@field private chars_len number The total number of characters in the word without the
---@field private raw_chars table A table of characters representing the original word @field private raw_chars_len number The total number of characters in the original word
---
---@field private cursor_char_index number The index of the cursor position in the character lis (1-based)
---@field private first_vowel_index number The index of the first vowel in the word (1-based)
---@field private last_vowel_index number The index of the last vowel in the word (1-based)
---
---
---
local CursorWord = {}

-- allow to access public methods and properties
CursorWord.__index = CursorWord

-- Creates a new CursorWord instancecur
--- @class CursorWord
--- @property chars table A table of characters representing the word
local _privates = setmetatable({}, { __mode = "k" }) -- use weak table to store private data

local function chars_without_cursor(raw_chars, raw_char_len, cursor_char_index)
	local new_chars = {}
	for i = 1, cursor_char_index - 1 do
		new_chars[i] = raw_chars[i]
	end
	for i = cursor_char_index + 1, raw_char_len do
		new_chars[i - 1] = raw_chars[i]
	end
	return new_chars, raw_char_len - 1
end

--- Cr-eates a new CursorWord instance
--- @param raw_chars table a table of characters representing the word
--- @param cursor_char_index integer the index of the cursor position in the character list (1-based)
--- @param insertion boolean whether the cursor is in insertion mode (optional, defaults to false)
--- @param raw_chars_len integer the total number of characters in the word (optional, defaults to length of char_list)
--- @return CursorWord  instance
function CursorWord:new(raw_chars, cursor_char_index, insertion, raw_chars_len)
	local obj = setmetatable({}, self)

	raw_chars_len = raw_chars_len or #raw_chars
	local chars, chars_len = raw_chars, raw_chars_len
	if insertion then
		chars, chars_len = chars_without_cursor(raw_chars, raw_chars_len, cursor_char_index)
	end

	--- Validate cursor position
	_privates[obj] = {
		chars = chars,
		chars_len = chars_len,
		raw_chars = raw_chars,
		raw_chars_len = raw_chars_len,

		cursor_char_index = cursor_char_index,

		first_vowel_index = nil,
		last_vowel_index = nil,
	}

	-- error(vim.inspect(_privates[obj]))
	return obj
end

function CursorWord:is_duplicate_d_or_vowel()
	local p = _privates[self]
	local chars = p.chars
	local seen = {}
	for k = 1, p.chars_len do
		local c = util.downgrade_to_level2(chars[k])
		if c == "d" or c == "D" or util.is_vietnamese_vowel(c) then
			if seen[c] then
				return true
			end
			seen[c] = true
		end
	end

	return false
end

--- Checks if at least one character in the list is a vowel
--- @param chars table the list of characters to check
--- @return boolean true if at least one character is a vowel, false otherwise
local function at_least_once_vowel(chars)
	for _, value in ipairs(chars) do
		if util.is_vietnamese_vowel(value) then
			return true
		end
	end
	return false
end

--- Checks if the word is potential to apply diacritic
--- @param diacritic_key string the key of the diacritic to check
--- @param method_config table|nil the method configuration to use for checking
--- @return boolean true if the diacritic can be applied, false otherwise
function CursorWord:is_potential_diacritic_applicable(diacritic_key, method_config)
	if method_config == nil then
		return false
	end

	local p = _privates[self]
	if p.chars_len > 1 and not at_least_once_vowel(p.chars) then
		return false -- No vowel in the word, diacritic cannot be applied
	end

	local chars = p.raw_chars
	for i = 1, p.cursor_char_index - 1 do
		local ch = chars[i]
		if method_config_util.diacritic(diacritic_key, ch, method_config) then
			-- if self:is_duplicate_d_or_vowel() then
			-- 	return false
			-- end
			return true
		end
	end

	return false
end

--- Returns the cursor position in the character list
--- @return integer the cursor position (1-based)
function CursorWord:cursor_char()
	local p = _privates[self]
	return p.raw_chars[p.cursor_char_index]
end

--- Returns the cursor position in the character list (1-based)
--- @return integer the cursor position (1-based)
function CursorWord:length(raw)
	if raw then
		return _privates[self].raw_chars_len
	end
	return _privates[self].chars_len
end

function CursorWord:get(raw)
	local p = _privates[self]
	if raw then
		return p.raw_chars
	end
	return p.chars
end

--- Returns the character at the cursor position
--- @return table the left segment of the word (characters before the cursor)
function CursorWord:left_segment()
	local p = _privates[self]
	local chars = p.raw_chars
	local result = {}
	for i = 1, p.cursor_char_index - 1 do
		result[#result + 1] = chars[i]
	end
	return result
end

----- Returns the character at the cursor position
--- @return table the right segment of the word (characters after the cursor)
function CursorWord:right_segment()
	local p = _privates[self]
	local chars = p.raw_chars
	local result = {}
	for i = p.cursor_char_index + 1, p.raw_chars_len do
		result[#result + 1] = chars[i]
	end
	return result
end

--- Processes tone marks in the word
function CursorWord:processes_tone(method_config)
	local p = _privates[self]
	local cursor_char_index = p.cursor_char_index

	-- local decomposed_chars = self:decompose_chars(2)

	local main_vowel, main_vowel_index = self:find_main_vowel()
	if not main_vowel then
		return -- No main vowel found, nothing to process
	elseif cursor_char_index <= main_vowel_index then
		return -- Cursor is before the main vowel, no need to process tone
	end

	local tone_diacritic = method_config_util.tone_diacritic(self:cursor_char(), main_vowel, method_config)
	local vowel, removed_tone = util.remove_tone_mark(main_vowel)
	if removed_tone == tone_diacritic then
		p.chars = p.raw_chars
		p.chars[main_vowel_index] = vowel
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		p.chars[main_vowel_index] = DIACRITIC_MAP[tone_diacritic]
	end
end

--- Processes diacritics in the word
function CursorWord:processes_diacritics(method_config)
	if not (self:analize_word_structure()) then
		return
	end

	local p = _privates[self]

	if method_config_util.is_tone_key(self:cursor_char(), method_config) then
		self:processes_tone(method_config)
	end
end

function CursorWord:decompose_chars(level)
	local p = _privates[self]
	local chars, chars_len = p.chars, p.chars_len
	local result = {}
	for i = 1, chars_len do
		local ch = chars[i]
		local dict = UTF8_VN_CHAR_DICT[ch]
		if dict then
			result[#result + 1] = dict[1]

			if level == 1 and dict.shape_diacritic then
				result[#result + 1] = dict.shape_diacritic
			end

			if dict.tone then
				result[#result + 1] = dict.tone
			end
		else
			result[#result + 1] = ch
		end
	end
	return result
end

function CursorWord:tostring(raw)
	local p = _privates[self]
	if raw then
		return table.concat(p.raw_chars)
	end
	return table.concat(p.chars)
end

--- Finds the main vowel in the character list
--- @param chars table the character list to search
--- @param chars_len integer the length of the character list
--- @return string}nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
local function _find_main_vowel(chars, chars_len)
	-- Check for tone-marked vowels first

	-- Find base vowels with highest priority
	local candidate_char = nil
	local candidate_index = -1
	local min_priority = 100

	for i = 1, chars_len do
		local char = chars[i]
		if util.has_tone_mark(char) then
			return char, i
		elseif util.is_vietnamese_vowel(char) then
			local base = UTF8_VN_CHAR_DICT[char][1]
			local priority = BASE_VOWEL_PRIORITY[base]
			if priority and priority < min_priority then
				min_priority = priority
				candidate_char = char
				candidate_index = i
			end
		end
	end

	return candidate_char, candidate_index
end

--- Function to find main vowel
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
function CursorWord:find_main_vowel()
	local p = _privates[self]
	return _find_main_vowel(p.chars, p.chars_len)
end

--- Check if all characters from i to j are vowels
--- @param chars table The character table
--- @param i integer The starting index (1-based)
--- @param j integer The ending index (1-based)
--- @return boolean True if all characters are vowels, false otherwise
local function is_all_vowel(chars, i, j)
	for k = i, j do
		if not util.is_vietnamese_vowel(chars[k]) then
			return false
		end
	end
	return true
end

--- Find the first and last vowel positions in a character table
--- @param chars table The character table
--- @param len integer The length of the character table
--- @return integer first The index of the first vowel (1-based)
--- @return integer last The index of the last vowel (1-based)
--- @return boolean is_single True if the first and last vowels are the same (single vowel), false otherwise
local function find_vowel_sequence_bounds(chars, len)
	local first, last = -1, -1

	for i = 1, len do
		if util.is_vietnamese_vowel(chars[i]) then
			first = i
			break
		end
	end

	if not first then
		return -1, -1, false
	end

	for i = len, 1, -1 do
		if util.is_vietnamese_vowel(chars[i]) then
			last = i
			break
		end
	end

	if last - first + 1 > MAX_VOWEL_CLUSTERS_LENGTH or not is_all_vowel(chars, first, last) then
		return -1, -1, false
	end

	return first, last, first == last
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param first_vowel_idx integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
--- @return integer adjust The adjustment to the first vowel index (0 or 1)
local function validate_consonant_cluster(chars, first_vowel_idx)
	local cluster_len = first_vowel_idx - 1
	if cluster_len == 0 then
		return true, 0
	elseif cluster_len > MAX_CONSONANT_CLUSTERS_LENGTH then
		return false, 0
	elseif cluster_len == 1 and ONSETS[table.concat(chars, "", 1, 2)] then
		-- Special case: consonant overlaps with vowel
		return true, 1
	end
	return ONSETS[table.concat(chars, "", 1, cluster_len)], 0
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param len integer The total length of the character table
--- @param last_vowel_index integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
local function validate_coda_cluster(chars, len, last_vowel_index)
	assert(last_vowel_index >= 1 and last_vowel_index <= len, "Invalid last vowel index")
	local cluster_len = len - last_vowel_index + 1
	if cluster_len == 0 then
		return true
	elseif cluster_len > MAX_CODA_CLUSTERS_LENGTH then
		return false
	end
	return CODAS[table.concat(chars, "", last_vowel_index + 1, len)] ~= nil
end

--- Ensure vowel indices are valid
--- @param first integer The index of the first vowel (1-based)
--- @param last integer The index of the last vowel (1-based)
--- @param len integer The total length of the character table
--- @return boolean True if indices are valid, false otherwise
local function are_valid_vowel_indices(first, last, len)
	if first < 1 or first > len then
		return false
	elseif last < 1 or last > len then
		return false
	elseif last < first then
		return false
	end
	return true
end

--- Analyze structure of Vietnamese word (onset + vowel cluster)
--- @return boolean True if the word structure is analizing succeed
function CursorWord:analize_word_structure()
	local p = _privates[self]
	local chars, len = p.chars, p.chars_len
	if len == 1 then
		-- Single character word
		-- no need to analyze, it's a valid word
		return true
	end

	local first, last, _ = find_vowel_sequence_bounds(chars, len)
	if not are_valid_vowel_indices(first, last, len) then
		return false
	end

	local is_valid, adjust = validate_consonant_cluster(chars, first)
	if not is_valid then
		return false
	end

	first = first + adjust
	if not are_valid_vowel_indices(first, last, len) then
		-- The word with no vowel
		return false
	end

	if not validate_coda_cluster(chars, len, last) then
		return false
	end

	p.first_vowel_index = first
	p.last_vowel_index = last

	return true
end

--- Function to validate Vietnamese word structure
function CursorWord:is_valid_vietnamese_word()
	return not self:analize_word_structure()
end

function CursorWord:column_boundaries(cursor_col)
	local p = _privates[self]
	local raw_chars = p.raw_chars
	local cursor_char_index = p.cursor_char_index
	local left_col = cursor_col - cursor_char_index
	vim.fn.strdisplaywidth(table.concat(raw_chars, "", 1, cursor_char_index - 1))
	local right_col = cursor_col
		+ vim.fn.strdisplaywidth(table.concat(raw_chars, "", cursor_char_index, p.raw_chars_len))
		- 1
	return left_col, right_col
end

return CursorWord
