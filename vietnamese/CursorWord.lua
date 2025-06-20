local tbl_concat = table.concat

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
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY

local util = require("vietnamese.util")
local method_config_util = require("vietnamese.method-config-util")

---@class CursorWord
---@field private word table A table of characters representing the word
---@field private word_len number The total number of characters in the word without the
---@field private raw table A table of characters representing the original word @field private raw_len number The total number of characters in the original word
---
---@field private inserted_char_index number The index of the cursor position in the character lis (1-based)
---@field private vowel_start number The index of the first vowel in the word (1-based)
---@field private vowel_end number The index of the last vowel in the word (1-based)
local CursorWord = {}

-- allow to access public methods and properties
CursorWord.__index = CursorWord

-- Creates a new CursorWord instancecur
--- @class CursorWord
--- @property word table A table of characters representing the word
local _privates = setmetatable({}, { __mode = "k" }) -- use weak table to store private data

local function filter_inserted_char(raw, raw_len, inserted_char_index)
	local filtered = {}
	for i = 1, inserted_char_index - 1 do
		filtered[i] = raw[i]
	end
	for i = inserted_char_index + 1, raw_len do
		filtered[i - 1] = raw[i]
	end
	return filtered, raw_len - 1
end

--- Cr-eates a new CursorWord instance
--- @param raw table a table of characters representing the word
--- @param cursor_char_index integer the index of the cursor position in the character list (1-based)
--- @param insertion boolean whether the cursor is in insertion mode (optional, defaults to false)
--- @param raw_len integer the total number of characters in the word (optional, defaults to length of char_list)
--- @return CursorWord  instance
function CursorWord:new(raw, cursor_char_index, insertion, raw_len)
	local obj = setmetatable({}, self)

	raw_len = raw_len or #raw

	local word, word_len, inserted_char_index = raw, raw_len, nil
	if insertion then
		inserted_char_index = cursor_char_index - 1
		word, word_len = filter_inserted_char(raw, raw_len, inserted_char_index)
	end

	_privates[obj] = {
		word = word,
		word_len = word_len,
		raw = raw,
		raw_len = raw_len,

		inserted_char_index = inserted_char_index,

		-- cursor_char_index == raw_len + 1
		-- if the cursor is at the end of the word
		cursor_char_index = cursor_char_index,

		vowel_start = -1,
		vowel_end = -1,
	}

	-- error(vim.inspect(_privates[obj]))
	return obj
end

function CursorWord:iter_chars(cb, raw)
	local p = _privates[self]
	local chars = raw and p.raw or p.word
	local length = raw and p.raw_len or p.word_len

	for i = 1, length, 1 do
		local char = chars[i]
		cb(i, char)
	end
end

--- Checks if the word is potential to apply diacritic
--- @param diacritic_key string the key of the diacritic to check
--- @param method_config table|nil the method configuration to use for checking
--- @return boolean true if the diacritic can be applied, false otherwise
function CursorWord:is_potential_diacritic_combinable(diacritic_key, method_config)
	vim.notify("is_potential_diacritic_combinable called with diacritic_key: " .. diacritic_key)
	if method_config == nil then
		return false
	end

	local p = _privates[self]
	local word = p.word
	if p.word_len > 1 and not util.some_vowels(word) and not util.is_exceed_repetition_vowel(word) then
		return false -- No vowel in the word, diacritic cannot be applied
	end

	local raw = p.raw
	for i = 1, p.inserted_char_index - 1 do
		local base_level1 = util.downgrade_to_level1(raw[i])
		if method_config_util.get_diacritic(diacritic_key, base_level1, method_config) then
			return true
		end
	end

	return false
end

--- Returns the cursor position in the character list
--- @return integer the cursor position (1-based)
function CursorWord:inserted_char()
	local p = _privates[self]
	return p.raw[p.inserted_char_index]
end

--- Returns the cursor position in the character list (1-based)
--- @return integer the cursor position (1-based)
function CursorWord:length(raw)
	return raw and _privates[self].raw_len or _privates[self].word_len
end

function CursorWord:get(raw)
	local p = _privates[self]
	return raw and p.raw or p.word
end

function CursorWord:remove_tone()
	local p = _privates[self]
	local main_vowel, main_vowel_index = self:find_main_vowel()
	if not main_vowel then
		return false
	end

	local vowel, removed_tone = util.strip_tone(main_vowel)
	if not removed_tone then
		return false
	end

	p.word[main_vowel_index] = vowel
	return true
end

--- Processes tone marks in the word
function CursorWord:processes_tone(method_config)
	local p = _privates[self]
	local inserted_char_index = p.inserted_char_index

	-- local decomposed_word = self:decompose_word(2)

	local main_vowel, main_vowel_index = self:find_main_vowel()
	if not main_vowel then
		return false
	elseif inserted_char_index <= main_vowel_index then
		return false
	end

	local vowel, removed_tone = util.strip_tone(main_vowel)
	local tone_diacritic = method_config_util.get_tone_diacritic(self:inserted_char(), vowel, method_config)
	if not tone_diacritic then
		return false
	elseif removed_tone == tone_diacritic then
		p.word = util.copy_list(p.raw) -- make a copy of the word)
		p.word[main_vowel_index] = vowel
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		p.word[main_vowel_index] = util.combine_diacritic(vowel, tone_diacritic)
	end
	return true
end

--- Processes diacritics in the word
function CursorWord:processes_diacritics(method_config)
	if not (self:analyzie_word_structure()) then
		return false
	end

	local p = _privates[self]

	if method_config_util.is_tone_key(self:inserted_char(), method_config) then
		return self:processes_tone(method_config)
	end
	return false
end

function CursorWord:decompose_word(level)
	local p = _privates[self]
	local word, word_len = p.word, p.word_len
	local result = {}
	for i = 1, word_len do
		local ch = word[i]
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
		return tbl_concat(p.raw)
	end
	return tbl_concat(p.word)
end

--- Finds the main vowel in the character list
--- @param chars table the character list to search
--- @param chars_size integer the length of the character list
--- @param i integer the starting index (1-based, optional)
--- @param j integer the ending index (1-based, optional)
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character in the word if found, -1 otherwise
local function find_main_vowel(chars, chars_size, i, j)
	-- Find base vowels with highest priority
	local candidate_char = nil
	local candidate_index = -1
	local min_priority = 100

	i = i and i > 0 and i or 1
	j = j and j < chars_size and j or chars_size

	for k = i, j do
		local char = chars[k]
		-- Check for tone-marked vowels first
		if util.has_tone(char) then
			return char, k
		elseif util.is_vietnamese_vowel(char) then
			local base_level2 = util.downgrade_to_level2(char)
			local priority = BASE_VOWEL_PRIORITY[base_level2]
			if priority and priority < min_priority then
				min_priority = priority
				candidate_char = char
				candidate_index = k
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
	if p.vowel_start == -1 then
		return nil, -1
	end
	return find_main_vowel(p.word, p.word_len, p.vowel_start, p.vowel_end)
end

--- Check if all characters from i to j are vowels
--- @param word table The character table
--- @param i integer The starting index (1-based)
--- @param j integer The ending index (1-based)
--- @return boolean True if all characters are vowels, false otherwise
local function is_all_vowel(word, i, j)
	for k = i, j do
		if not util.is_vietnamese_vowel(word[k]) then
			return false
		end
	end
	return true
end

--- Find the first and last vowel positions in a character table
--- @param word table The character table
--- @param len integer The length of the character table
--- @return integer first The index of the first vowel (1-based)
--- @return integer last The index of the last vowel (1-based)
--- @return boolean is_single True if the first and last vowels are the same (single vowel), false otherwise
local function find_vowel_sequence_bounds(word, len)
	vim.notify("find_vowel_sequence_bounds called with word: " .. tbl_concat(word))
	local first, last = -1, -1

	for i = 1, len do
		if util.is_vietnamese_vowel(word[i]) then
			first = i
			break
		end
	end

	if not first then
		return -1, -1, false
	end

	for i = len, 1, -1 do
		if util.is_vietnamese_vowel(word[i]) then
			last = i
			break
		end
	end

	if last - first + 1 > MAX_VOWEL_CLUSTERS_LENGTH or not is_all_vowel(word, first, last) then
		return -1, -1, false
	end

	return first, last, first == last
end

--- Validate onset (consonant cluster) before the vowel
--- @param word table The character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
--- @return integer adjust The adjustment to the first vowel index (0 or 1)
local function validate_consonant_cluster(word, vowel_start)
	vim.notify("validate_consonant_cluster called with first_vowel_idx: " .. vowel_start)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return true, 0
	elseif cluster_len > MAX_CONSONANT_CLUSTERS_LENGTH then
		return false, 0
	elseif cluster_len == 1 and ONSETS[tbl_concat(word, "", 1, 2)] then
		-- Special case: consonant overlaps with vowel
		return true, 1
	end
	return ONSETS[tbl_concat(word, "", 1, cluster_len)] ~= nil, 0
end

--- Validate onset (consonant cluster) before the vowel
--- @param word table The character table
--- @param len integer The total length of the character table
--- @param vowel_end integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
local function validate_coda_cluster(word, len, vowel_end)
	vim.notify("validate_coda_cluster called with vowel_end: " .. vowel_end)
	assert(vowel_end >= 1 and vowel_end <= len, "Invalid last vowel index")
	local cluster_len = len - vowel_end
	if cluster_len == 0 then
		return true
	elseif cluster_len > MAX_CODA_CLUSTERS_LENGTH then
		return false
	end
	return CODAS[tbl_concat(word, "", vowel_end + 1, len)] ~= nil
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
function CursorWord:analyzie_word_structure()
	local p = _privates[self]
	local word, len = p.word, p.word_len
	if len == 1 then
		-- Single character word
		-- no need to analyze, it's a valid word
		return true
	end

	local first, last, _ = find_vowel_sequence_bounds(word, len)
	if not are_valid_vowel_indices(first, last, len) then
		vim.notify("Invalid vowel indices in word: " .. tbl_concat(word))
		return false
	end

	local is_valid, adjust = validate_consonant_cluster(word, first)
	if not is_valid then
		vim.notify("Invalid consonant cluster in word: " .. tbl_concat(word))
		return false
	end

	first = first + adjust
	if not are_valid_vowel_indices(first, last, len) then
		vim.notify("Invalid vowel indices in word: " .. tbl_concat(word))
		-- The word with no vowel
		return false
	end

	if not validate_coda_cluster(word, len, last) then
		vim.notify("Invalid coda cluster in word: " .. tbl_concat(word))
		return false
	end

	p.vowel_start = first
	p.vowel_end = last

	return true
end

--- Function to validate Vietnamese word structure
function CursorWord:is_valid_vietnamese_word()
	return not self:analyzie_word_structure()
end

--- Returns the column boundaries of the cursor position
--- @param cursor_col integer The current column position of the cursor
--- @return integer start The start column boundary of the cursor position
--- @return integer end The end column boundary of the cursor position (exclusive)
function CursorWord:column_boundaries(cursor_col)
	local p = _privates[self]
	local raw = p.raw
	local cursor_char_index = p.cursor_char_index

	local start = cursor_col - #tbl_concat(raw, "", 1, cursor_char_index - 1)

	if cursor_char_index > p.raw_len then
		return start, cursor_col
	end

	local end_ = cursor_col + #tbl_concat(raw, "", cursor_char_index, p.raw_len)

	return start, end_
end

return CursorWord
