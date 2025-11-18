local Constant = require("vietnamese.constant")
local Util = require("vietnamese.util")
local BitMask = require("vietnamese.util.bitmask")
local McUtil = require("vietnamese.util.method-config")
local Codec = require("vietnamese.util.codec")

local tbl_insert, tbl_move, concat, byte = table.insert, table.move, table.concat, string.byte
local lower_char, byte_len = Codec.lower_char, Util.byte_len
local key_to_shape = McUtil.key_to_shape

local DIACRITIC = Codec.DIACRITIC
local ONSETS = Constant.ONSETS
local CODAS = Constant.CODAS
local VOWEL_SEQS = Constant.VOWEL_SEQS
local VOWEL_PRIORITY = Constant.VOWEL_PRIORITY

--- @alias WordState
--- | 0 # WordShapeReady
--- | 1 # WordShapeReady
--- | 2 # WordInvalid
--- | 3 # WordValid

local WordUnknown = 0
local WordShapeReady = 1
local WordValid = 3
local WordInvalid = 2

--- @alias VowelSeqStatus
--- | 0 # VowelSeqInvalid
--- | 1 # VowelSeqValid
--- | 2 # VowelSeqAmbiguous

local VowelSeqInvalid = 0
local VowelSeqValid = 1
local VowelSeqAmbiguous = 2

--- @class WordEngine
--- @field chars string[] List of characters for processing
--- @field char_count integer Length of `word`
--- @field orig_chars string[] Original list of characters before modification
--- @field orig_count integer Length of `raw`
--- @field insert_index integer Index of the recently inserted character (if any)
--- @field insert_char string The character at the cursor position
--- @field cursor_index integer Current cursor position (1-based). If the cursor is at the end of the word, it is `raw_len + 1`.
--- @field word_state WordState State of the word structure analysis
--- @field vowel_start integer (after analysis) Index of the start of the vowel cluster (1-based)
--- @field vowel_end integer (after analysis) Index of the end of the vowel cluster (1-based)
--- @field vowel_shift integer (after analysis) Offset if the onset overlaps with the vowel cluster
--- @field vnorms table|nil (after analysis) --- Normalized vowel sequence layer, mapping indices to normalized vowels example: for word = { "d", "a", "o" } -- normalized_vowel_layer = { [1] = nil, [2] = "a", [3] = "o" }. All chars is lowercase
--- @field tone Diacritic|nil (after analysis) The tone mark of the main vowel if it has one
--- @field tone_index integer (after analysis) The index of the tone mark in the word (1-based)
--- Represents a Vietnamese word. Provides utilities for analyzing vowel clusters,
--- determining the main vowel, and applying tone marks. Supports cursor-based character insertion.
local WordEngine = {}

-- allow to access public methods and properties
WordEngine.__index = WordEngine

--- Creates a new array with a single element inserted at a given index.
---
--- This function does **not** mutate the original array.
--- It clones the prefix, inserts the element, and copies the suffix efficiently using `table.move`.
---
--- @param source string[]|any[]  The original array to copy from.
--- @param length integer          The number of valid items in `source`.
--- @param value any               The value to insert.
--- @param index integer           The position (1-based) where `value` will be inserted.
--- @return any[] new_array        The newly created array.
--- @return integer new_length     The updated size of the new array.
local function clone_with_insert(source, length, value, index)
	local new_length = length + 1
	local new_array = {}

	-- Copy prefix
	if index > 1 then
		tbl_move(source, 1, index - 1, 1, new_array)
	end

	-- Insert value
	new_array[index] = value

	-- Copy suffix
	if index <= length then
		tbl_move(source, index, length, index + 1, new_array)
	end

	return new_array, new_length
end

--- Cr-eates a new CursorWord instance
--- @param cword table a table of characters representing the word
--- @param cwlen integer the length of the word
--- @param insert_key string the character at the cursor position
--- @param insert_idx integer the index of the cursor character (1-based)
--- @return WordEngine  instance
function WordEngine:new(cword, cwlen, insert_key, insert_idx)
	local orig_chars, org_count = clone_with_insert(cword, cwlen, insert_key, insert_idx)

	local obj = setmetatable({
		chars = cword,
		char_count = cwlen,
		orig_chars = orig_chars,
		orig_count = org_count,

		insert_index = insert_idx,
		insert_char = insert_key, -- the character at the cursor position

		-- cursor_char_index == raw_len + 1
		-- if the cursor is at the end of the word
		cursor_index = insert_idx + 1,

		word_state = WordUnknown, -- state of the word structure analysis

		-- this fields only have the real value after analysis
		tone = nil, -- the tone mark of the main vowel if it has one
		tone_index = -1, -- the index of the tone mark in the word (1-based)

		vowel_start = -1,
		vowel_end = -2, -- -2 to make sure that it is not valid when loop from start to end
		vowel_shift = 0, -- adjust the vowel start index if the onset overlaps with the vowel

		vnorms = nil, -- normalized vowel sequence layer, mapping indices to normalized vowels
	}, self)

	return obj
end

local R2_MASK = 0
for _, v in ipairs({ "o", "u", "c", "n", "m", "g", "h", "p", "t" }) do
	R2_MASK = BitMask.mark_bit(R2_MASK, byte(v) - 97)
end

--- Check if the word is a potential Vietnamese word
--- @return boolean potential true if the word is a potential Vietnamese word
function WordEngine:is_potential_vnword()
	local chars, char_count = self.chars, self.char_count
	if char_count > 1 then
		local vs, ve = nil, nil
		local tone_found = false
		local left_times = {}

		for i = 1, char_count do
			local c = chars[i]
			if Codec.is_vn_vowel(c) then
				vs, ve = vs or i, i
			end

			-- Check if word has multiple tones
			if Codec.has_tone(c) then
				if tone_found then
					return false
				end
				tone_found = true
			end

			--- Check max repetition times of each character
			local b1, b2 = byte(c, 1, 2)
			if b2 then -- more than 1 byte
				-- Convert to Unicode letter
				b1, b2 = byte(Codec.base_lower(c), 1, 2)
				if b2 then
					-- Still not a Unicode letter
					return false
				end
			end
			--- if uppercase then convert to lowercase
			if b1 > 64 and b1 < 91 then
				b1 = b1 + 32 -- convert to lowercase
			elseif b1 < 97 or b1 > 122 then -- not a letter
				-- Not a Unicode letter
				return false
			end
			if left_times[b1] == 0 then
				-- No more repetitions time allowed
				return false
			end
			left_times[b1] = (left_times[b1] or (BitMask.is_marked(R2_MASK, b1 - 97) and 2 or 1)) - 1
		end

		--- Check the length of the vowel sequence
		if not vs then
			return false
		end
		local v_seq_len = ve - vs + 1
		if v_seq_len < 1 or v_seq_len > 3 or (v_seq_len == 3 and not Codec.is_vn_vowel(chars[vs + 1])) then
			return false
		end
	end

	return true
end

--- Checks if the word is potential to apply diacritic
--- @param method_config table the method configuration to use for checking
--- @return boolean valid if the diacritic can be applied, false otherwise
function WordEngine:is_potential_diacritic_key(method_config)
	local orig_chars, insert_char = self.orig_chars, self.insert_char
	for i = self.insert_index - 1, 1, -1 do
		if McUtil.key_to_diacritic(insert_char, orig_chars[i], method_config) then
			return true
		end
	end
	return false
end

--- Returns the cursor position in the character list
--- @return string the character at the cursor position
function WordEngine:inserted_key()
	return self.insert_char
end

--- Processes the new vowel character at the cursor position
--- @param method_config table the method configuration to use for processing
--- @param tone_stragegy OrthographyStragegy the strategy to use for finding the main vowel position, defaults to "modern"
function WordEngine:processes_new_vowel(method_config, tone_stragegy)
	local raw, inidx = self.orig_chars, self.insert_index
	if
		(inidx > 1 and Codec.is_vn_vowel(raw[inidx - 1]))
		or (inidx < self.orig_count and Codec.is_vn_vowel(raw[inidx + 1]))
	then
		self:input_key()
		return self:update_tone_pos(method_config, tone_stragegy)
	end
	return false
end

--- Copies the raw character list to the word character list
function WordEngine:restore_raw(ovverides)
	local word, word_len, raw, raw_len = self.chars, self.char_count, self.orig_chars, self.orig_count
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
	self.char_count = raw_len
end

--- Inserts the character at the cursor position into the word
function WordEngine:input_key()
	local word, wlen = self.chars, self.char_count
	if wlen < self.orig_count then
		tbl_insert(word, self.insert_index, self.insert_char)
		self.char_count = wlen + 1
		self.word_state = WordUnknown
	end
end

----- Updates the position of the tone mark in the word
---# @param self WordEngine The WordEngine instance
--- @param method_config table|nil The method configuration to use for updating the tone mark position
--- @param tone_stragegy OrthographyStragegy The strategy to use for finding the main vowel position, defaults to "modern"
--- @return boolean changed true if the tone mark position was updated, false otherwise
---@diagnostic disable-next-line: unused-local
function WordEngine:update_tone_pos(method_config, tone_stragegy)
	if self:analyze_structure() == WordInvalid then
		return false
	end

	local tidx = self.tone_index
	-- no tone
	if tidx < 1 then
		return false
	end

	local vowel, new_idx = self:find_tone_pos(tone_stragegy, true)
	if not vowel or new_idx == tidx then
		return false
	end

	local word = self.chars
	word[tidx] = Codec.strip_tone(word[tidx])
	word[new_idx] = Codec.merge_diacritic(vowel, self.tone)
	self.tone_index = new_idx
	return true
end

--- Returns the word as a string
--- @param use_origin boolean|nil whether to use the original character list
--- @return string word the word as a string
function WordEngine:tostring(use_origin)
	return concat(use_origin and self.orig_chars or self.chars)
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
	local v_seq = concat(vnorms, "", vs, ve)
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
	if self:analyze_structure() == WordInvalid then
		-- error(main_vowel .. " " .. tidx .. " " .. insert_idx)
		return nil, -1
	elseif self.vowel_start < 0 then
		return nil, -1
	end

	local vs, ve, tidx = self.vowel_start, self.vowel_end, self.tone_index

	-- only one vowel in the word
	if vs == ve then
		return self.chars[vs], vs
	elseif not force_recheck and tidx > 0 then
		return self.chars[tidx], tidx
	elseif stragegy == "old" then
		return find_old_tone_pos(self.chars, self.char_count, vs, ve, self.vnorms)
	end
	return find_modern_tone_pos(self.chars, self.char_count, vs, ve, self.vnorms)
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
		tone = Codec.tone(chars[i])
		if tone ~= DIACRITIC.Flat then
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
		return VowelSeqValid, {
			[vowel_start] = lower_char(Codec.strip_tone(chars[vowel_start])),
		}
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
		vnorms[i] = lower_char(Codec.strip_tone(chars[i]))
	end

	local seq_map = VOWEL_SEQS[concat(vnorms, "", vowel_start, vowel_end)]
	if seq_map == false then
		return VowelSeqAmbiguous, vnorms
	elseif seq_map == nil then
		return VowelSeqInvalid, vnorms
	end
	return VowelSeqValid, vnorms
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
--- @return WordState The analysis state of the word
function WordEngine:analyze_structure(force)
	if not force and self.word_state ~= WordUnknown then
		return self.word_state
	end

	local chars, char_count = self.chars, self.char_count

	-- Find the first and last vowel
	local vs, ve = -1, -1
	for i = 1, char_count do
		if Codec.is_vn_vowel(chars[i]) then
			vs = i
			for j = char_count, i, -1 do
				if Codec.is_vn_vowel(chars[j]) then
					ve = j
					break
				end
			end
			break
		end
	end

	if vs < 1 then
		if char_count == 1 and Codec.is_dD(chars[1]) then
			-- Special d
			self.word_state = WordShapeReady
		else
			self.word_state = WordInvalid
		end

		return self.word_state
	end

	local onset_end = detect_onset(chars, vs, ve)
	if onset_end < 0 then
		self.word_state = WordInvalid
		return self.word_state
	end

	vs = skip_eaten_vowels(onset_end, vs, ve)
	if vs < 1 then
		self.word_state = WordInvalid
		return self.word_state
	end

	local status, vnorms = detect_vowel_seq(chars, char_count, vs, ve)
	if status == VowelSeqInvalid then
		self.word_state = WordInvalid
		return self.word_state
	elseif status == VowelSeqAmbiguous then
		self.word_state = WordShapeReady
	end

	if not validate_coda(chars, char_count, ve) then
		self.word_state = WordInvalid
		error("Invalid coda")
		return self.word_state
	end

	self.tone, self.tone_index = detect_tone_mark(chars, char_count, vs, ve)
	self.vowel_shift = vs - onset_end
	self.vowel_start, self.vowel_end = vs, ve
	self.vnorms = vnorms
	self.word_state = WordValid
	return self.word_state
end

--- Removes the tone mark from the main vowel in the word
--- @param self WordEngine The WordEngine instance
--- @param method_config table|nil The method configuration to use for tone removal
--- @return boolean True if the tone mark was removed, false otherwise
---@diagnostic disable-next-line: unused-local
local remove_tone = function(self, method_config)
	if not self.tone then
		self:input_key()
		return false
	end
	local chars, tidx = self.chars, self.tone_index
	chars[tidx] = Codec.strip_tone(chars[tidx]) -- remove the tone mark
	self.tone = nil
	self.tone_index = -1
	return true
end

--- Processes tone marks in the word
--- @param self WordEngine The WordEngine instance
--- @param method_config table The method configuration to use for processing tones
--- @param tone_stragegy OrthographyStragegy The strategy to use for finding the main vowel position, defaults to "modern"
--- @return boolean True if the tone mark was processed, false otherwise
local function processes_tone(self, method_config, tone_stragegy)
	local insert_char, insert_idx = self.insert_char, self.insert_index
	if not insert_char then
		return false
	end

	local main_vowel, tidx = self:find_tone_pos(tone_stragegy)

	if not main_vowel or insert_idx <= tidx then
		return false
	end

	local lv2_vowel, removed_tone = Codec.strip_tone2(main_vowel)
	local applying_tone = McUtil.key_to_tone(insert_char, lv2_vowel, method_config)

	if not applying_tone then
		return false
	elseif removed_tone == applying_tone then
		self.chars[tidx] = lv2_vowel -- restore the original vowel
		self:input_key()
		self.tone = nil
		self.tone_index = -1
	else
		-- no tone mark found,
		-- or the tone mark is different from the one we want to apply
		self.chars[tidx] = Codec.merge_diacritic(lv2_vowel, applying_tone)
		self.tone = applying_tone
		self.tone_index = tidx
	end
	return true
end

--- Collects effects of applying shape diacritics to the characters in the word
--- @param chars table The character table of the word_len
--- @param vs integer The index of the first vowel (1-based)
--- @param ve integer The index of the last vowel (1-based)
--- @param inkey string The character at the cursor position
--- @param method_config table The method configuration to use for shape diacritics
--- @return table<integer,{idx: integer, striped: string, curr_shape: Diacritic, char: string, target_shape: Diacritic }> effects A table of effects, each effect is a table with the following fields:
--- @return integer ecount The number of effects collected
local function collect_effects(chars, vs, ve, inkey, inidx, method_config)
	if inidx < 2 then -- no previous character to apply shape diacritic
		return {}, 0
	end

	local effects = {}

	local c1 = chars[1]
	local stroke = Codec.is_dD(c1) and key_to_shape(inkey, c1, method_config)
	if stroke then
		local striped, curr_shape = Codec.strip_shape2(c1)
		effects[1] = {
			idx = 1, -- index of the character in the word
			char = c1, -- character itself
			striped = striped, -- character without shape diacritic
			curr_shape = curr_shape, -- current shape diacritic of the character
			target_shape = stroke, -- diacritic to apply
		}
		return effects, 1
	end

	local ecount = 0
	-- to make sure that in the "qu" or "gi" case "u" and "i" is consider ass a consonant
	for i = vs, ve < inidx and ve or inidx do
		local c = chars[i]
		local shape_diacritic = key_to_shape(inkey, c, method_config)
		if shape_diacritic then
			local striped, curr_shape = Codec.strip_shape2(c)
			ecount = ecount + 1
			effects[ecount] = {
				idx = i,
				char = c,
				striped = striped,
				curr_shape = curr_shape,
				target_shape = shape_diacritic,
			}
		end
	end
	return effects, ecount
end

--- Processes shape diacritics in the word
--- @param self WordEngine The WordEngine instance
--- @param method_config table The method configuration to use for shape diacritics
--- @param tone_stragegy OrthographyStragegy The strategy to use for finding the main vowel position, defaults to "modern"
--- @return boolean True if the shape diacritic was processed, false otherwise
local function processes_shape(self, method_config, tone_stragegy)
	local chars, char_count, vs, ve = self.chars, self.char_count, self.vowel_start, self.vowel_end
	local effects, ecount = collect_effects(chars, vs, ve, self.insert_char, self.insert_index, method_config)

	if ecount == 0 then
		return false -- no shape diacritic found
	elseif ecount > 1 then
		local u, o = effects[1], effects[2]
		local uidx, oidx = u.idx, o.idx
		local ubase, obase = Codec.base_lower(u.char), Codec.base_lower(o.char)

		local dual_horn = oidx < char_count -- must have the coda
			and oidx - uidx == 1 -- must be adjacent
			and ubase == "u"
			and obase == "o"
			-- just need one of them to affect
			and (u.target_shape == DIACRITIC.Horn or o.target_shape == DIACRITIC.Horn)

		if dual_horn then
			if u.curr_shape == DIACRITIC.Horn and o.curr_shape == DIACRITIC.Horn then
				-- restore the horn
				chars[uidx] = u.striped
				chars[oidx] = o.striped
				self:input_key()
				return true
			end

			chars[uidx] = Codec.merge_diacritic(u.char, DIACRITIC.Horn)
			chars[oidx] = Codec.merge_diacritic(o.char, DIACRITIC.Horn)

			local status, new_vnorms = detect_vowel_seq(chars, char_count, vs, ve)
			if status == VowelSeqValid then
				self.vnorms = new_vnorms
				self.word_state = WordValid
				self:update_tone_pos(method_config, tone_stragegy)
				return true
			end

			self:input_key()
			return false
		end

		local Flat = DIACRITIC.Flat
		-- sort by had shape
		Util.insertion_sort(effects, ecount, function(a, b)
			if a.curr_shape ~= Flat and b.curr_shape == Flat then
				return true
			elseif a.curr_shape == Flat and b.curr_shape ~= Flat then
				return false
			end
			return a.idx < b.idx
		end)
	end

	for i = 1, ecount do
		local e = effects[i]
		local e_idx = e.idx

		if e.curr_shape == e.target_shape then
			-- restore shape diacritic
			chars[e_idx] = e.striped
			self:input_key()
			return true
		elseif e_idx < vs or e_idx > ve then
			-- case d character
			-- e_idx < vs when had at least 1 vowel
			-- e_idx > ve when had no vowel
			chars[e_idx] = Codec.merge_diacritic(e.char, e.target_shape)
			return true
		end

		-- in vowel sequence
		chars[e_idx] = Codec.merge_diacritic(e.char, e.target_shape)
		local status, new_vnorms = detect_vowel_seq(chars, char_count, vs, ve)
		if status == VowelSeqValid then
			self.vnorms = new_vnorms
			self.word_state = WordValid
			self:update_tone_pos(method_config, tone_stragegy)
			return true
		end

		-- restore the before state
		chars[e_idx] = e.char
	end
	self:input_key()
	return false
end

--- Processes diacritics in the word
--- @param method_config table The method configuration to use for processing diacritics
--- @return boolean changed True if the diacritic was processed, false otherwise
function WordEngine:processes_diacritic(method_config, tone_stragegy)
	if self:analyze_structure() == WordInvalid then
		return false
	end

	local insert_char = self.insert_char
	if McUtil.is_tone_removal_key(insert_char, method_config) then
		return remove_tone(self, method_config)
	elseif McUtil.is_shape_key(insert_char, method_config) then
		return processes_shape(self, method_config, tone_stragegy)
	elseif McUtil.is_tone_key(insert_char, method_config) then
		return processes_tone(self, method_config, tone_stragegy)
	end
	return false
end

--- Checks if the word is a valid Vietnamese word
--- @return boolean True if the word is a valid Vietnamese word, false otherwise
function WordEngine:is_valid_vietnamese_word()
	return self:analyze_structure() == WordValid
end

--- Returns the cell boundaries of the cursor position
--- @param cursor_cell_idx integer The current column position of the cursor
--- @return integer start The start column boundary of the cursor position
--- @return integer stop The end column boundary of the cursor position (exclusive)
function WordEngine:cell_boundaries(cursor_cell_idx)
	local strdisplaywidth = vim.fn.strdisplaywidth
	local raw, csidx = self.orig_chars, self.cursor_index
	local start = cursor_cell_idx - strdisplaywidth(concat(raw, "", 1, csidx - 1))
	local stop = csidx > self.orig_count and cursor_cell_idx
		or cursor_cell_idx + strdisplaywidth(concat(raw, "", csidx, self.orig_count))
	return start, stop
end

--- Returns the byte offset boundaries of the cursor position
--- @param cursor_col_byteoffset integer The current byte offset of the cursor pos
--- @return integer start The start byte offset boundary of the cursor position
--- @return integer stop The end byte offset boundary of the cursor position (exclusive)
function WordEngine:col_bounds(cursor_col_byteoffset)
	local origins, orig_count, csidx = self.orig_chars, self.orig_count, self.cursor_index
	local start = cursor_col_byteoffset - byte_len(origins, orig_count, 1, csidx - 1)
	local stop = csidx > orig_count and cursor_col_byteoffset
		or cursor_col_byteoffset + byte_len(origins, orig_count, csidx, orig_count)
	return start, stop
end

--- Calculates the current cursor column based on the inserted character
--- @param old_col integer The previous column position of the cursor_col_byteoffset
--- @return integer The updated column position of the cursor_col_byteoffset
function WordEngine:get_curr_cursor_col(old_col)
	local origin_count, char_count, csidx = self.orig_count, self.char_count, self.cursor_index
	local start = old_col - byte_len(self.orig_chars, origin_count, 1, csidx - 1)
	if char_count == origin_count then
		return start + byte_len(self.chars, char_count, 1, csidx - 1)
	elseif char_count < origin_count then
		return start + byte_len(self.chars, char_count, 1, self.insert_index - 1)
	end
	return old_col
end

return WordEngine
