local tbl_concat = table.concat

local CONSTANT = require("vietnamese.constant")

local ONSETS = CONSTANT.ONSETS
local CODAS = CONSTANT.CODAS
local VOWEL_SEQS = CONSTANT.VOWEL_SEQS
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VNCHAR_COMPONENT
local VOWEL_PRIORITY = CONSTANT.VOWEL_PRIORITY

local SINGLE_VOWEL_LENGTH = 1
local DIPTHONGS_LENGTH = 2
local TRIPTHONGS_LENGTH = 3

local MAX_CODA_CLUSTERS_LENGTH = 2
local MAX_CONSONANT_CLUSTERS_LENGTH = 3

local util = require("vietnamese.util")
local method_config_util = require("vietnamese.util.method-config")

--- @enum ANALYSIS_STATE
local ANALYSIS_STATE = {
	NOT_ANALYZED = 0,
	-- The word is analyzed and can be processed with diacritics but may be not a valid vietnamese word
	DIACRITIC_PROCESSABLE = 1,
	INVALID_VN_WORD = 2,
	VALID_VN_WORD = 3,
}

--- @enum VOWEL_VALIDATE_STATE
local VOWEL_VALIDATE_STATE = {
	INVALID = 0,
	VALID = 1,
	TRANSACTIONAL = 2,
}

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
--- @field analysis_status ANALYSIS_STATE State of the word structure analysis
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

		analysis_status = ANALYSIS_STATE.NOT_ANALYZED, -- state of the word structure analysis

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
		and not util.is_potiental_vowel_seq(word, word_len, SINGLE_VOWEL_LENGTH, TRIPTHONGS_LENGTH)
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
	local main_vowel, main_vowel_index = self:detect_mark_position()
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

	local main_vowel, main_vowel_index = self:detect_mark_position()
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
	if self:analyzie_word_structure() == ANALYSIS_STATE.INVALID_VN_WORD then
		return false
	end
	local inserted_char = self:inserted_char()
	if method_config_util.is_tone_removal_key(inserted_char, method_config) then
		return self:remove_tone(method_config)
	end

	if method_config_util.is_tone_key(inserted_char, method_config) then
		return self:processes_tone(method_config)
	end
	return false
end

function WordEngine:processes_shape(method_config)
	local p = _privates[self]
	local word, word_len = p.word, p.word_len
	local c_idex, shape_diacritic = nil, nil
	for i = 1, word_len do
		shape_diacritic = method_config_util.get_shape_diacritic(self:inserted_char(), word[i], method_config)
		c_idex = i
	end

	--
end

-- function WordEngine:decompose_word(level)
-- 	local p = _privates[self]
-- 	local word, word_len = p.word, p.word_len
-- 	local result = {}
-- 	for i = 1, word_len do
-- 		local ch = word[i]
-- 		local dict = UTF8_VN_CHAR_DICT[ch]
-- 		if dict then
-- 			result[#result + 1] = dict[1]

-- 			if level == 1 and dict.shape then
-- 				result[#result + 1] = dict.shape
-- 			end

-- 			if dict.tone then
-- 				result[#result + 1] = dict.tone
-- 			end
-- 		else
-- 			result[#result + 1] = ch
-- 		end
-- 	end
-- 	return result
-- end

function WordEngine:tostring(use_raw)
	return tbl_concat(use_raw and _privates[self].raw or _privates[self].word)
end

--- Function to find main vowel
--- @param force boolean|nil whether to force recompute the position even it only had tone marked already
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
function WordEngine:detect_mark_position(force)
	self:analyzie_word_structure()

	local p = _privates[self]
	if p.vowel_start < 0 then
		return nil, -1
	end

	local word, vs, ve = p.word, p.vowel_start, p.vowel_end
	local vlen = util.caculate_distance(vs, ve)

	-- only one vowel in the word
	if vlen == SINGLE_VOWEL_LENGTH then
		return word[vs], vs
	end

	-- convert the vowel to level 2 and store in a new layer with the same index in word
	-- example:
	-- word = { "d" "a", "o"  }
	-- -> normalized_vowel_layer = {
	--   [2] = "a",
	--   [3] = "o",
	-- }
	local normalized_vowel_layer = {}
	-- Check if the word has a tone-marked vowel
	for i = vs, ve do
		local char = word[i]
		if util.has_tone_marked(char) then
			-- find a  tone marked and no need to recompute
			if not force then
				return char, i
			end
			normalized_vowel_layer[i] = util.level(char, 2)
		end
		normalized_vowel_layer[i] = char
	end

	-- check if precomputed diphthongs or triphthongs
	local v_seq = tbl_concat(normalized_vowel_layer, "", vs, ve)
	local precomputed = VOWEL_SEQS[v_seq]
	if precomputed then
		local mvi = vs + precomputed[1]
		return word[mvi], mvi
	end

	-- find the mark position base on the priority of the vowel
	local mvi = -1
	local min_priority = 100
	for k = vs, ve do
		local priority = VOWEL_PRIORITY[normalized_vowel_layer[k]]
		if priority < min_priority then
			min_priority = priority
			mvi = k
		end
	end

	return word[mvi], mvi
end

--- Validate the vowel cluster in the character table
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
---
local function validate_vowel_cluster(chars, chars_size, vowel_start, vowel_end)
	if vowel_start == vowel_end then
		return VOWEL_VALIDATE_STATE.VALID
	end

	-- convert the vowel to level 2 and store in a new layer with the same index in word
	-- example:
	-- word = { "d" "a", "o"  }
	-- -> normalized_vowel_layer = {
	--   [2] = "a",
	--   [3] = "o",
	-- }
	local normalized_vowel_layer = {}
	-- Check if the word has a tone-marked vowel
	for i = vowel_start, vowel_end do
		normalized_vowel_layer[i] = util.level(chars[i], 2)
	end
	local normalized_vowel_seq = tbl_concat(normalized_vowel_layer, "", vowel_start, vowel_end)
	local seq_map = VOWEL_SEQS[normalized_vowel_seq]
	if seq_map == false then
		return VOWEL_VALIDATE_STATE.TRANSACTIONAL
	elseif seq_map == nil then
		return VOWEL_VALIDATE_STATE.INVALID
	end
	return VOWEL_VALIDATE_STATE.VALID
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @return boolean is_valid True if the consonant cluster is valid, false otherwise
--- @return integer onset_end The index of the end of the onset cluster (1-based)
--- @note The consonant cluster is valid if:
--- - It is empty (no consonant before the vowel)
--- - It is a valid consonant cluster defined in the ONSETS table
---
--- @note If the consonant cluster overlaps with the vowel (e.g. "qu", "qo"), it is considered
--- valid and the first vowel index is adjusted by 1.
local function detect_onset_cluster(chars, vowel_start, vowel_end)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return true, cluster_len
	elseif cluster_len > MAX_CONSONANT_CLUSTERS_LENGTH then
		return false, cluster_len
	elseif cluster_len == 1 and vowel_end > vowel_start and ONSETS[tbl_concat(chars, "", 1, 2)] then
		-- Special case: consonant overlaps with vowel
		-- e.g "qu", "gi"
		return true, vowel_start
	end
	return ONSETS[tbl_concat(chars, "", 1, cluster_len)] ~= nil, 0
end

--- Fix the onset and vowel conflicts
--- @param onset_end integer The index of the end of the onset cluster (1-based)
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return integer The adjusted index of the first vowel (1-based)
--- @return integer The index of the last vowel (1-based)
local function fix_onset_vowel_conflict(onset_end, vowel_start, vowel_end)
	if onset_end < vowel_start then
		return vowel_start, vowel_end
	elseif onset_end + 1 > vowel_end then
		return -1, -2 -- No vowel found
	end
	return onset_end + 1, vowel_end
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
--- @param force boolean|nil If true, forces re-analysis of the word analyzie_word_structure
--- @return ANALYSIS_STATE The analysis state of the word
function WordEngine:analyzie_word_structure(force)
	local p = _privates[self]

	if not force and p.analysis_status ~= ANALYSIS_STATE.NOT_ANALYZED then
		return p.analysis_status
	end

	-- default is valid
	p.analysis_status = ANALYSIS_STATE.VALID_VN_WORD

	local word, len = p.word, p.word_len
	if len == 1 then
		-- Single character word
		-- no need to analyze, it's a valid word
		p.analysis_status = ANALYSIS_STATE.DIACRITIC_PROCESSABLE
		return p.analysis_status
	end

	local vs, ve, _ = util.find_vowel_seq_bounds(word, len)
	if not are_valid_vowel_indices(vs, ve, len) then
		p.analysis_status = ANALYSIS_STATE.INVALID_VN_WORD
		return p.analysis_status
	end

	local vowel_seq_status = validate_vowel_cluster(word, len, vs, ve)
	if vowel_seq_status == VOWEL_VALIDATE_STATE.INVALID then
		p.analysis_status = ANALYSIS_STATE.INVALID_VN_WORD
		return p.analysis_status
	elseif vowel_seq_status == VOWEL_VALIDATE_STATE.TRANSACTIONAL then
		p.analysis_status = ANALYSIS_STATE.DIACRITIC_PROCESSABLE
	end

	local valid, onset_end = detect_onset_cluster(word, vs, ve)
	if not valid then
		p.analysis_status = ANALYSIS_STATE.INVALID_VN_WORD
		return p.analysis_status
	end

	vs, ve = fix_onset_vowel_conflict(onset_end, vs, ve)
	if vs < 1 then
		p.analysis_status = ANALYSIS_STATE.INVALID_VN_WORD
		return p.analysis_status
	end
	p.vowel_start_adjust = onset_end

	if not validate_coda_cluster(word, len, ve) then
		p.analysis_status = ANALYSIS_STATE.INVALID_VN_WORD
		return ANALYSIS_STATE.INVALID_VN_WORD
	end

	p.vowel_start = vs
	p.vowel_end = ve

	return p.analysis_status
end

--- Checks if the word is a valid Vietnamese word
--- @return boolean True if the word is a valid Vietnamese word, false otherwise
function WordEngine:is_valid_vietnamese_word()
	local p = _privates[self]
	if p.word_len == 1 then
		return util.is_vietnamese_vowel(p.word[1])
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
--- @return integer stop The end column boundary of the cursor position (exclusive)
function WordEngine:column_boundaries(cursor_col)
	local p = _privates[self]
	local raw, csidx = p.raw, p.cursor_char_index

	local start = cursor_col - vim.fn.strdisplaywidth(tbl_concat(raw, "", 1, csidx - 1))
	local stop = csidx > p.raw_len and cursor_col
		or cursor_col + vim.fn.strdisplaywidth(tbl_concat(raw, "", csidx, p.raw_len))

	return start, stop
end

--- Returns the byte offset boundaries of the cursor position
--- @param cursor_col_byteoffset integer The current byte offset of the cursor pos
--- @return integer start The start byte offset boundary of the cursor position
--- @return integer stop The end byte offset boundary of the cursor position (exclusive)
function WordEngine:byteoffset_boundaries(cursor_col_byteoffset)
	local p = _privates[self]
	local raw, csidx = p.raw, p.cursor_char_index

	local start = cursor_col_byteoffset - #tbl_concat(raw, "", 1, csidx - 1)
	local stop = csidx > p.raw_len and cursor_col_byteoffset
		or cursor_col_byteoffset + #tbl_concat(raw, "", csidx, p.raw_len)

	return start, stop
end

return WordEngine
