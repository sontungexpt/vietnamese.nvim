local CONSTANT = require("vietnamese.constant")
local ONSETS, CODAS, VOWEL_SEQS, VOWEL_PRIORITY =
	CONSTANT.ONSETS, CONSTANT.CODAS, CONSTANT.VOWEL_SEQS, CONSTANT.VOWEL_PRIORITY
local Diacritic = CONSTANT.Diacritic

local SINGLE_VOWEL_LENGTH = 1
local TRIPTHONGS_LENGTH = 3

local MAX_ONSET_LENGTH = 3

local util = require("vietnamese.util")
local mc_util = require("vietnamese.util.method-config")

local concat_tight_range = util.concat_tight_range
local level = util.level

--- @enum StructState
local StructState = {
	Unknown = 0,

	-- not a valid Vietnamese word
	-- but ready to apply shape diacritic
	ShapeReady = 1,

	Invalid = 2,
	Valid = 3,
}
local StructValid = StructState.Valid
local StructInvalid = StructState.Invalid
local StructUnknown = StructState.Unknown
local StructShapeReady = StructState.ShapeReady

--- @enum VowelSeqStatus
local VowelSeqStatus = {
	Invalid = 0,
	Valid = 1,
	Ambiguous = 2,
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
--- @field wlen integer Length of `word`
--- @field raw string[] Original list of characters before modification
--- @field rawlen integer Length of `raw`
--- @field inserted_idx integer Index of the recently inserted character (if any)
--- @field inserted_char string The character at the cursor position
--- @field cursor_idx integer Current cursor position (1-based). If the cursor is at the end of the word, it is `raw_len + 1`.
--- @field struct_state StructState State of the word structure analysis
--- @field vowel_start integer (after analysis) Index of the start of the vowel cluster (1-based)
--- @field vowel_end integer (after analysis) Index of the end of the vowel cluster (1-based)
--- @field vowel_shift integer (after analysis) Offset if the onset overlaps with the vowel cluster
--- @field vnorms table|nil (after analysis) --- Normalized vowel sequence layer, mapping indices to normalized vowels example: for word = { "d", "a", "o" } -- normalized_vowel_layer = { [1] = nil, [2] = "a", [3] = "o" }
--- @field tone_mark Diacritic? (after analysis) The tone mark of the main vowel if it has one
--- @field tone_mark_idx integer (after analysis) The index of the tone mark in the word (1-based)
local _privates = setmetatable({}, { __mode = "k" }) --- @type table<WordEngine, PrivateWordEngineFields>

local function clone_and_insert(chars, chars_size, inserted_char, inserted_idx)
	local new_chars = {}
	local new_size = chars_size + 1

	for i = 1, inserted_idx - 1 do
		new_chars[i] = chars[i]
	end
	new_chars[inserted_idx] = inserted_char
	for i = inserted_idx + 1, new_size do
		new_chars[i] = chars[i - 1]
	end

	return new_chars, new_size
end

--- Cr-eates a new CursorWord instance
--- @param cword table a table of characters representing the word
--- @param cwlen integer the length of the word
--- @param inserted_char string the character at the cursor position
--- @param inserted_idx integer the index of the cursor character (1-based)
--- @return WordEngine  instance
function WordEngine:new(cword, cwlen, inserted_char, inserted_idx)
	local obj = setmetatable({}, self)

	local raw, raw_len = clone_and_insert(cword, cwlen, inserted_char, inserted_idx)

	_privates[obj] = {
		word = cword,
		wlen = cwlen,
		raw = raw,
		rawlen = raw_len,

		inserted_idx = inserted_idx,
		inserted_char = inserted_char, -- the character at the cursor position

		-- cursor_char_index == raw_len + 1
		-- if the cursor is at the end of the word
		cursor_idx = inserted_idx + 1,

		struct_state = StructUnknown, -- state of the word structure analysis

		-- this fields only have the real value after analysis
		tone_mark = nil, -- the tone mark of the main vowel if it has one
		tone_mark_idx = -1, -- the index of the tone mark in the word (1-based)
		vowel_start = -1,
		vowel_end = -2, -- -2 to make sure that it is not valid when loop from start to end
		vowel_shift = 0, -- adjust the vowel start index if the onset overlaps with the vowel
		vnorms = nil,
	}

	return obj
end

function WordEngine:iter_chars(cb, use_raw)
	local p = _privates[self]
	local chars = use_raw and p.raw or p.word
	local length = use_raw and p.rawlen or p.wlen

	for i = 1, length, 1 do
		local char = chars[i]
		cb(i, char)
	end
end

function WordEngine:is_potential_vnword()
	local p = _privates[self]
	local word, word_len = p.word, p.wlen

	if
		word_len > 1
		and not util.is_potiental_vowel_seq(word, word_len, SINGLE_VOWEL_LENGTH, TRIPTHONGS_LENGTH)
		and not util.exceeded_repetition_time(word, word_len)
		and not util.unique_tone_marked(word, word_len)
	then
		return false -- No vowel in the word, diacritic cannot be applied
	end
	return true
end

--- Checks if the word is potential to apply diacritic
--- @param method_config table the method configuration to use for checking
--- @return boolean true if the diacritic can be applied, false otherwise
function WordEngine:is_potential_diacritic_key(method_config)
	local p = _privates[self]
	local raw, inserted_char = p.raw, p.inserted_char

	for i = p.inserted_idx - 1, 1, -1 do
		if mc_util.get_diacritic(inserted_char, raw[i], method_config) then
			return true
		end
	end

	return false
end

--- Returns the cursor position in the character list
--- @return string the character at the cursor position
function WordEngine:inserted_char()
	local p = _privates[self]
	return p.inserted_char or ""
end

--- Copies the raw character list to the word character list
function WordEngine:restore_raw(ovverides)
	local p = _privates[self]
	local word, word_len, raw, raw_len = p.word, p.wlen, p.raw, p.rawlen
	local stop = word_len > raw_len and word_len or raw_len

	if not ovverides or next(ovverides) == nil then
		for i = 1, stop do
			word[i] = raw[i]
		end
	else
		for i = 1, stop do
			word[i] = ovverides[i] or raw[i]
		end
	end

	-- update new len
	p.wlen = raw_len
end

--- Returns the cursor position in the character list (1-based)
--- @return integer the cursor position (1-based)
function WordEngine:length(use_raw)
	return use_raw and _privates[self].rawlen or _privates[self].wlen
end

function WordEngine:get(use_raw)
	local p = _privates[self]
	return use_raw and p.raw or p.word
end

function WordEngine:feedkey()
	local p = _privates[self]
	self:restore_raw({})

	p.struct_state = StructUnknown
end

----- Updates the position of the tone mark in the word
--- @param method_config table|nil The method configuration to use for updating the tone mark position
--- @return boolean changed true if the tone mark position was updated, false otherwise
function WordEngine:update_tone_pos(method_config)
	if self:analyze_structure() == StructInvalid then
		return false
	end
	local p = _privates[self]
	local tone, tidx = p.tone_mark, p.tone_mark_idx

	-- no tone
	if tidx < 1 then
		return false
	end

	local vowel, new_idx = self:find_tone_pos("", true)
	if not vowel or new_idx == tidx then
		return false
	end

	local word = p.word
	word[tidx] = level(word[tidx], 2)

	--- @cast tone Diacritic
	word[new_idx] = util.merge_tone_lv2(vowel, tone)
	p.tone_mark = tone
	p.tone_mark_idx = new_idx
	return true
end

function WordEngine:tostring(use_raw)
	return concat_tight_range(use_raw and _privates[self].raw or _privates[self].word)
end

--- Function to find main vowel
--- @param style string the style of the word (e.g. "normal", "formal")
--- @param force_recheck boolean|nil whether to force recompute the position even it only had tone marked already
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
function WordEngine:find_tone_pos(style, force_recheck)
	self:analyze_structure()

	local p = _privates[self]

	if p.vowel_start < 0 then
		return nil, -1
	end

	local word, vs, ve = p.word, p.vowel_start, p.vowel_end
	local tone_mark_idx = p.tone_mark_idx

	-- only one vowel in the word
	if vs == ve then
		return word[vs], vs
	elseif not force_recheck and tone_mark_idx > 0 then
		return word[tone_mark_idx], tone_mark_idx
	end

	local vnorms = p.vnorms
	if not vnorms then
		return nil, -1
	end

	-- check if precomputed diphthongs or triphthongs
	local v_seq = concat_tight_range(vnorms, vs, ve)
	local precomputed = VOWEL_SEQS[v_seq]
	if precomputed then
		local mvi = vs + precomputed[1]
		return word[mvi], mvi
	end

	-- find the mark position base on the priority of the vowel
	local mvi = -1
	local min_priority = 100
	for k = vs, ve do
		local priority = VOWEL_PRIORITY[vnorms[k]]
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
--- @return VowelSeqStatus The status of the vowel sequence
--- @return table|nil The normalized vowel sequence if it exists
--- @return Diacritic|nil The tone mark if it exists
--- @return integer The index of the tone mark in the vowel sequence (1-based), or -1 if no tone mark exists
local function detect_vowel_seq_and_tone(chars, chars_size, vowel_start, vowel_end)
	local tone_mark = nil
	local tone_mark_idx = -1
	local status = VowelSeqStatus.Valid

	if vowel_start == vowel_end then
		local lv2
		lv2, tone_mark = util.strip_tone(chars[vowel_start])
		if tone_mark then
			tone_mark_idx = vowel_start
		end
		return status, { [vowel_start] = lv2 }, tone_mark, tone_mark_idx
	end

	-- convert the vowel to level 2 and store in a new layer with the same index in word
	-- example:
	-- word = { "d" "a", "o"  }
	-- -> normalized_vowel_layer = {
	--   [2] = "a",
	--   [3] = "o",
	-- }
	local vnorms = {}
	-- Check if the word has a tone-marked vowel
	for i = vowel_start, vowel_end do
		local tone
		vnorms[i], tone = util.strip_tone(chars[i])
		if tone then
			tone_mark = tone
			tone_mark_idx = i
		end
	end
	local vowel_seq = concat_tight_range(vnorms, vowel_start, vowel_end)
	local seq_map = VOWEL_SEQS[vowel_seq]
	if seq_map == false then
		status = VowelSeqStatus.Ambiguous
	elseif seq_map == nil then
		status = VowelSeqStatus.Invalid
	end
	return status, vnorms, tone_mark, tone_mark_idx
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
local function detect_onset(chars, vowel_start, vowel_end)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return true, cluster_len
	elseif cluster_len > MAX_ONSET_LENGTH then
		return false, cluster_len
	elseif cluster_len == 1 then
		local char1 = chars[1]
		if vowel_end > vowel_start and ONSETS[(char1 .. chars[2]):lower()] then
			-- Special case: consonant overlaps with vowel
			-- e.g "qu", "gi"
			return true, vowel_start
		end
		return ONSETS[char1:lower()] ~= nil, 0
	elseif cluster_len == 2 then
		return ONSETS[(chars[1] .. chars[2]):lower()] ~= nil, 0
	end
	return ONSETS[(chars[1] .. chars[2] .. chars[3]):lower()] ~= nil, 0
end

--- Fix the onset and vowel conflicts
--- @param onset_end integer The index of the end of the onset cluster (1-based)
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return integer new_vowel_start The adjusted index of the first vowel (1-based)
--- @return integer new_vowel_end The index of the last vowel (1-based)
local function fix_onset_vowel_collision(onset_end, vowel_start, vowel_end)
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
local function validate_coda(chars, chars_size, vowel_end)
	-- assert(vowel_end >= 1 and vowel_end <= chars_size, "Invalid last vowel index")
	local cluster_len = chars_size - vowel_end
	if cluster_len == 0 then
		return true
	elseif cluster_len == 1 then
		return CODAS[(chars[vowel_end + 1]):lower()] ~= nil
	elseif cluster_len == 2 then
		return CODAS[(chars[vowel_end + 1] .. chars[vowel_end + 2]):lower()] ~= nil
	end
	return false
end

--- Analyze structure of Vietnamese word (onset + vowel cluster)
--- @param force boolean|nil If true, forces re-analysis of the word analyzie_word_structure
--- @return StructState The analysis state of the word
function WordEngine:analyze_structure(force)
	local p = _privates[self]

	if not force and p.struct_state ~= StructUnknown then
		return p.struct_state
	end

	local word, wlen = p.word, p.wlen

	local vs, ve, _ = util.find_vowel_seq_bounds(word, wlen)

	if vs < 1 then
		if wlen == 1 and util.is_d(word[1]) then
			-- Special d
			p.struct_state = StructShapeReady
		else
			p.struct_state = StructInvalid
		end

		return p.struct_state
	end

	local vowel_seq_status
	vowel_seq_status, p.vnorms, p.tone_mark, p.tone_mark_idx = detect_vowel_seq_and_tone(word, wlen, vs, ve)

	if vowel_seq_status == VowelSeqStatus.Invalid then
		p.struct_state = StructInvalid
		return p.struct_state
	elseif vowel_seq_status == VowelSeqStatus.Ambiguous then
		p.struct_state = StructShapeReady
	end

	local valid, onset_end = detect_onset(word, vs, ve)
	if not valid then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	vs, ve = fix_onset_vowel_collision(onset_end, vs, ve)
	if vs < 1 then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	if not validate_coda(word, wlen, ve) then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	p.vowel_shift = vs - onset_end
	p.vowel_start = vs
	p.vowel_end = ve
	p.struct_state = StructValid
	return p.struct_state
end

--- Removes the tone mark from the main vowel in the word
--- @param self WordEngine The WordEngine instance
--- @param method_config table|nil The method configuration to use for tone removal
--- @return boolean True if the tone mark was removed, false otherwise
---@diagnostic disable-next-line: unused-local
local function remove_tone(self, method_config)
	local p = _privates[self]
	local word, tone, tidx = p.word, p.tone_mark, p.tone_mark_idx
	if not tone then
		self:restore_raw({})
		return false
	end
	word[tidx] = level(word[tidx], 2) -- remove the tone mark
	p.tone_mark = nil
	p.tone_mark_idx = -1
	return true
end

--- Processes tone marks in the word
local function processes_tone(self, method_config)
	local p = _privates[self]

	local inserted_char, inserted_idx = p.inserted_char, p.inserted_idx
	if not inserted_char then
		return false
	end

	local main_vowel, tidx = self:find_tone_pos("")

	if not main_vowel then
		return false
	elseif inserted_idx <= tidx then
		return false
	end

	local lv2_vowel, removed_tone = util.strip_tone(main_vowel)
	local tone_diacritic = mc_util.get_tone_diacritic(inserted_char, lv2_vowel, method_config)
	if not tone_diacritic then
		return false
	elseif removed_tone == tone_diacritic then
		-- restore the tone mark
		self:restore_raw({
			[tidx] = lv2_vowel,
		})
		p.tone_mark = nil
		p.tone_mark_idx = -1
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		p.word[tidx] = util.merge_tone_lv2(lv2_vowel, tone_diacritic)
		p.tone_mark = tone_diacritic
		p.tone_mark_idx = tidx
	end
	return true
end

local function collect_effects(chars, vs, ve, key, method_config)
	local effects = {}

	local char1 = chars[1]
	local shape_diacritic_d = util.is_d(char1) and mc_util.get_shape_diacritic(key, char1, method_config)
	if shape_diacritic_d then
		effects[1] = {
			[1] = 1, -- index of the character in the word
			[2] = char1, -- character itself
			[3] = shape_diacritic_d, -- diacritic to apply
			[4] = util.has_shape(char1), -- if the character already has a shape diacritic
		}
		return effects, 1
	end

	local ecount = 0
	-- to make sure that in the "qu" or "gi" case "u" and "i" is consider ass a consonant
	for i = vs, ve do
		local c = chars[i]
		local shape_diacritic = mc_util.get_shape_diacritic(key, c, method_config)
		if shape_diacritic then
			ecount = ecount + 1
			effects[ecount] = {
				[1] = i,
				[2] = c,
				[3] = shape_diacritic,
				[4] = util.has_shape(c),
			}
		end
	end
	return effects, ecount
end

local function processes_shape(self, method_config)
	local p = _privates[self]

	local word, word_len, inserted_idx, inserted_char = p.word, p.wlen, p.inserted_idx, p.inserted_char
	local vs, ve = p.vowel_start, p.vowel_end

	local effects, ecount = collect_effects(word, vs, ve, inserted_char, method_config)

	if ecount == 0 then
		return false -- no shape diacritic found
	elseif ecount > 1 then
		local e1, e2 = effects[1], effects[2]
		local e1_idx, e2_idx = e1[1], e2[1]
		local e1_c, e2_c = e1[2], e2[2]
		local e1_shape, e2_shape = e1[3], e2[3]

		local is_dual_horn_uo = e2_idx < word_len -- must have the coda
			and e2_idx - e1_idx == 1 -- must be adjacent
			and e1_shape == Diacritic.Horn
			and e2_shape == Diacritic.Horn
			and level(e1_c, 1) == "u"
			and level(e2_c, 1) == "o"

		if is_dual_horn_uo then
			if e2_idx >= inserted_idx then
				return false
			elseif e1[4] and e2[4] then
				-- restore the horn
				self:restore_raw({
					[e1_idx] = util.strip_shape(e1_c),
					[e2_idx] = util.strip_shape(e2_c),
				})
				return true
			end

			word[e1_idx] = util.merge_diacritic(e1_c, e1_shape)
			word[e2_idx] = util.merge_diacritic(e2_c, e2_shape)

			local status, new_vnorms = detect_vowel_seq_and_tone(word, word_len, vs, ve)

			if status == VowelSeqStatus.Valid then
				p.vnorms = new_vnorms
				p.struct_state = StructValid
				self:update_tone_pos(method_config)
				return true
			end
			self:restore_raw({})
			p.struct_state = StructUnknown
			return false
		end

		-- sort by has shape
		table.sort(effects, function(a, b)
			if a[4] and not b[4] then
				return true
			elseif not a[4] and b[4] then
				return false
			end
			return a[1] < b[1]
		end)
	end

	for i = 1, ecount do
		local e = effects[i]
		local e_idx, e_c = e[1], e[2]
		if e_idx < inserted_idx then
			if e[4] then
				-- restore shape diacritic
				self:restore_raw({
					[e_idx] = util.strip_shape(e_c),
				})

				return true
			end
			-- not in vowel sequence means a consonant
			-- d
			if e_idx < vs or e_idx > ve then
				word[e_idx] = util.merge_diacritic(e_c, e[3])
				return true
			end

			-- in vowel sequence
			word[e_idx] = util.merge_diacritic(e_c, e[3])
			local status, new_vnorms = detect_vowel_seq_and_tone(word, word_len, vs, ve)
			if status == VowelSeqStatus.Valid then
				p.vnorms = new_vnorms
				p.struct_state = StructValid
				self:update_tone_pos(method_config)
				return true
			elseif i == ecount then
				-- can not apply the shape diacritic
				self:restore_raw({})
				p.struct_state = StructUnknown
				return false
			end
			-- restore the before state
			word[e_idx] = e_c
		end
	end

	return false
end

--- Processes diacritics in the word
--- @param method_config table The method configuration to use for processing diacritics
--- @return boolean changed True if the diacritic was processed, false otherwise
function WordEngine:processes_diacritic(method_config)
	if self:analyze_structure() == StructInvalid then
		return false
	end
	local p = _privates[self]
	local inserted_char = p.inserted_char

	---@cast inserted_char string
	if mc_util.is_tone_removal_key(inserted_char, method_config) then
		return remove_tone(self, method_config)
	elseif mc_util.is_shape_key(inserted_char, method_config) then
		return processes_shape(self, method_config)
	elseif mc_util.is_tone_key(inserted_char, method_config) then
		return processes_tone(self, method_config)
	end
	return false
end
-- --- Checks if the word is a valid Vietnamese word
-- --- @return boolean True if the word is a valid Vietnamese word, false otherwise
-- function WordEngine:is_valid_vietnamese_word()
-- 	local p = _privates[self]
-- 	if p.word_len == 1 then
-- 		return util.is_vietnamese_vowel(p.word[1])
-- 	end
-- 	self:analyze_structure()

-- 	if p.vowel_start < 1 then
-- 		return false
-- 	end

-- 	return true
-- end

--- Returns the cell boundaries of the cursor position
--- @param cursor_cell_idx integer The current column position of the cursor
--- @return integer start The start column boundary of the cursor position
--- @return integer stop The end column boundary of the cursor position (exclusive)
function WordEngine:cell_boundaries(cursor_cell_idx)
	local strdisplaywidth = vim.fn.strdisplaywidth
	local p = _privates[self]
	local raw, csidx = p.raw, p.cursor_idx

	local start = cursor_cell_idx - strdisplaywidth(concat_tight_range(raw, 1, csidx - 1))
	local stop = csidx > p.rawlen and cursor_cell_idx
		or cursor_cell_idx + strdisplaywidth(concat_tight_range(raw, csidx, p.rawlen))

	return start, stop
end

--- Returns the byte offset boundaries of the cursor position
--- @param cursor_col_byteoffset integer The current byte offset of the cursor pos
--- @return integer start The start byte offset boundary of the cursor position
--- @return integer stop The end byte offset boundary of the cursor position (exclusive)
function WordEngine:col_bounds(cursor_col_byteoffset)
	local p = _privates[self]
	local raw, raw_len, csidx = p.raw, p.rawlen, p.cursor_idx

	local start = cursor_col_byteoffset - #concat_tight_range(raw, 1, csidx - 1)
	local stop = csidx > raw_len and cursor_col_byteoffset
		or cursor_col_byteoffset + #concat_tight_range(raw, csidx, raw_len)

	return start, stop
end

--- Calculates the current cursor column based on the inserted character
--- @param old_col integer The previous column position of the cursor_col_byteoffset
--- @return integer The updated column position of the cursor_col_byteoffset
function WordEngine:get_curr_cursor_col(old_col)
	local p = _privates[self]
	local raw_len, word_len = p.rawlen, p.wlen
	local csidx = p.cursor_idx
	local start = old_col - #concat_tight_range(p.raw, 1, csidx - 1)

	if word_len == raw_len then
		return start + #concat_tight_range(p.word, 1, csidx - 1)
	elseif word_len < raw_len then
		return start + #concat_tight_range(p.word, 1, p.inserted_idx - 1)
	end
	return old_col
end

return WordEngine
