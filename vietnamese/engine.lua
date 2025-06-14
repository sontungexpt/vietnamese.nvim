local vim = vim
local fn, api = vim.fn, vim.api
local require = require
local strcharpart, strcharlen, matchstrpos = fn.strcharpart, fn.strcharlen, fn.matchstrpos
local nvim_win_get_cursor, nvim_get_current_line = api.nvim_win_get_cursor, api.nvim_get_current_line
local util = require("vietnamese.util")
local nvim_buf_get_text, nvim_win_get_cursor = api.nvim_buf_get_text, api.nvim_win_get_cursor
local is_vietnamese_char = util.is_vietnamese_char

local CONSTANT = require("vietnamese.constant")
local TONE_PLACEMENT = CONSTANT.TONE_PLACEMENT
local VOWEL_SEQUENCES = CONSTANT.VOWEL_SEQUENCES
local UTF8_VN_CHAR_DICT = CONSTANT.UTF8_VN_CHAR_DICT
local THRESHOLD_WORD_LEN = 10

local decomposed_char_cache = {}

-- local VIETNAMESE_CHARS =
-- 	"áàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵđÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴĐ"

-- vietnamese_input/engine.lua
local M = {}
-- local VIETNAMESE_PATTERN =
-- 	"[%wáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵđÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴĐ]"

-- local LOWER_VIETNAMESE_PATTERN =
-- 	"[%láàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵđ]"

-- local UPPER_VIETNAMESE_PATTERN =
-- 	"[%uÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴĐ]"

-- local DIACRITIC_NAP = CONSTANT.DIACRITIC_NAP
-- local VALID_CONSONANTS = CONSTANT.VALID_CONSONANTS

-- local ONSET_PATTERN = CONSTANT.ONSET_PATTERN
-- local VOWEL_PATTERN = CONSTANT.VOWEL_PATTERN
-- local CODA_PATTERN = CONSTANT.CODA_PATTERN

--- Check if a character is a valid input character for the current method
local function is_moderator_char(char, method_config)
	char = char:lower()
	for _, diacritics in pairs(method_config.diacritic_map) do
		for diacritic, _ in pairs(diacritics) do
			if char == diacritic then
				return true
			end
		end
	end
	for tone, _ in pairs(method_config.tone_map) do
		if char == tone then
			return true
		end
	end
	for _, tone_removal in ipairs(method_config.tone_removals) do
		if char == tone_removal then
			return true
		end
	end
	for _, c in ipairs(method_config.char_map) do
		if c == char then
			return true
		end
	end
	return false
end

function M.get_config()
	return require("vietnamese.config").get_config()
end

function M.get_method_config()
	local user_config = M.get_config()
	local current_method = user_config.input_method

	local ok, method_config = pcall(require, "vietnamese.method." .. current_method)
	if not ok then
		method_config = user_config.custom_methods[current_method]
	end
	if type(method_config) ~= "table" then
		vim.notify(
			"Invalid method configuration for '" .. current_method .. "'. Please check your configuration.",
			vim.log.levels.ERROR,
			{ title = "Vietnamese Input Method Error" }
		)
		return nil
	end

	return method_config
end

function M.set_input_method(method)
	require("vietnamese.config").set_input_method(method)
end

function M.get_input_method()
	return require("vietnamese.config").get_config().input_method
end

local should_process_diacritic_tone = function(inserted_char, method_config)
	return type(method_config.is_moderator_char) == "function" and method_config.is_moderator_char(inserted_char)
		or is_moderator_char(inserted_char, method_config)
end

-- function M.is_valid_sequence(seq)
-- 	if strcharlen(seq) > 10 then -- too long word, skip processing
-- 		return false
-- 	end
-- 	-- Check for valid consonant clusters
-- 	for i = 1, #VALID_CONSONANTS do
-- 		local cons = VALID_CONSONANTS[i]
-- 		if seq:sub(1, #cons) == cons then
-- 			return true
-- 		end
-- 	end

-- 	-- Check for valid vowel sequences
-- 	for i = 1, #VOWELS do
-- 		local vowel = VOWELS[i]
-- 		if seq:find(vowel_seq) then
-- 			return true
-- 		end
-- 	end

-- 	return false
-- end
-- local valid_codas = {
-- 	c = true,
-- 	ch = true,
-- 	m = true,
-- 	n = true,
-- 	ng = true,
-- 	nh = true,
-- 	p = true,
-- 	t = true,
-- }

-- -- function M.is_valid_sequence(word)
-- -- 	if word == "" then
-- -- 		return false
-- -- 	elseif word:match("[^\1-\127\194-\244]") or word:match("[\194-\244][\128-\191]?[\128-\191]?[^\128-\191]") then
-- -- 		-- UTF-8 validation
-- -- 		return false
-- -- 	end

-- -- 	local util = require("vietnamese.util")
-- -- 	local lower_word = util.lower(word)

-- -- 	-- Build pattern components (case-insensitive)
-- -- 	local ci = {
-- -- 		onset = "()(" .. ONSET_PATTERN .. ")()",
-- -- 		vowel = "()(" .. VOWEL_PATTERN .. ")()",
-- -- 		coda = "()(" .. CODA_PATTERN .. ")()",
-- -- 	}

-- -- 	-- Syllable pattern with capture positions
-- -- 	local pattern = ("^(%%s*)(%s)()(%s+)(%s?)(%s?)$"):format(ci.onset, ci.vowel, ci.vowel, ci.vowel)
-- -- 	--

-- -- 	-- Match syllable structure
-- -- 	local _, o, o_end, v1, v1_end, v2, v2_end, v3 = word:match(pattern)
-- -- 	if not v1 then
-- -- 		return false
-- -- 	end

-- -- 	-- Extract vowel nucleus
-- -- 	local v_start = v1_end
-- -- 	local v_end = v3 and v3 or (v2 and v2_end or v1_end)
-- -- 	local v_nucleus = word:sub(v_start, v_end - 1)

-- -- 	-- Rule 1: ă must have coda
-- -- 	if v_nucleus:match("[ăĂắẮằẰẳẲẵẴặẶ]") then
-- -- 		local c_start = v_end
-- -- 		local c_part = word:sub(c_start)
-- -- 		if not c_part or c_part == "" then
-- -- 			return false
-- -- 		end
-- -- 	end

-- -- 	-- Rule 2: gh/ngh constraints
-- -- 	if o then
-- -- 		local o_text = word:sub(o, o_end - 1):lower()
-- -- 		if o_text == "gh" or o_text == "ngh" then
-- -- 			local next_char = word:sub(v_start, v_start):lower()
-- -- 			if not next_char:match("[iyeê]") then
-- -- 				return false
-- -- 			end
-- -- 		end
-- -- 	end

-- -- 	-- Rule 3: Validate coda
-- -- 	if v_end <= #word then
-- -- 		local c_part = word:sub(v_end):lower()
-- -- 		if not valid_codas[c_part] then
-- -- 			return false
-- -- 		end
-- -- 	end

-- -- 	return true
-- -- end
-- -- local function is_valid_vietnamese_syllable(word)
-- -- 	-- Step 1: Define valid components using UTF-8 ranges

-- -- 	-- Step 2: Build syllable pattern (longest-first ordering)
-- -- 	local pattern = string.format(
-- -- 		"^((%s)%.?)?%s+((%s)%.?)?$", -- Allow optional diacritic dots (.)
-- -- 		ONSET:gsub("(%a+)", "%%0"), -- Escape sequences
-- -- 		VOWEL,
-- -- 		CODA:gsub("(%a+)", "%%0")
-- -- 	)

-- -- 	-- Step 3: Check match and phonotactic rules
-- -- 	if not word:match(pattern) then
-- -- 		return false
-- -- 	end

-- -- 	-- Phonotactic constraints
-- -- 	if word:match("[g]ngh?[^ieê]") then
-- -- 		return false
-- -- 	end -- gh/ngh before i,e,ê
-- -- 	if word:match("ch?nh?[^ieê][ieê]?$") then
-- -- 		return false
-- -- 	end -- ch/nh after front vowels

-- -- 	return true
-- -- end

-- -- Vietnamese character sets
-- local ONSETS = CONSTANT.ONSETS
-- local CODAS = CONSTANT.CODAS
-- local FRONT_VOWELS = { -- Codepoints for i/e/ê and diacritics
-- 	0x69,
-- 	0xED,
-- 	0xEC,
-- 	0x1EC9,
-- 	0x129,
-- 	0x1ECB, -- i
-- 	0x65,
-- 	0xE9,
-- 	0xE8,
-- 	0x1EBB,
-- 	0x1EBD,
-- 	0x1EB9, -- e
-- 	0xEA,
-- 	0x1EBF,
-- 	0x1EC1,
-- 	0x1EC3,
-- 	0x1EC5,
-- 	0x1EC7, -- ê
-- }
-- local FRONT_VOWELS_Y = { -- Includes y and diacritics
-- 	0x79,
-- 	0xFD,
-- 	0x1EF3,
-- 	0x1EF7,
-- 	0x1EF9,
-- 	0x1EF5, -- y
-- }

-- -- Precompute lookup tables
-- local front_vowel_set, front_vowel_y_set = {}, {}
-- for _, cp in ipairs(FRONT_VOWELS) do
-- 	front_vowel_set[cp] = true
-- end
-- for _, cp in ipairs(FRONT_VOWELS) do
-- 	front_vowel_y_set[cp] = true
-- end
-- for _, cp in ipairs(FRONT_VOWELS_Y) do
-- 	front_vowel_y_set[cp] = true
-- end

-- -- Sort for longest-match-first

-- function is_vietnamese_word(word)
-- 	-- Empty word check
-- 	if #word == 0 then
-- 		return false
-- 	end

-- 	-- Iterate through all onset possibilities
-- 	for _, onset in ipairs(ONSETS) do
-- 		if word:sub(1, #onset) == onset then
-- 			local rest = word:sub(#onset + 1)
-- 			if #rest == 0 then
-- 				break
-- 			end -- Vowel required

-- 			-- Check all coda possibilities
-- 			for _, coda in ipairs(CODAS) do
-- 				if #coda <= #rest and rest:sub(-#coda) == coda then
-- 					local vowel = rest:sub(1, #rest - #coda)

-- 					-- Validate onset-vowel rules
-- 					if onset == "gh" or onset == "ngh" then
-- 						local first_cp = utf8.codepoint(vowel, 1)
-- 						if not front_vowel_set[first_cp] then
-- 							goto next_coda -- Invalid vowel for gh/ngh
-- 						end
-- 					end

-- 					-- Validate vowel-coda rules
-- 					if coda == "ch" or coda == "nh" then
-- 						local last_cp = utf8.codepoint(vowel, -1)
-- 						if not front_vowel_y_set[last_cp] then
-- 							goto next_coda -- Invalid coda position
-- 						end
-- 					end

-- 					return true -- Valid syllable
-- 				end
-- 				::next_coda::
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

-- -- Test function for batch validation
-- function test_vietnamese_words(words)
-- 	local results = {}
-- 	for i, word in ipairs(words) do
-- 		results[i] = { word = word, valid = is_vietnamese_word(word) }
-- 	end
-- 	return results
-- end

-- local process_diacritics = function(raw_word, method_config)
-- 	local converted = raw_word

-- 	for pattern, replacement in pairs(method_config.diacritic_map) do
-- 		converted = converted:gsub(pattern, replacement)
-- 	end
-- 	return converted
-- end

-- function M.process_raw_word(raw_word, inserted_char)
-- 	local method_config = M.get_method_config()
-- 	if type(method_config) ~= "table" then
-- 		return raw_word
-- 	elseif not should_process(inserted_char, raw_word, method_config) then
-- 		return raw_word
-- 	elseif not M.is_valid_sequence(raw_word) then
-- 		return raw_word
-- 	end

-- 	decompose_word(raw_word, method_config)

-- 	-- Process character conversions
-- 	local converted = process_diacritics(raw_word, method_config)

-- 	-- local converted = raw_word
-- 	-- for pattern, replacement in pairs(method_config.diacritic_map) do
-- 	-- 	converted = converted:gsub(pattern, replacement)
-- 	-- end

-- 	-- Process tones
-- 	-- return method.apgetmetatablejply_tones(converted)
-- end

-- function M.apply_tone(text)
-- 	local tone_char, tone_index, count
-- 	local tone_keys = TONE_CHARS.telex

-- 	-- Find tone character and its positions
-- 	local positions = {}
-- 	for i = #text, 1, -1 do
-- 		local c = text:sub(i, i)
-- 		if tone_keys:find(c) then
-- 			tone_char = c
-- 			tone_index = TONE_MAP.telex[c]
-- 			table.insert(positions, i)
-- 		end
-- 	end

-- 	if not tone_char then
-- 		return text
-- 	end
-- 	count = #positions

-- 	-- Remove all tone characters
-- 	local base_text = text:gsub("[" .. tone_keys .. "]", "")

-- 	-- Handle tone removal (double press)
-- 	if count > 1 then
-- 		return base_text .. string.rep(tone_char, count)
-- 	end

-- 	-- Apply tone to the appropriate vowel
-- 	local main_vowel = M.find_main_vowel(base_text)

-- 	if not main_vowel or not TONE_PLACEMENT[main_vowel] then
-- 		return text
-- 	end

-- 	local accented = TONE_PLACEMENT[main_vowel][tone_index]
-- 	return base_text:gsub(main_vowel, accented, 1)
-- end

function M.find_main_vowel(word)
	-- Find all vowels in the text
	local vowel_positions = {}
	local vowel_positions_len = 0
	for i = 1, strcharlen(word) do
		local char = strcharpart(word, i - 1, 1)
		if VOWELS:find(char) then
			vowel_positions_len = vowel_positions_len + 1
			vowel_positions[vowel_positions] = { pos = i, char = char }
		end
	end

	if vowel_positions_len == 0 then
		return nil
	elseif vowel_positions_len == 1 then
		return vowel_positions[1].char
	end

	-- Prefer the last vowel for certain vowel sequences
	local last_two = word:sub(-2)
	if last_two:match("[iuy]o") or last_two:match("[iuy]ơ") then
		return vowel_positions[vowel_positions_len].char
	end

	-- Special handling for common vowel sequences
	for _, seq in ipairs(VOWEL_SEQUENCES) do
		local start, end_pos = word:find(seq)
		if start then
			for j = start, end_pos do
				if VOWELS:find(word:sub(j, j)) then
					return word:sub(j, j)
				end
			end
		end
	end

	-- Default to the first vowel
	return vowel_positions[1].char
end

local reverse_tbl = function(tbl)
	local reversed = {}
	for i = #tbl, 1, -1 do
		reversed[#reversed + 1] = tbl[i]
	end
	return reversed
end

-- Helper to get text from a specific line and column range
local function get_buf_text(bufnr, row, start_col, end_col)
	-- Extract text between start_col and end_col on a given row
	local lines = vim.api.nvim_buf_get_text(bufnr, row, row, start_col, end_col, {})
	return lines[1] or ""
end

--- Get valid Vietnamese characters to the **left** of the cursor.
--- It fetches chunks of text from the left side, expanding by THRESHOLD_WORD_LEN each time.
--- It collects characters that are valid Vietnamese letters and stops when a non-Vietnamese char is found.
--- @param bufnr number: Buffer number
--- @param row_0based number: Cursor row (0-based)
--- @param col_0based number: Cursor column (0-based)
--- @return table: Reversed list of left characters (from closest to furthest from cursor)
--- @return number: Length of left_chars collected
local function get_left_chars(bufnr, row_0based, col_0based)
	local left_chars_reversed = {} -- Table to store characters we collect
	local left_chars_reversed_len = 0 -- Length of the left_chars_reversed table
	local batch = 0 -- Number of times we expanded further left

	repeat
		-- Calculate new start and end for reading more characters on the left
		local start_col = math.max(0, col_0based - THRESHOLD_WORD_LEN * (batch + 1))
		local end_col = col_0based - THRESHOLD_WORD_LEN * batch

		-- Get the text from start_col to end_col

		local left_text = nvim_buf_get_text(bufnr, row_0based, start_col, row_0based, end_col, {})[1]
		if not left_text or left_text == "" then
			break
		end
		local char_len = strcharlen(left_text)

		-- Walk backwards from the end of this segment
		for i = char_len - 1, 0, -1 do
			-- Get the i-th character from the end
			local ch = strcharpart(left_text, i, 1)
			-- If it's a Vietnamese character, prepend it to the result table
			if is_vietnamese_char(ch) then
				left_chars_reversed_len = left_chars_reversed_len + 1
				left_chars_reversed[left_chars_reversed_len] = ch
			else
				-- If it's not valid, stop collecting
				return reverse_tbl(left_chars_reversed), left_chars_reversed_len
			end

			-- Stop if we've already collected enough characters
			if left_chars_reversed_len >= THRESHOLD_WORD_LEN then
				return reverse_tbl(left_chars_reversed), left_chars_reversed_len
			end
		end

		-- If we hit beginning of line, stop
		if start_col == 0 then
			break
		end

		-- Go one batch further left
		batch = batch + 1

	until left_chars_reversed_len >= THRESHOLD_WORD_LEN

	return reverse_tbl(left_chars_reversed), left_chars_reversed_len
end

--- Get the character under cursor and valid Vietnamese characters to the **right**.
-- Reads the buffer line from cursor and moves rightward batch by batch.
-- Stops at first non-Vietnamese character or when THRESHOLD is reached.
-- @param bufnr number: Buffer number
-- @param row_0based number: Row of cursor (0-indexed)
-- @param col_0based number: Column of cursor (0-indexed)
-- @return table: List of valid Vietnamese characters to the right
-- @return number: Number of right characters
-- @return string: Character directly under the cursor
local function get_cusor_char_and_right_chars(bufnr, row_0based, col_0based)
	local cursor_char = ""
	local right_chars = {}
	local right_chars_len = 0 -- Length of the right_chars table
	local batch = 0 -- Number of times we expanded further right

	repeat
		local start_col = col_0based + THRESHOLD_WORD_LEN * batch
		local end_col = col_0based + THRESHOLD_WORD_LEN * (batch + 1)
		local right_text = nvim_buf_get_text(bufnr, row_0based, start_col, row_0based, end_col, {})[1]

		if not right_text or right_text == "" then
			break -- No more text to the right
		end

		local char_len = strcharlen(right_text)

		local start = 0
		if batch == 0 then
			cursor_char = strcharpart(right_text, 0, 1)
			start = 1 -- Start from the second character
		end
		for i = start, char_len - 1 do
			local ch = strcharpart(right_text, i, 1)

			-- If it's a Vietnamese character, add to result
			if is_vietnamese_char(ch) then
				right_chars_len = right_chars_len + 1
				right_chars[right_chars_len] = ch
			else
				return right_chars, right_chars_len, cursor_char
			end

			-- Stop if we've already collected enough characters
			if right_chars_len >= THRESHOLD_WORD_LEN then
				return right_chars, right_chars_len, cursor_char
			end
		end

		-- Go one batch further right
		batch = batch + 1

	until right_chars_len >= THRESHOLD_WORD_LEN

	return right_chars, right_chars_len, cursor_char
end

--- Main function to extract a processable Vietnamese word under cursor.
--- Combines characters from left of the cursor, the cursor character itself, and characters to the right.
--- Checks thresholds and rules to avoid collecting too many characters or empty segments.
--- @param bufnr number: Buffer number
--- @param row_0based number: Row of the cursor (0-based)
--- @param col_0based number: Column of the cursor (0-based)
--- @param excluded_cursor_char string: (Optional) Char to skip (used if we already handled cursor position)
--- @param had_left_chars boolean: If true, and no left chars found → return nil
--- @return table|nil: WordBuffer object containing the word characters, cursor position, and length
function M.get_processable_word(bufnr, row_0based, col_0based, had_left_chars)
	-- Get both sides of the word
	local left_chars, left_chars_len = get_left_chars(bufnr, row_0based, col_0based)
	if left_chars_len == THRESHOLD_WORD_LEN then
		return nil
	elseif had_left_chars and left_chars_len == 0 then
		return nil
	end
	local right_chars, right_chars_len, cursor_char = get_cusor_char_and_right_chars(bufnr, row_0based, col_0based)

	if left_chars_len + right_chars_len >= THRESHOLD_WORD_LEN then
		return nil
	elseif left_chars_len == 0 and right_chars_len == 0 then
		return nil
	end

	local word_chars = {}
	for i = 1, left_chars_len do
		word_chars[i] = left_chars[i]
	end
	local cursor_char_pos = left_chars_len + 1
	word_chars[cursor_char_pos] = cursor_char

	for i = 1, right_chars_len do
		word_chars[cursor_char_pos + i] = right_chars[i]
	end

	return require("vietnamese.WordBuffer").new(word_chars, cursor_char_pos, left_chars_len + 1 + right_chars_len)
end

--- Get a list of Vietnamese characters excluding the cursor character.
---
--- This function is used to get the word characters without the cursor character.
---
--- @param word_chars table: List of characters forming the word_chars
--- @param cursor_char_pos number: 1-based position of the cursor character in the word_chars
--- @return table: List of characters excluding the cursor characters
local function get_exclued_cursor_char_words(word_chars, cursor_char_pos)
	local result = {}
	for i, char in ipairs(word_chars) do
		if i ~= cursor_char_pos then
			result[#result + 1] = char
		end
	end
	return result
end

M.setup = function(config)
	local inserted_char = ""
	local inserting = false

	api.nvim_create_autocmd({
		"InsertCharPre",
		"TextChangedI",
	}, {
		callback = function(args)
			if args.event == "InsertCharPre" then
				inserted_char = vim.v.char
				inserting = true
				return
			elseif not inserting then
				return
			end
			inserting = false -- Reset inserting state

			local bufnr = 0
			local pos = nvim_win_get_cursor(0)
			local row_0based = pos[1] - 1 -- Row is 0-indexed in API
			local col_0based = pos[2] -- Column is 0-indexed
			-- check if is yank
			local word_chars, cursor_char_pos = M.get_processable_word(bufnr, row_0based, col_0based, true)
			vim.notify(
				vim.inspect({ word_chars, cursor_char_pos }),
				vim.log.levels.INFO,
				{ title = "Vietnamese Input Debug" }
			)

			if not word_chars or #word_chars == 0 then
				return
			elseif not should_process_diacritic_tone(inserted_char, M.get_method_config()) then
				return
			end

			inserted_char = "" -- Reset inserted character

			-- local processed = M.process_raw_word(raw_text, inserted_char)

			-- if not processed or processed == raw_text then
			-- 	return
			-- end

			-- -- Save cursor position relative to word
			-- local relative_pos = col - word_start

			-- vim.api.nvim_buf_set_text(0, row, word_start, row, word_end, { processed })

			-- -- Restore cursor position
			-- local new_length = #processed
			-- local new_cursor_col = math.min(word_start + relative_pos, word_start + new_length)
			-- vim.api.nvim_win_set_cursor(0, { row + 1, new_cursor_col })
		end,
	})
end

return M
