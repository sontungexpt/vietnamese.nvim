local Constant = require("vietnamese.constant")
local Util = require("vietnamese.util")
local BitMask = require("vietnamese.util.bitmask")
local McUtil = require("vietnamese.util.method-config")
local Codec = require("vietnamese.util.codec")

local tbl_insert, tbl_move, concat, byte = table.insert, table.move, table.concat, string.byte
local byte_len = Util.byte_len
local key_to_shape = McUtil.key_to_shape

local DIACRITIC = Codec.DIACRITIC
local ONSETS = Constant.ONSETS
local CODAS = Constant.CODAS
local VOWEL_SEQS = Constant.VOWEL_SEQS
local VOWEL_PRIORITY = Constant.VOWEL_PRIORITY

-- Word state constants (small ints for compact comparisons)
local WordUnknown = 0
local WordShapeReady = 1
local WordInvalid = 2
local WordValid = 3

-- Vowel-sequence status constants
local VowelSeqInvalid = 0
local VowelSeqValid = 1
local VowelSeqAmbiguous = 2

-- public module table (forward-declared so local helpers can call exported helpers)
local WordEngine = {}

-- Local helpers ------------------------------------------------------------

-- Clone `source` (length items) and insert `value` at `index` without changing source.
-- Returns new array and new length.
--- Clone an array and insert a value at the given index without mutating the original.
--- @param source any[] Original array (1-based sequence).
--- @param length integer Number of valid elements in `source`.
--- @param value any Value to insert.
--- @param index integer 1-based insertion index.
--- @return any[] new_array New array containing the inserted value.
--- @return integer new_length Updated length of the new array.
local function clone_with_insert(source, length, value, index)
	local new_length = length + 1
	local new_array = {}
	if index > 1 then
		tbl_move(source, 1, index - 1, 1, new_array)
	end
	new_array[index] = value
	if index <= length then
		tbl_move(source, index, length, index + 1, new_array)
	end
	return new_array, new_length
end

-- Precompute mask used by repetition logic in is_potential_vnword
local R2_MASK = 0
for _, v in ipairs({ "o", "u", "c", "n", "m", "g", "h", "p", "t" }) do
	R2_MASK = BitMask.mark_bit(R2_MASK, byte(v) - 97)
end

-- find_old_tone_pos: older orthography rule to pick main vowel
--- Select main vowel index using the older orthography heuristic.
--- @param word string[] Character array of the word.
--- @param wlen integer Number of characters in `word`.
--- @param vs integer 1-based start index of vowel sequence.
--- @param ve integer 1-based end index of vowel sequence.
--- @param vnorms table|nil Normalized vowel mapping (index -> normalized vowel) or nil.
--- @return string|nil main_vowel The chosen main vowel character or nil.
--- @return integer index 1-based index of the main vowel or -1 when not found.
local function find_old_tone_pos(word, wlen, vs, ve, vnorms)
	local mvi = vs
	if ve - vs + 1 == 3 or ve < wlen then
		mvi = vs + 1
	end
	if not vnorms then
		return nil, -1
	end
	for k = vs, ve do
		local v = vnorms[k]
		if v == "ơ" or v == "ê" or v == "ô" or v == "ư" or v == "ă" or v == "â" then
			mvi = k
		end
	end
	return word[mvi], mvi
end

-- find_modern_tone_pos: modern orthography rule using precomputed sequences and priority table
--- Select main vowel index using the modern orthography heuristic.
--- Uses precomputed sequences or vowel priority table.
--- @param word string[] Character array of the word.
--- @param wlen integer Number of characters in `word`.
--- @param vs integer 1-based start index of vowel sequence.
--- @param ve integer 1-based end index of vowel sequence.
--- @param vnorms table|nil Normalized vowel mapping (index -> normalized vowel) or nil.
--- @return string|nil main_vowel The chosen main vowel character or nil.
--- @return integer index 1-based index of the main vowel or -1 when not found.
local function find_modern_tone_pos(word, wlen, vs, ve, vnorms)
	if not vnorms then
		return nil, -1
	end
	local v_seq = concat(vnorms, "", vs, ve)
	local precomputed = VOWEL_SEQS[v_seq]
	if precomputed then
		local mvi = vs + precomputed
		return word[mvi], mvi
	end
	local mvi = -1
	local min_priority = math.huge
	for k = vs, ve do
		local priority = VOWEL_PRIORITY[vnorms[k]]
		if priority < min_priority then
			min_priority = priority
			mvi = k
		end
	end
	return word[mvi], mvi
end

-- detect_tone_mark: returns tone diacritic (not Flat) and its index, or nil, -1
--- Detect a tone diacritic inside the vowel sequence.
--- @param chars string[] Character array of the word.
--- @param chars_size integer Total number of characters in `chars`.
--- @param vowel_start integer 1-based start index of vowel sequence.
--- @param vowel_end integer 1-based end index of vowel sequence.
--- @return Diacritic|nil tone Detected tone diacritic (DIACRITIC.*) or nil.
--- @return integer index 1-based index of the tone diacritic or -1 if none found.
local function detect_tone_mark(chars, chars_size, vowel_start, vowel_end)
	for i = vowel_start, vowel_end do
		local tone = Codec.tone(chars[i])
		if tone ~= DIACRITIC.Flat then
			return tone, i
		end
	end
	return nil, -1
end

-- detect_vowel_seq: normalize vowel sequence and validate using precomputed table
--- Validate and normalize a vowel cluster and return normalized mapping.
--- @param chars string[] Character array of the word.
--- @param chars_size integer Total characters in `chars`.
--- @param vowel_start integer 1-based start index of vowel sequence.
--- @param vowel_end integer 1-based end index of vowel sequence.
--- @return integer status One of VowelSeqInvalid, VowelSeqValid, VowelSeqAmbiguous.
--- @return table|nil vnorms Mapping (index -> normalized vowel) or nil when invalid.
local function detect_vowel_seq(chars, chars_size, vowel_start, vowel_end)
	if vowel_start == vowel_end then
		return VowelSeqValid, { [vowel_start] = Codec.strip_tone_case(chars[vowel_start]) }
	end
	local vnorms = {}
	for i = vowel_start, vowel_end do
		vnorms[i] = Codec.strip_tone_case(chars[i])
	end
	local seq_map = VOWEL_SEQS[concat(vnorms, "", vowel_start, vowel_end)]
	if seq_map == false then
		return VowelSeqAmbiguous, vnorms
	elseif seq_map == nil then
		return VowelSeqInvalid, vnorms
	end
	return VowelSeqValid, vnorms
end

-- detect_onset: validate consonant cluster before the vowel (returns length/end index or -1)
--- Validate the onset (consonant cluster before vowel) and return its end index.
--- @param chars string[] Character array of the word.
--- @param vowel_start integer 1-based start index of vowel sequence.
--- @param vowel_end integer 1-based end index of vowel sequence.
--- @return integer onset_end Returns 0 when no onset, >0 for the end index of the onset, -1 when invalid.
local function detect_onset(chars, vowel_start, vowel_end)
	local cluster_len = vowel_start - 1
	if cluster_len == 0 then
		return 0
	elseif cluster_len > 3 then
		return -1
	elseif cluster_len == 1 then
		local c1 = chars[1]
		if c1 == "Đ" then
			return 1
		elseif vowel_end > vowel_start and ONSETS[(c1 .. chars[2]):lower()] then
			return 2
		end
		return ONSETS[c1:lower()] and 1 or -1
	elseif cluster_len == 2 then
		return ONSETS[(chars[1] .. chars[2]):lower()] and 2 or -1
	end
	return ONSETS[(chars[1] .. chars[2] .. chars[3]):lower()] and 3 or -1
end

-- skip_eaten_vowels: if onset overlaps with vowel sequence adjust the vowel start
--- Adjust vowel_start when an onset has overlapped/eaten vowels (e.g. qu, gi cases).
--- @param onset_end integer 1-based end index of onset cluster.
--- @param vowel_start integer 1-based start index of vowel sequence.
--- @param vowel_end integer 1-based end index of vowel sequence.
--- @return integer new_vowel_start Adjusted 1-based start of vowel sequence or -1 if invalid.
local function skip_eaten_vowels(onset_end, vowel_start, vowel_end)
	if onset_end < vowel_start then
		return vowel_start
	end
	local new_vs = onset_end + 1
	return new_vs > vowel_end and -1 or new_vs
end

-- validate_coda: check consonant cluster after vowel using CODAS table
--- Validate coda (consonant cluster after the vowel sequence).
--- @param chars string[] Character array of the word.
--- @param chars_size integer Total characters in `chars`.
--- @param vowel_end integer 1-based index of the last vowel.
--- @return boolean True if the coda is valid for Vietnamese; false otherwise.
local function validate_coda(chars, chars_size, vowel_end)
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

-- collect_effects: helper for shape diacritic processing (returns a list and count)
--- Collect shape-diacritic effects when applying `inkey` to the word.
--- Returns a list of effect objects and the count.
--- @param chars string[] Character array.
--- @param vs integer 1-based start index of vowel sequence.
--- @param ve integer 1-based end index of vowel sequence.
--- @param inkey string The key pressed that may trigger a shape diacritic.
--- @param inidx integer 1-based insertion index.
--- @param method_config table Method configuration used to resolve shape mapping.
--- @return table effects List of effect objects: { idx=integer, char=string, striped=string, curr_shape=Diacritic, target_shape=Diacritic }
--- @return integer ecount Number of effects collected.
local function collect_effects(chars, vs, ve, inkey, inidx, method_config)
	if inidx < 2 then
		return {}, 0
	end
	local effects = {}
	local c1 = chars[1]
	local stroke = Codec.is_dD(c1) and key_to_shape(inkey, c1, method_config)
	if stroke then
		local striped, curr_shape = Codec.strip_shape2(c1)
		effects[1] = {
			idx = 1,
			char = c1,
			striped = striped,
			curr_shape = curr_shape,
			target_shape = stroke,
		}
		return effects, 1
	end
	local ecount = 0
	local upto = ve < inidx and ve or inidx
	for i = vs, upto do
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

-- Core processors (operate on `state` -------------------------------------------------
-- Note: all functions receive a `state` table as their first argument. This avoids creating
-- new closures per instance and keeps the hot path allocation-free when reusing the singleton.

-- Insert the pending inserted character into state.chars (if not already)
--- Insert the pending `insert_char` into the state's `chars` array (if not already inserted).
--- @param state table WordEngine state table.
--- @return nil
local function input_key(state)
	local word, wlen = state.chars, state.char_count
	if wlen < state.orig_count then
		tbl_insert(word, state.insert_index, state.insert_char)
		state.char_count = wlen + 1
		state.word_state = WordUnknown
	end
end

-- processes_tone: apply or toggle tone on the main vowel
--- Apply a tone diacritic based on the inserted key to the main vowel.
--- @param state table WordEngine state.
--- @param method_config table Method configuration for tone mapping.
--- @param tone_stragegy string|nil Orthography strategy ("modern"/"old").
--- @return boolean True if tone was applied/changed; false otherwise.
local function processes_tone(state, method_config, tone_stragegy)
	local insert_char, insert_idx = state.insert_char, state.insert_index
	if not insert_char then
		return false
	end
	local main_vowel, tidx = WordEngine.find_tone_pos(state, tone_stragegy)
	if not main_vowel or insert_idx <= tidx then
		return false
	end
	local striped, removed_tone = Codec.strip_tone2(main_vowel)
	local applying_tone = McUtil.key_to_tone(insert_char, striped, method_config)
	if not applying_tone then
		return false
	elseif removed_tone == applying_tone then
		state.chars[tidx] = striped
		input_key(state)
		state.tone = nil
		state.tone_index = -1
	else
		state.chars[tidx] = Codec.merge_diacritic(striped, applying_tone)
		state.tone = applying_tone
		state.tone_index = tidx
	end
	return true
end

-- processes_shape: apply shape diacritics such as Horn, Breve, etc.
--- Apply shape diacritics (Horn, Breve, etc.) to characters affected by the insertion.
--- Attempts to update state.chars and recompute vowel normalization.
--- @param state table WordEngine state.
--- @param method_config table Method configuration for shape mapping.
--- @param tone_stragegy string|nil Orthography strategy used when updating tone position.
--- @return boolean True if any shape change was applied; false otherwise.
local function processes_shape(state, method_config, tone_stragegy)
	local chars, char_count, vs, ve = state.chars, state.char_count, state.vowel_start, state.vowel_end
	local effects, ecount = collect_effects(chars, vs, ve, state.insert_char, state.insert_index, method_config)
	if ecount == 0 then
		return false
	elseif ecount > 1 then
		local u, o = effects[1], effects[2]
		local uidx, oidx = u.idx, o.idx
		local ubase, obase = Codec.base(u.char), Codec.base(o.char)
		local dual_horn = oidx < char_count
			and oidx - uidx == 1
			and ubase == "u"
			and obase == "o"
			and (u.target_shape == DIACRITIC.Horn or o.target_shape == DIACRITIC.Horn)
		if dual_horn then
			if u.curr_shape == DIACRITIC.Horn and o.curr_shape == DIACRITIC.Horn then
				chars[uidx] = u.striped
				chars[oidx] = o.striped
				input_key(state)
				return true
			end
			chars[uidx] = Codec.merge_diacritic(u.char, DIACRITIC.Horn)
			chars[oidx] = Codec.merge_diacritic(o.char, DIACRITIC.Horn)
			local status, new_vnorms = detect_vowel_seq(chars, char_count, vs, ve)
			if status == VowelSeqValid then
				state.vnorms = new_vnorms
				state.word_state = WordValid
				WordEngine.update_tone_pos(state, method_config, tone_stragegy)
				return true
			end
			input_key(state)
			return false
		end
		local Flat = DIACRITIC.Flat
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
			chars[e_idx] = e.striped
			input_key(state)
			return true
		elseif e_idx < vs or e_idx > ve then
			chars[e_idx] = Codec.merge_diacritic(e.char, e.target_shape)
			return true
		end
		chars[e_idx] = Codec.merge_diacritic(e.char, e.target_shape)
		local status, new_vnorms = detect_vowel_seq(chars, char_count, vs, ve)
		if status == VowelSeqValid then
			state.vnorms = new_vnorms
			state.word_state = WordValid
			WordEngine.update_tone_pos(state, method_config, tone_stragegy)
			return true
		end
		chars[e_idx] = e.char
	end
	input_key(state)
	return false
end

-- Public API (module-level functions) -----------------------------------------

-- Internal singleton state reused across keystrokes to avoid allocations
local _singleton_state = nil

-- Reset fields of a state object for reuse
--- Reset a WordEngine state table in-place for reuse.
--- @param state table State table to reset (modified in-place).
--- @param chars string[] Table (array) of UTF-8 characters representing the word.
--- @param char_count integer Number of characters in `chars`.
--- @param insert_char string The character inserted at the cursor (may be empty).
--- @param insert_index integer The 1-based index in the original string where insertion occurs.
--- @return nil
function WordEngine._reset_state(state, chars, char_count, insert_char, insert_index)
	state.chars = chars
	state.char_count = char_count
	state.orig_chars, state.orig_count = clone_with_insert(chars, char_count, insert_char, insert_index)
	state.insert_index = insert_index
	state.insert_char = insert_char
	state.cursor_index = insert_index + 1
	state.word_state = WordUnknown
	state.tone = nil
	state.tone_index = -1
	state.vowel_start = -1
	state.vowel_end = -2
	state.vowel_shift = 0
	state.vnorms = nil
end

-- Acquire a singleton state object initialized for the given input.
-- Reuses the same table each call to avoid allocations.
--- Acquire a singleton WordEngine state initialized for the given input.
--- Reuses a single state table to avoid per-keystroke allocations. Caller MUST NOT retain the returned table across asynchronous or nested uses because it will be mutated on the next acquire.
--- @param chars string[] Table (array) of UTF-8 characters representing the current word chunk.
--- @param char_count integer Number of characters in `chars`.
--- @param insert_char string Character inserted at cursor position (may be empty).
--- @param insert_index integer 1-based insertion index inside the original characters.
--- @return table state The singleton state table ready for processing.
function WordEngine.acquire(chars, char_count, insert_char, insert_index)
	if not _singleton_state then
		_singleton_state = {}
	end
	WordEngine._reset_state(_singleton_state, chars, char_count, insert_char, insert_index)
	return _singleton_state
end

-- Inspectors / quick checks --------------------------------------------------
--- Return true if the given state contains a potential Vietnamese word
--- Quick heuristics whether `state.chars` represent a potential Vietnamese word.
--- This check is conservative and fast (filters out obvious non-words).
--- @param state table The WordEngine state returned from `acquire`.
--- @return boolean True if the state passes basic Vietnamese word heuristics, false otherwise.
function WordEngine.is_potential_vnword(state)
	local chars, char_count = state.chars, state.char_count
	if char_count > 1 then
		local vs, ve = nil, nil
		local tone_found = false
		local left_times = {}
		for i = 1, char_count do
			local c = chars[i]
			if Codec.is_vn_vowel(c) then
				vs, ve = vs or i, i
			end
			if Codec.has_tone(c) then
				if tone_found then
					return false
				end
				tone_found = true
			end
			local b1, b2 = byte(c, 1, 2)
			if b2 then
				b1, b2 = byte(Codec.base(c), 1, 2)
				if b2 then
					return false
				end
			end
			if b1 > 64 and b1 < 91 then
				b1 = b1 + 32
			elseif b1 < 97 or b1 > 122 then
				return false
			end
			if left_times[b1] == 0 then
				return false
			end
			left_times[b1] = (left_times[b1] or (BitMask.is_marked(R2_MASK, b1 - 97) and 2 or 1)) - 1
		end
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

--- Check if an inserted key could be a diacritic affecting previous chars
--- Determine whether the recently typed key may be a diacritic that affects prior characters.
--- @param state table The WordEngine state.
--- @param method_config table The method configuration (key -> diacritic mapping).
--- @return boolean True if a diacritic could apply; false otherwise.
function WordEngine.is_potential_diacritic_key(state, method_config)
	local orig_chars, insert_char = state.orig_chars, state.insert_char
	for i = state.insert_index - 1, 1, -1 do
		if McUtil.key_to_diacritic(insert_char, orig_chars[i], method_config) then
			return true
		end
	end
	return false
end

--- Process a newly typed vowel (if it creates/extends a vowel cluster)
--- Handle insertion of a vowel at the cursor: insert and update tone if adjacent vowels.
--- @param state table The WordEngine state.
--- @param method_config table Method configuration used to resolve diacritics/tone.
--- @param tone_stragegy string|nil Orthography strategy ("modern" or "old").
--- @return boolean True if change applied (caller should update buffer); false otherwise.
function WordEngine.processes_new_vowel(state, method_config, tone_stragegy)
	local raw, inidx = state.orig_chars, state.insert_index
	if
		(inidx > 1 and Codec.is_vn_vowel(raw[inidx - 1]))
		or (inidx < state.orig_count and Codec.is_vn_vowel(raw[inidx + 1]))
	then
		input_key(state)
		return WordEngine.update_tone_pos(state, method_config, tone_stragegy)
	end
	return false
end

--- Inserts the current insert_char into state.chars (if not already)
--- Insert the pending `insert_char` into `state.chars` if not already present.
--- @param state table The WordEngine state to mutate.
--- @return nil
function WordEngine.input_key(state)
	input_key(state)
end

--- Update tone position if necessary (e.g. when insertion changes vowel cluster)
--- Update the position of the tone mark if the main vowel has changed.
--- @param state table The WordEngine state (modified in-place).
--- @param method_config table|nil Optional method configuration.
--- @param tone_stragegy string|nil Orthography strategy.
--- @return boolean True if tone position was updated; false otherwise.
function WordEngine.update_tone_pos(state, method_config, tone_stragegy)
	if WordEngine.analyze_structure(state) == WordInvalid then
		return false
	end
	local tidx = state.tone_index
	if tidx < 1 then
		return false
	end
	local vowel, new_idx = WordEngine.find_tone_pos(state, tone_stragegy, true)
	if not vowel or new_idx == tidx then
		return false
	end
	local word = state.chars
	word[tidx] = Codec.strip_tone(word[tidx])
	word[new_idx] = Codec.merge_diacritic(vowel, state.tone)
	state.tone_index = new_idx
	return true
end

--- Return current word as string
--- Convert state's characters to a Lua string.
--- @param state table The WordEngine state.
--- @param use_origin boolean|nil If true, return the string built from `state.orig_chars` (pre-insert); otherwise use `state.chars`.
--- @return string word The concatenated string.
function WordEngine.tostring(state, use_origin)
	return concat(use_origin and state.orig_chars or state.chars)
end

--- Find the main vowel position using the chosen strategy
--- Find the main vowel and its index according to the orthography strategy.
--- @param state table The WordEngine state.
--- @param stragegy string|nil "old" or "modern" (default modern).
--- @param force_recheck boolean|nil If true, recompute even when a tone_index is already recorded.
--- @return string|nil main_vowel The vowel character chosen as main vowel, or nil if invalid.
--- @return integer index The 1-based index of main vowel in `state.chars`, or -1 when not found.
function WordEngine.find_tone_pos(state, stragegy, force_recheck)
	if WordEngine.analyze_structure(state) == WordInvalid then
		return nil, -1
	elseif state.vowel_start < 0 then
		return nil, -1
	end
	local vs, ve, tidx = state.vowel_start, state.vowel_end, state.tone_index
	if vs == ve then
		return state.chars[vs], vs
	elseif not force_recheck and tidx > 0 then
		return state.chars[tidx], tidx
	elseif stragegy == "old" then
		return find_old_tone_pos(state.chars, state.char_count, vs, ve, state.vnorms)
	end
	return find_modern_tone_pos(state.chars, state.char_count, vs, ve, state.vnorms)
end

--- Analyze word structure (onset + vowel cluster + coda) and cache in state
--- Analyze the word structure (onset + vowel cluster + coda) and cache results on `state`.
--- Populates: state.tone, state.tone_index, state.vowel_start, state.vowel_end, state.vnorms, state.word_state, state.vowel_shift.
--- @param state table The WordEngine state to analyze (modified in-place).
--- @param force boolean|nil If true, force re-analysis even when cached.
--- @return integer WordState One of WordUnknown (0), WordShapeReady (1), WordInvalid (2) or WordValid (3).
function WordEngine.analyze_structure(state, force)
	if not force and state.word_state ~= WordUnknown then
		return state.word_state
	end
	local chars, char_count = state.chars, state.char_count
	-- find first and last vowel
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
			state.word_state = WordShapeReady
		else
			state.word_state = WordInvalid
		end
		return state.word_state
	end
	local onset_end = detect_onset(chars, vs, ve)
	if onset_end < 0 then
		state.word_state = WordInvalid
		return state.word_state
	end
	vs = skip_eaten_vowels(onset_end, vs, ve)
	if vs < 1 then
		state.word_state = WordInvalid
		return state.word_state
	end
	local status, vnorms = detect_vowel_seq(chars, char_count, vs, ve)
	if status == VowelSeqInvalid then
		state.word_state = WordInvalid
		return state.word_state
	elseif status == VowelSeqAmbiguous then
		state.word_state = WordShapeReady
	end
	if not validate_coda(chars, char_count, ve) then
		state.word_state = WordInvalid
		return state.word_state
	end
	state.tone, state.tone_index = detect_tone_mark(chars, char_count, vs, ve)
	state.vowel_shift = vs - onset_end
	state.vowel_start, state.vowel_end = vs, ve
	state.vnorms = vnorms
	state.word_state = WordValid
	return state.word_state
end

--- Remove tone mark from the main vowel
--- Remove the tone mark from the main vowel in `state.chars`.
--- If no tone is present, this will insert the pending key instead (via input_key).
--- @param state table The WordEngine state (modified in-place).
--- @param method_config table|nil Optional method configuration.
--- @return boolean True if the tone mark was removed; false if no tone existed (and an insertion happened).
function WordEngine.remove_tone(state, method_config)
	if not state.tone then
		input_key(state)
		return false
	end
	local chars, tidx = state.chars, state.tone_index
	chars[tidx] = Codec.strip_tone(chars[tidx])
	state.tone = nil
	state.tone_index = -1
	return true
end

--- Process a diacritic key (shape / tone / remove tone)
--- Process a diacritic key (shape/tone/removal) against `state`.
--- Chooses the proper processor (remove_tone, processes_shape, processes_tone) based on input and method config.
--- @param state table The WordEngine state.
--- @param method_config table Method configuration to use.
--- @param tone_stragegy string|nil Orthography strategy.
--- @return boolean True if a change was applied to `state`; false otherwise.
function WordEngine.processes_diacritic(state, method_config, tone_stragegy)
	if WordEngine.analyze_structure(state) == WordInvalid then
		return false
	end
	local insert_char = state.insert_char
	if McUtil.is_tone_removal_key(insert_char, method_config) then
		return WordEngine.remove_tone(state, method_config)
	elseif McUtil.is_shape_key(insert_char, method_config) then
		return processes_shape(state, method_config, tone_stragegy)
	elseif McUtil.is_tone_key(insert_char, method_config) then
		return processes_tone(state, method_config, tone_stragegy)
	end
	return false
end

--- Quick validity check
--- Check whether the state represents a valid Vietnamese word.
--- @param state table The WordEngine state.
--- @return boolean True if valid; false otherwise.
function WordEngine.is_valid_vietnamese_word(state)
	return WordEngine.analyze_structure(state) == WordValid
end

--- Cursor / column helpers --------------------------------------------------
--- Compute display-cell boundaries (start, stop) for replacing the current word.
--- @param state table The WordEngine state.
--- @param cursor_cell_idx integer Cursor column in display cells (0-based)
--- @return integer start The start column boundary.
--- @return integer stop The end column boundary (exclusive).
function WordEngine.cell_boundaries(state, cursor_cell_idx)
	local strdisplaywidth = vim.fn.strdisplaywidth
	local raw, csidx = state.orig_chars, state.cursor_index
	local start = cursor_cell_idx - strdisplaywidth(concat(raw, "", 1, csidx - 1))
	local stop = csidx > state.orig_count and cursor_cell_idx
		or cursor_cell_idx + strdisplaywidth(concat(raw, "", csidx, state.orig_count))
	return start, stop
end

--- Compute byte-offset bounds (start, stop) for replacing the current word in the buffer.
--- @param state table The WordEngine state.
--- @param cursor_col_byteoffset integer Cursor byte offset in the current line (0-based).
--- @return integer start The starting byte offset to replace.
--- @return integer stop The ending byte offset to replace (exclusive).
function WordEngine.col_bounds(state, cursor_col_byteoffset)
	local origins, orig_count, csidx = state.orig_chars, state.orig_count, state.cursor_index
	local start = cursor_col_byteoffset - byte_len(origins, orig_count, 1, csidx - 1)
	local stop = csidx > orig_count and cursor_col_byteoffset
		or cursor_col_byteoffset + byte_len(origins, orig_count, csidx, orig_count)
	return start, stop
end

--- Compute new cursor column after the word replacement.
--- @param state table The WordEngine state (with updated `chars`).
--- @param old_col integer Previous cursor column (byte offset).
--- @return integer new_col The updated cursor column to restore.
function WordEngine.get_curr_cursor_col(state, old_col)
	local origin_count, char_count, csidx = state.orig_count, state.char_count, state.cursor_index
	local start = old_col - byte_len(state.orig_chars, origin_count, 1, csidx - 1)
	if char_count == origin_count then
		return start + byte_len(state.chars, char_count, 1, csidx - 1)
	elseif char_count < origin_count then
		return start + byte_len(state.chars, char_count, 1, state.insert_index - 1)
	end
	return old_col
end

-- Expose module
return WordEngine
