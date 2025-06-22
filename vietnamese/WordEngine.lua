local tbl_concat = table.concat

local CONSTANT = require("vietnamese.constant")

local ONSETS = CONSTANT.ONSETS
local CODAS = CONSTANT.CODAS
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local BASE_VOWEL_PRIORITY = CONSTANT.BASE_VOWEL_PRIORITY

local TRIPTHONGS_LENGTH = 3
local MAX_CODA_CLUSTERS_LENGTH = 2
local MAX_CONSONANT_CLUSTERS_LENGTH = 3

local util = require("vietnamese.util")
local method_config_util = require("vietnamese.util.method-config")

--- @class WordEngine
--- Represents a Vietnamese word. Provides utilities for analyzing vowel clusters,
--- determining the main vowel, and applying tone marks. Supports cursor-based character insertion.
local WordEngine = {}

-- allow to access public methods and properties
WordEngine.__index = WordEngine

--- Stores internal fields for each WordEngine instance
--- @class PrivateWordEngineFields
--- @field word string[] List of characters for processing
--- @field word_len number Length of `word`
--- @field raw string[] Original list of characters before modification
--- @field raw_len number Length of `raw`
--- @field inserted_char_index number? Index of the recently inserted character (if any)
--- @field cursor_char_index number Current cursor position (1-based)
--- @field vowel_start number Index of the start of the vowel cluster (1-based)
--- @field vowel_end number Index of the end of the vowel cluster (1-based)
--- @field vowel_start_adjust number Offset if the onset overlaps with the vowel cluster
--- @field analyzed boolean Whether the word structure has been analyzed
--- @field analyzed_success boolean Whether the analysis was successful
local _privates = setmetatable({}, { __mode = "k" }) --- @type table<WordEngine, PrivateWordEngineFields>

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
--- @return WordEngine  instance
function WordEngine:new(raw, cursor_char_index, insertion, raw_len)
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

		analyzed = false, -- whether the word structure has been analyzed
		analyzed_success = false, -- whether the word structure is valid

		vowel_start_adjust = 0, -- adjust the vowel start index if the onset overlaps with the vowel
		vowel_start = -1,
		vowel_end = -2, -- -2 to make sure that it is not valid when loop from start to end
	}

	-- error(vim.inspect(_privates[obj]))
	return obj
end

function WordEngine:iter_chars(cb, use_raw)
	local p = _privates[self]
	local chars = use_raw and p.raw or p.word
	local length = use_raw and p.raw_len or p.word_len

	for i = 1, length, 1 do
		local char = chars[i]
		cb(i, char)
	end
end

function WordEngine:is_potential_vnword()
	local p = _privates[self]
	local word = p.word
	local word_len = p.word_len
	if
		word_len > 1
		and not util.some_vowels(word, word_len)
		and not util.is_exceeded_vowel_repetition_time(word, word_len)
		and not util.unique_tone_marked(word, word_len)
	then
		return false -- No vowel in the word, diacritic cannot be applied
	end
	return true
end

--- Checks if the word is potential to apply diacritic
--- @param key string the key of the diacritic to check
--- @param method_config table|nil the method configuration to use for checking
--- @return boolean true if the diacritic can be applied, false otherwise
function WordEngine:is_potential_diacritic_key(key, method_config)
	assert(key ~= nil, "diacritic_key must not be nil")
	assert(type(method_config) == "table", "method_config must not be nil")

	local p = _privates[self]
	local raw = p.raw
	for i = 1, p.inserted_char_index - 1 do
		local ch = raw[i]
		if method_config_util.get_diacritic(key, ch, method_config) then
			return true
		end
	end

	return false
end

--- Returns the cursor position in the character list
--- @return string the character at the cursor position
function WordEngine:inserted_char()
	local p = _privates[self]
	return p.raw[p.inserted_char_index]
end

--- Returns the cursor position in the character list (1-based)
--- @return integer the cursor position (1-based)
function WordEngine:length(use_raw)
	return use_raw and _privates[self].raw_len or _privates[self].word_len
end

function WordEngine:get(use_raw)
	local p = _privates[self]
	return use_raw and p.raw or p.word
end

function WordEngine:remove_tone(method_config)
	local p = _privates[self]
	local main_vowel, main_vowel_index = self:find_main_vowel()
	if not main_vowel then
		return false
	end

	local vowel, removed_tone = util.strip_tone(main_vowel)
	if not removed_tone then
		-- add like a normal character
		p.word = util.copy_list(p.raw) -- make a copy of the word
		p.word_len = p.raw_len
		return false
	end
	p.word[main_vowel_index] = vowel
	return true
end

--- Processes tone marks in the word
function WordEngine:processes_tone(method_config)
	local p = _privates[self]
	local inserted_char_index = p.inserted_char_index

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
		p.word_len = p.raw_len
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		p.word[main_vowel_index] = util.merge_tone_to_lv2_vowel(vowel, tone_diacritic)
	end
	return true
end

--- Processes diacritics in the word
function WordEngine:processes_diacritic(method_config)
	if not (self:analyzie_word_structure()) then
		return false
	end
	-- local p = _privates[self]
	--
	local inserted_char = self:inserted_char()
	if method_config_util.is_tone_removal_key(inserted_char, method_config) then
		return self:remove_tone(method_config)
	end

	if method_config_util.is_tone_key(inserted_char, method_config) then
		return self:processes_tone(method_config)
	end
	return false
end

function WordEngine:decompose_word(level)
	local p = _privates[self]
	local word, word_len = p.word, p.word_len
	local result = {}
	for i = 1, word_len do
		local ch = word[i]
		local dict = UTF8_VN_CHAR_DICT[ch]
		if dict then
			result[#result + 1] = dict[1]

			if level == 1 and dict.shape then
				result[#result + 1] = dict.shape
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

function WordEngine:tostring(raw)
	local p = _privates[self]
	if raw then
		return tbl_concat(p.raw)
	end
	return tbl_concat(p.word)
end

--- Calculates the length of a vowel cluster
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return integer The length of the vowel cluster_len
local function caculate_vowel_length(vowel_start, vowel_end)
	return vowel_end - vowel_start + 1
end

--- Function to find main vowel
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
function WordEngine:find_main_vowel()
	self:analyzie_word_structure()

	local p = _privates[self]
	if p.vowel_start == -1 then
		return nil, -1
	end

	local vowel_start, vowel_end = p.vowel_start, p.vowel_end
	local vowel_length = caculate_vowel_length(vowel_start, vowel_end)

	if vowel_length == 1 then
		return p.word[vowel_start], vowel_start
	elseif vowel_length == TRIPTHONGS_LENGTH then
		local main_vowel_index = vowel_start + 1
		return p.word[main_vowel_index], main_vowel_index
	end

	local word = p.word
	local main_vowel_index = -1
	local min_priority = 100

	for k = vowel_start, vowel_end do
		local char = word[k]
		-- Check for tone-marked vowels first
		if util.has_tone_marked(char) then
			return char, k
		elseif util.is_vietnamese_vowel(char) then
			local base_level2 = util.level(char, 2)
			local priority = BASE_VOWEL_PRIORITY[base_level2]
			if priority and priority < min_priority then
				min_priority = priority
				main_vowel_index = k
			end
		end
	end
	return word[main_vowel_index], main_vowel_index

	-- return find_main_vowel(p.word, p.word_len, vowel_start, vowel_end)
end

--- Find the first and last vowel positions in a character table
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @return integer first The index of the first vowel (1-based)
--- @return integer last The index of the last vowel (1-based)
--- @return boolean is_single True if the first and last vowels are the same (single vowel), false otherwise
local function find_vowel_sequence_bounds(chars, chars_size)
	local first, last = -1, -2

	-- Find the first and last vowel in the character table
	for i = 1, chars_size do
		if util.is_vietnamese_vowel(chars[i]) then
			first = i
			break
		end
	end

	if first == -1 then
		return first, last, false
	end

	for i = chars_size, 1, -1 do
		if util.is_vietnamese_vowel(chars[i]) then
			last = i
			break
		end
	end

	return first, last, first == last
end

--- Validate the vowel cluster in the character table
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return boolean True if the vowel cluster is valid, false otherwise
--- @note The vowel cluster is valid if:
---
---
local function validate_vowel_cluster(chars, chars_size, vowel_start, vowel_end)
	if
		caculate_vowel_length(vowel_start, vowel_end) > TRIPTHONGS_LENGTH
		or not util.all_vowels(chars, chars_size, false, vowel_start, vowel_end)
	then
		return false
	end
	return true
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
--- @return integer adjust The adjustment to the first vowel index (0 or 1)
--- @note The consonant cluster is valid if:
--- - It is empty (no consonant before the vowel)
--- - It is a valid consonant cluster defined in the ONSETS table
---
--- @note If the consonant cluster overlaps with the vowel (e.g. "qu", "qo"), it is considered
--- valid and the first vowel index is adjusted by 1.
local function validate_onset_cluster(chars, vowel_start)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return true, 0
	elseif cluster_len > MAX_CONSONANT_CLUSTERS_LENGTH then
		return false, 0
	elseif cluster_len == 1 and ONSETS[tbl_concat(chars, "", 1, 2)] then
		-- Special case: consonant overlaps with vowel
		-- e.g "qu", "qo"
		return true, 1
	end
	return ONSETS[tbl_concat(chars, "", 1, cluster_len)] ~= nil, 0
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param chars_size integer The total length of the character table
--- @param vowel_end integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
local function validate_coda_cluster(chars, chars_size, vowel_end)
	assert(vowel_end >= 1 and vowel_end <= chars_size, "Invalid last vowel index")
	local cluster_len = chars_size - vowel_end
	if cluster_len == 0 then
		return true
	elseif cluster_len > MAX_CODA_CLUSTERS_LENGTH then
		return false
	end
	return CODAS[tbl_concat(chars, "", vowel_end + 1, chars_size)] ~= nil
end

--- Ensure vowel indices are valid
--- @param first integer The index of the first vowel (1-based)
--- @param last integer The index of the last vowel (1-based)
--- @param len integer The total length of the character table
--- @return boolean True if indices are valid, false otherwise
local function are_valid_vowel_indices(first, last, len)
	if first < 1 or first > len then
		return false
	elseif last < first or last > len then
		return false
	end
	return true
end

--- Analyze structure of Vietnamese word (onset + vowel cluster)
--- @return boolean True if the word structure is analizing succeed
function WordEngine:analyzie_word_structure(force)
	local p = _privates[self]

	if not force and p.analyzed then
		return p.analyzed_success
	end
	p.analyzed = true
	local word, len = p.word, p.word_len

	if len == 1 then
		-- Single character word
		-- no need to analyze, it's a valid word
		p.analyzed_success = true
		return true
	end

	local first, last, _ = find_vowel_sequence_bounds(word, len)
	if not are_valid_vowel_indices(first, last, len) then
		p.analyzed_success = false
		return false
	end

	if not validate_vowel_cluster(word, len, first, last) then
		p.analyzed_success = false
		return false
	end

	local is_valid, adjust = validate_onset_cluster(word, first)
	if not is_valid then
		p.analyzed_success = false
		return false
	end

	first = first + adjust
	if not are_valid_vowel_indices(first, last, len) then
		-- The word with no vowel
		p.analyzed_success = false
		return false
	end
	p.vowel_start_adjust = adjust

	if not validate_coda_cluster(word, len, last) then
		p.analyzed_success = false
		return false
	end

	p.vowel_start = first
	p.vowel_end = last
	p.analyzed_success = true

	return true
end

--- Checks if the word is a valid Vietnamese word
--- @return boolean True if the word is a valid Vietnamese word, false otherwise
function WordEngine:is_valid_vietnamese_word()
	local p = _privates[self]
	if p.word_len == 1 then
		return util.is_vietnamese_char(p.word[1])
	end
	self:analyzie_word_structure()

	if p.vowel_start < 1 then
		return false
	end

	return true
end

--- Returns the column boundaries of the cursor position
--- @param cursor_col integer The current column position of the cursor
--- @return integer start The start column boundary of the cursor position
--- @return integer end The end column boundary of the cursor position (exclusive)
function WordEngine:column_boundaries(cursor_col)
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

--- Returns the byte offset boundaries of the cursor position
--- @param cursor_col_byteoffset integer The current byte offset of the cursor pos
--- @return integer start The start byte offset boundary of the cursor position
--- @return integer end The end byte offset boundary of the cursor position (exclusive)
function WordEngine:byteoffset_boundaries(cursor_col_byteoffset)
	local p = _privates[self]
	local raw = p.raw
	local cursor_char_index = p.cursor_char_index

	local start = cursor_col_byteoffset - #tbl_concat(raw, "", 1, cursor_char_index - 1)

	if cursor_char_index > p.raw_len then
		return start, cursor_col_byteoffset
	end
	local end_ = cursor_col_byteoffset + #tbl_concat(raw, "", cursor_char_index, p.raw_len)
	return start, end_
end

return WordEngine
