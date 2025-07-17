local CONSTANT = require("vietnamese.constant")
local ONSETS, CODAS, VOWEL_SEQS, VOWEL_PRIORITY =
	CONSTANT.ONSETS, CONSTANT.CODAS, CONSTANT.VOWEL_SEQS, CONSTANT.VOWEL_PRIORITY
local Diacritic = CONSTANT.Diacritic

local util = require("vietnamese.util")
local mc_util = require("vietnamese.util.method-config")

local lower_char, concat_tight_range, level, byte_len =
	util.lower_char, util.concat_tight_range, util.level, util.byte_len
local tbl_insert = table.insert

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
local WordEngine = {
	StructState = StructState,
}

-- allow to access public methods and properties
WordEngine.__index = WordEngine

--- Stores internal fields for each WordEngine instance
--- @class PrivateWordEngineFields
--- @field word string[] List of characters for processing
--- @field wlen integer Length of `word`
--- @field raw string[] Original list of characters before modification
--- @field rawlen integer Length of `raw`
--- @field inserted_idx integer Index of the recently inserted character (if any)
--- @field inserted_key string The character at the cursor position
--- @field cursor_idx integer Current cursor position (1-based). If the cursor is at the end of the word, it is `raw_len + 1`.
--- @field struct_state StructState State of the word structure analysis
--- @field vowel_start integer (after analysis) Index of the start of the vowel cluster (1-based)
--- @field vowel_end integer (after analysis) Index of the end of the vowel cluster (1-based)
--- @field vowel_shift integer (after analysis) Offset if the onset overlaps with the vowel cluster
--- @field vnorms table|nil (after analysis) --- Normalized vowel sequence layer, mapping indices to normalized vowels example: for word = { "d", "a", "o" } -- normalized_vowel_layer = { [1] = nil, [2] = "a", [3] = "o" }. All chars is lowercase
--- @field tone_mark Diacritic|nil (after analysis) The tone mark of the main vowel if it has one
--- @field tone_mark_idx integer (after analysis) The index of the tone mark in the word (1-based)
local _privates = setmetatable({}, { __mode = "k" }) --- @type table<WordEngine, PrivateWordEngineFields>

local function clone_and_insert(chars, chars_size, inserted_key, inserted_idx)
	local new_chars = {}
	local new_size = chars_size + 1

	for i = 1, inserted_idx - 1 do
		new_chars[i] = chars[i]
	end
	new_chars[inserted_idx] = inserted_key
	for i = inserted_idx + 1, new_size do
		new_chars[i] = chars[i - 1]
	end

	return new_chars, new_size
end

--- Cr-eates a new CursorWord instance
--- @param cword table a table of characters representing the word
--- @param cwlen integer the length of the word
--- @param inserted_key string the character at the cursor position
--- @param inserted_idx integer the index of the cursor character (1-based)
--- @return WordEngine  instance
function WordEngine:new(cword, cwlen, inserted_key, inserted_idx)
	local obj = setmetatable({}, self)

	local raw, raw_len = clone_and_insert(cword, cwlen, inserted_key, inserted_idx)

	_privates[obj] = {
		word = cword,
		wlen = cwlen,
		raw = raw,
		rawlen = raw_len,

		inserted_idx = inserted_idx,
		inserted_key = inserted_key, -- the character at the cursor position

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
		vnorms = nil, -- normalized vowel sequence layer, mapping indices to normalized vowels
	}

	return obj
end

--- Iterates over the characters in the word
--- @param use_raw boolean if true, iterates over the raw character list, otherwise iterates over the word character List
--- @return fun(): integer|nil, string|nil a function that returns the index and character at that Index
function WordEngine:iter_chars(use_raw)
	local p = _privates[self]
	local length = use_raw and p.rawlen or p.wlen
	if length < 1 then
		return function()
			return nil, nil -- no characters to iteratec
		end
	end

	local chars = use_raw and p.raw or p.word
	local i = 0
	return function()
		i = i + 1
		if i > length then
			return nil -- no characters to iterate
		end
		return i, chars[i - 1] -- return the next character and its index
	end
end

function WordEngine:is_potential_vnword()
	local p = _privates[self]
	local word, word_len = p.word, p.wlen

	if
		word_len > 1
		and not util.is_potential_vowel_seq(word, word_len)
		and not util.exceeded_repetition_time(word, word_len)
		and not util.unique_tone_marked(word, word_len)
	then
		return false -- No vowel in the word, diacritic cannot be applied
	end
	return true
end

--- Checks if the word is potential to apply diacritic
--- @param method_config table the method configuration to use for checking
--- @return boolean valid if the diacritic can be applied, false otherwise
function WordEngine:is_potential_diacritic_key(method_config)
	local p = _privates[self]
	local raw, inserted_key = p.raw, p.inserted_key

	for i = p.inserted_idx - 1, 1, -1 do
		if mc_util.get_diacritic(inserted_key, raw[i], method_config) then
			return true
		end
	end

	return false
end

--- Returns the cursor position in the character list
--- @return string the character at the cursor position
function WordEngine:inserted_key()
	return _privates[self].inserted_key
end

--- Processes the new vowel character at the cursor position
--- @param method_config table the method configuration to use for processing
--- @param tone_stragegy OrthographyStragegy the strategy to use for finding the main vowel position, defaults to "modern"
function WordEngine:processes_new_vowel(method_config, tone_stragegy)
	local p = _privates[self]
	local raw, inidx = p.raw, p.inserted_idx

	if
		(inidx > 1 and util.is_vietnamese_vowel(raw[inidx - 1]))
		or (inidx < p.rawlen and util.is_vietnamese_vowel(raw[inidx + 1]))
	then
		self:input_key()
		return self:update_tone_pos(method_config, tone_stragegy)
	end
	return false
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

--- Inserts the character at the cursor position into the word
function WordEngine:input_key()
	local p = _privates[self]
	local word, wlen = p.word, p.wlen
	if wlen < p.rawlen then
		tbl_insert(word, p.inserted_idx, p.inserted_key)
		p.wlen = wlen + 1
		p.struct_state = StructUnknown
	end
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

----- Updates the position of the tone mark in the word
---# @param self WordEngine The WordEngine instance
--- @param method_config table|nil The method configuration to use for updating the tone mark position
--- @param tone_stragegy OrthographyStragegy The strategy to use for finding the main vowel position, defaults to "modern"
--- @return boolean changed true if the tone mark position was updated, false otherwise
---@diagnostic disable-next-line: unused-local
function WordEngine:update_tone_pos(method_config, tone_stragegy)
	if self:analyze_structure() == StructInvalid then
		return false
	end

	local p = _privates[self]
	local tidx = p.tone_mark_idx
	-- no tone
	if tidx < 1 then
		return false
	end

	local vowel, new_idx = self:find_tone_pos(tone_stragegy, true)
	if not vowel or new_idx == tidx then
		return false
	end

	local word = p.word
	word[tidx] = level(word[tidx], 2)
	word[new_idx] = util.merge_tone_lv2(vowel, p.tone_mark)
	p.tone_mark_idx = new_idx
	return true
end

function WordEngine:tostring(use_raw)
	return concat_tight_range(use_raw and _privates[self].raw or _privates[self].word)
end

--- Finds the main vowel in the word based on the strategy
--- @param word string[] The character list of the word_len
--- @param wlen integer The length of the word
--- @param vs integer The start index of the vowel sequence (1-based)
--- @param ve integer The end index of the vowel sequence (1-based)
--- @param vnorms table|nil The normalized vowel sequence layer, mapping indices to normalized vowels
--- @return string|nil The main vowel character if found, nil otherwise
--- @return integer The index of the main vowel character if found, -1 otherwise
local function find_old_tone_pos(word, wlen, vs, ve, vnorms)
	local mvi = vs

	-- triphthong
	if ve - vs + 1 == 3 or ve < wlen then
		mvi = vs + 1
	end

	if not vnorms then
		return nil, -1
	end

	local v
	for k = vs, ve do
		v = vnorms[k]
		if v == "ơ" or v == "ê" or v == "ô" or v == "ư" or v == "ă" or v == "â" then
			mvi = k -- first vowel is the main vowel
		end
	end

	return word[mvi], mvi
end

--- Finds the main vowel in the word based on the modern strategy
--- @param word string[] The character list of the word_len
--- @param wlen integer The length of the word
--- @param vs integer The start index of the vowel sequence (1-based)
--- @param ve integer The end index of the vowel sequence (1-based)
--- @param vnorms table|nil The normalized vowel sequence layer, mapping indices to normalized vowels
--- @return string|nil The main vowel character if found, nil otherwise
--- @return integer The index of the main vowel character if found, -1 otherwise
---@diagnostic disable-next-line: unused-local
local function find_modern_tone_pos(word, wlen, vs, ve, vnorms)
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
	local priority
	for k = vs, ve do
		priority = VOWEL_PRIORITY[vnorms[k]]
		if priority < min_priority then
			min_priority = priority
			mvi = k
		end
	end

	return word[mvi], mvi
end

--- Function to find main vowel
--- @param stragegy OrthographyStragegy the strategy to use for finding the main vowel
--- @param force_recheck boolean|nil whether to force recompute the position even it only had tone marked already
--- @return string|nil the main vowel character if found, nil otherwise
--- @return integer the index of the main vowel character if found, nil otherwise
function WordEngine:find_tone_pos(stragegy, force_recheck)
	if self:analyze_structure() == StructInvalid then
		return nil, -1
	end

	local p = _privates[self]
	if p.vowel_start < 0 then
		return nil, -1
	end

	local word, vs, ve, tidx = p.word, p.vowel_start, p.vowel_end, p.tone_mark_idx

	-- only one vowel in the word
	if vs == ve then
		return word[vs], vs
	elseif not force_recheck and tidx > 0 then
		return word[tidx], tidx
	elseif stragegy == "old" then
		return find_old_tone_pos(word, p.wlen, vs, ve, p.vnorms)
	end
	return find_modern_tone_pos(word, p.wlen, vs, ve, p.vnorms)
end

--- Detects the tone mark in the vowel sequence
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return Diacritic|nil The tone mark if it exists, nil otherwise
--- @return integer The index of the tone mark in the vowel sequence (1-based), or -1 if no tone mark exists
---@diagnostic disable-next-line: unused-local
local function detect_tone_mark(chars, chars_size, vowel_start, vowel_end)
	local tone
	for i = vowel_start, vowel_end do
		tone = util.get_tone_mark(chars[i])
		if tone then
			return tone, i
		end
	end
	return nil, -1
end

--- Validate the vowel cluster in the character table
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return VowelSeqStatus The status of the vowel sequence
--- @return table|nil The normalized vowel sequence if it exists
---@diagnostic disable-next-line: unused-local
local function detect_vowel_seq(chars, chars_size, vowel_start, vowel_end)
	if vowel_start == vowel_end then
		return VowelSeqStatus.Valid, { [vowel_start] = lower_char(level(chars[vowel_start], 2)) }
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
		vnorms[i] = lower_char(level(chars[i], 2))
	end
	local seq_map = VOWEL_SEQS[concat_tight_range(vnorms, vowel_start, vowel_end)]

	if seq_map == false then
		return VowelSeqStatus.Ambiguous, vnorms
	elseif seq_map == nil then
		return VowelSeqStatus.Invalid, vnorms
	end
	return VowelSeqStatus.Valid, vnorms
end

--- Validate onset (consonant cluster) before the vowel
--- @param chars table The character table
--- @param vowel_start integer The index of the first vowel (1-based)
--- @return integer onset_end The index of the end of the onset cluster (-1 if invalid otherwise >=0 valid, > 0 if found, == 0 if no onset found)
local function detect_onset(chars, vowel_start, vowel_end)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return 0
	elseif cluster_len > 3 then
		return -1
	elseif cluster_len == 1 then
		local c1 = chars[1]
		if vowel_end > vowel_start and ONSETS[(c1 .. chars[2]):lower()] then
			-- Special case: consonant overlaps with vowel
			-- e.g "qu", "gi"
			return 2
		end
		return ONSETS[c1:lower()] and 1 or -1
	elseif cluster_len == 2 then
		return ONSETS[(chars[1] .. chars[2]):lower()] and 2 or -1
	end
	return ONSETS[(chars[1] .. chars[2] .. chars[3]):lower()] and 3 or -1
end

--- Fix the onset and vowel conflicts
--- @param onset_end integer The index of the end of the onset cluster (1-based)
--- @param vowel_start integer The index of the first vowel (1-based)
--- @param vowel_end integer The index of the last vowel (1-based)
--- @return integer new_vowel_start The adjusted index of the first vowel (1-based)
local function skip_eaten_vowels(onset_end, vowel_start, vowel_end)
	if onset_end < vowel_start then
		return vowel_start
	end

	local new_vs = onset_end + 1
	return new_vs > vowel_end and -1 or new_vs
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
	local vs, ve = util.find_vowel_seq_bounds(word, wlen)

	if vs < 1 then
		if wlen == 1 and util.is_d(word[1]) then
			-- Special d
			p.struct_state = StructShapeReady
		else
			p.struct_state = StructInvalid
		end

		return p.struct_state
	end

	local onset_end = detect_onset(word, vs, ve)
	if onset_end < 0 then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	vs = skip_eaten_vowels(onset_end, vs, ve)
	if vs < 1 then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	local status, vnorms = detect_vowel_seq(word, wlen, vs, ve)
	if status == VowelSeqStatus.Invalid then
		p.struct_state = StructInvalid
		return p.struct_state
	elseif status == VowelSeqStatus.Ambiguous then
		p.struct_state = StructShapeReady
	end

	if not validate_coda(word, wlen, ve) then
		p.struct_state = StructInvalid
		return p.struct_state
	end

	p.tone_mark, p.tone_mark_idx = detect_tone_mark(word, wlen, vs, ve)
	p.vowel_shift = vs - onset_end
	p.vowel_start, p.vowel_end = vs, ve
	p.vnorms = vnorms
	p.struct_state = StructValid
	return p.struct_state
end

--- Removes the tone mark from the main vowel in the word
--- @param self WordEngine The WordEngine instance
--- @param p PrivateWordEngineFields The private fields of the WordEngine instance
--- @param method_config table|nil The method configuration to use for tone removal
--- @return boolean True if the tone mark was removed, false otherwise
---@diagnostic disable-next-line: unused-local
local function remove_tone(self, p, method_config)
	local word, tone, tidx = p.word, p.tone_mark, p.tone_mark_idx
	if not tone then
		self:input_key()
		return false
	end
	word[tidx] = level(word[tidx], 2) -- remove the tone mark
	p.tone_mark = nil
	p.tone_mark_idx = -1
	return true
end

--- Processes tone marks in the word
--- @param self WordEngine The WordEngine instance
--- @param p PrivateWordEngineFields The private fields of the WordEngine instance
--- @param method_config table The method configuration to use for processing tones
--- @param tone_stragegy OrthographyStragegy The strategy to use for finding the main vowel position, defaults to "modern"
--- @return boolean True if the tone mark was processed, false otherwise
local function processes_tone(self, p, method_config, tone_stragegy)
	local inserted_key, inserted_idx = p.inserted_key, p.inserted_idx
	if not inserted_key then
		return false
	end

	local main_vowel, tidx = self:find_tone_pos(tone_stragegy)

	if not main_vowel or inserted_idx <= tidx then
		return false
	end

	local lv2_vowel, removed_tone = util.strip_tone(main_vowel)
	local applying_tone = mc_util.get_tone_diacritic(inserted_key, lv2_vowel, method_config)

	if not applying_tone then
		return false
	elseif removed_tone == applying_tone then
		p.word[tidx] = lv2_vowel -- restore the original vowel
		self:input_key()
		p.tone_mark = nil
		p.tone_mark_idx = -1
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		p.word[tidx] = util.merge_tone_lv2(lv2_vowel, applying_tone)
		p.tone_mark = applying_tone
		p.tone_mark_idx = tidx
	end
	return true
end

--- Collects effects of applying shape diacritics to the characters in the word
--- @param chars table The character table of the word_len
--- @param vs integer The index of the first vowel (1-based)
--- @param ve integer The index of the last vowel (1-based)
--- @param key string The character at the cursor position
--- @param method_config table The method configuration to use for shape diacritics
--- @return table<integer,{idx: integer, no_shape_char: string, curr_shape: Diacritic, char: string, applying_shape:Diacritic }> effects A table of effects, each effect is a table with the following fields:
--- @return integer ecount The number of effects collected
local function collect_effects(chars, vs, ve, key, method_config)
	local strip_shape = util.strip_shape
	local get_shape_diacritic = mc_util.get_shape_diacritic

	local effects = {}

	local char1 = chars[1]
	local horizontal_stroke = util.is_d(char1) and get_shape_diacritic(key, char1, method_config)
	if horizontal_stroke then
		local no_shape_char, curr_shape = strip_shape(char1)
		effects[1] = {
			idx = 1, -- index of the character in the word
			char = char1, -- character itself
			no_shape_char = no_shape_char, -- character without shape diacritic
			curr_shape = curr_shape, -- current shape diacritic of the character
			applying_shape = horizontal_stroke, -- diacritic to apply
		}
		return effects, 1
	end

	local ecount = 0
	-- to make sure that in the "qu" or "gi" case "u" and "i" is consider ass a consonant
	for i = vs, ve do
		local c = chars[i]
		local shape_diacritic = get_shape_diacritic(key, c, method_config)
		if shape_diacritic then
			local no_shape_char, curr_shape = strip_shape(c)
			ecount = ecount + 1
			effects[ecount] = {
				idx = i,
				char = c,
				no_shape_char = no_shape_char,
				curr_shape = curr_shape,
				applying_shape = shape_diacritic,
			}
		end
	end
	return effects, ecount
end

local function processes_shape(self, p, method_config, tone_stragegy)
	local word, wlen, vs, ve, inidx = p.word, p.wlen, p.vowel_start, p.vowel_end, p.inserted_idx

	local effects, ecount = collect_effects(word, vs, ve, p.inserted_key, method_config)

	if ecount == 0 then
		return false -- no shape diacritic found
	elseif ecount > 1 then
		local u, o = effects[1], effects[2]
		local uidx, oidx = u.idx, o.idx
		local lv1u, lv1o = level(u.char, 1), level(o.char, 1)

		local dual_horn = oidx < wlen -- must have the coda
			and oidx - uidx == 1 -- must be adjacent
			and (lv1u == "u" or lv1u == "U") -- must be a vowel
			and (lv1o == "o" or lv1o == "O") -- must be a vowel
			-- just need one of them to affect
			and (u.applying_shape == Diacritic.Horn or o.applying_shape == Diacritic.Horn)

		if dual_horn then
			if oidx >= inidx then
				return false
			elseif u.curr_shape == Diacritic.Horn and o.curr_shape == Diacritic.Horn then
				-- restore the horn
				word[uidx] = u.no_shape_char
				word[oidx] = o.no_shape_char
				self:input_key()
				return true
			end

			word[uidx] = util.merge_diacritic(u.char, Diacritic.Horn)
			word[oidx] = util.merge_diacritic(o.char, Diacritic.Horn, true) --because o has 2 case shape

			local status, new_vnorms = detect_vowel_seq(word, wlen, vs, ve)
			if status == VowelSeqStatus.Valid then
				p.vnorms = new_vnorms
				p.struct_state = StructValid
				self:update_tone_pos(method_config, tone_stragegy)
				return true
			end

			self:input_key()
			return false
		end

		-- sort by had shape
		util.isort_b2(effects, ecount, function(a, b)
			if a.curr_shape and not b.curr_shape then
				return true
			elseif not a.curr_shape and b.curr_shape then
				return false
			end
			return a.idx < b.idx
		end)
	end

	for i = 1, ecount do
		local e = effects[i]
		local e_idx = e.idx

		if e_idx < inidx then
			if e.curr_shape == e.applying_shape then
				-- restore shape diacritic
				word[e_idx] = e.no_shape_char
				self:input_key()
				return true
			elseif e_idx < vs or e_idx > ve then
				-- case d character
				-- e_idx < vs when had at least 1 vowel
				-- e_idx > ve when had no vowel
				word[e_idx] = util.merge_diacritic(e.char, e.applying_shape)
				return true
			end

			-- in vowel sequence
			word[e_idx] = util.merge_diacritic(e.char, e.applying_shape, true)
			local status, new_vnorms = detect_vowel_seq(word, wlen, vs, ve)
			if status == VowelSeqStatus.Valid then
				p.vnorms = new_vnorms
				p.struct_state = StructValid
				self:update_tone_pos(method_config, tone_stragegy)
				return true
			end

			-- restore the before state
			word[e_idx] = e.char
		end
	end
	self:input_key()
	return false
end

--- Processes diacritics in the word
--- @param method_config table The method configuration to use for processing diacritics
--- @return boolean changed True if the diacritic was processed, false otherwise
function WordEngine:processes_diacritic(method_config, tone_stragegy)
	if self:analyze_structure() == StructInvalid then
		return false
	end

	local p = _privates[self]
	local inkey = p.inserted_key

	---@cast inkey string
	if mc_util.is_tone_removal_key(inkey, method_config) then
		return remove_tone(self, p, method_config)
	elseif mc_util.is_shape_key(inkey, method_config) then
		return processes_shape(self, p, method_config, tone_stragegy)
	elseif mc_util.is_tone_key(inkey, method_config) then
		return processes_tone(self, p, method_config, tone_stragegy)
	end
	return false
end

--- Checks if the word is a valid Vietnamese word
--- @return boolean True if the word is a valid Vietnamese word, false otherwise
function WordEngine:is_valid_vietnamese_word()
	return self:analyze_structure() == StructValid
end

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
	local raw, rawlen, csidx = p.raw, p.rawlen, p.cursor_idx

	local start = cursor_col_byteoffset - byte_len(raw, rawlen, 1, csidx - 1)
	local stop = csidx > rawlen and cursor_col_byteoffset
		or cursor_col_byteoffset + byte_len(raw, rawlen, csidx, rawlen)

	return start, stop
end

--- Calculates the current cursor column based on the inserted character
--- @param old_col integer The previous column position of the cursor_col_byteoffset
--- @return integer The updated column position of the cursor_col_byteoffset
function WordEngine:get_curr_cursor_col(old_col)
	local p = _privates[self]
	local rawlen, wlen = p.rawlen, p.wlen
	local csidx = p.cursor_idx
	local start = old_col - byte_len(p.raw, rawlen, 1, csidx - 1)

	if wlen == rawlen then
		return start + byte_len(p.word, wlen, 1, csidx - 1)
	elseif wlen < rawlen then
		return start + byte_len(p.word, wlen, 1, p.inserted_idx - 1)
	end
	return old_col
end

return WordEngine
