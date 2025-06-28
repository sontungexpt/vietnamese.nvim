local vim = vim
local api = vim.api
local nvim_buf_get_text = api.nvim_buf_get_text
local tbl_concat = table.concat
local str_utf_pos = vim.str_utf_pos

local CONSTANT = require("vietnamese.constant")
local UTF8_VNCHAR_COMPONENT = CONSTANT.UTF8_VNCHAR_COMPONENT
local DIACRITIC_MAP = CONSTANT.DIACRITIC_MAP
local BASE_VOWEL_PRIORITY = CONSTANT.VOWEL_PRIORITY
local Diacritic = CONSTANT.Diacritic

local M = {}

--- Reverse a table in place
--- @param tbl table: Table to reverse
--- @param len number: Optional length of the table to reverse (default is #tbl)
--- @return table: Reversed table
M.reverse_list = function(tbl, len)
	len = len or #tbl
	if len < 2 then
		return tbl
	end

	for i = 1, len / 2, 1 do
		tbl[i], tbl[len - i + 1] = tbl[len - i + 1], tbl[i]
	end
	return tbl
end

--- Convert a string to a table of characters
--- @param str string: The string to Convert
--- @return table: A table containing the characters of the starting
--- @return number: The length of the character table
function M.str2chars(str)
	local chars = {}
	local pos = str_utf_pos(str)
	local len = #pos
	for i = 1, len do
		local start_i, start_in = pos[i], pos[i + 1]
		chars[i] = str:sub(start_i, start_in ~= nil and start_in - 1 or #str)
	end
	return chars, len
end

--- Get the UTF-8 positions of characters in a string
--- @param str string: The string to get positions from
--- @return fun(): (number|nil, string|nil) An iterator function that returns the start position of each character
--- and the character itself
--- This function is used to iterate over the characters in a string
function M.iter_chars(str)
	local pos = str_utf_pos(str)
	local i = 0
	return function()
		i = i + 1
		local start_idx = pos[i]
		if not start_idx then
			return nil, nil
		end
		local start_next = pos[i + 1]
		return i, str:sub(start_idx, start_next ~= nil and start_next - 1 or nil)
	end
end

--- Iterate over characters in a string in reverse ordered
--- @param str string: The string to iterate over
--- @return fun(): (number|nil, string|nil, number|nil) An iterator function that returns the index, character, and position
--- index: The index start from 1 of the character in the string
--- string: The character at the current index
--- real_index: The real index of the character in the string
function M.iter_chars_reverse(str)
	local pos = str_utf_pos(str)
	local len = #pos
	local i = len + 1
	return function()
		i = i - 1
		local start_idx = pos[i]
		if not start_idx then
			return nil, nil, nil
		end
		local start_next = pos[i + 1]
		return len - i + 1, str:sub(start_idx, start_next ~= nil and start_next - 1 or nil), i
	end
end

--- Convert a string to lowercase
--- @param word string The string to Convert
--- @return string The lowercase version of the starting
function M.lower(word)
	local chars = {}
	for i, char in M.iter_chars(word) do
		local comp = UTF8_VNCHAR_COMPONENT[char]
		chars[i] = comp and comp.lo or char:lower()
	end

	return tbl_concat(chars)
end

--- Check if a character is uppercase
--- @param c string The character to checks
--- @return boolean True if the character is uppercase, false otherwise
function M.is_lower(c)
	assert(c, "c must not be nil")
	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp then
		return c:match("^[a-z]$") ~= nil
	end
	return comp.lo ~= nil
end

--- Convert a string to uppercase
--- @param word string The string to Convert
--- @return string The uppercase version of the starting
function M.upper(word)
	local chars = {}
	for i, char in M.iter_chars(word) do
		local comp = UTF8_VNCHAR_COMPONENT[char]
		chars[i] = comp and comp.up or char:upper()
	end
	return tbl_concat(chars)
end

--- Check if a character is uppercase
--- @param c string The character to checks
--- @return boolean True if the character is uppercase, false otherwise
function M.is_upper(c)
	assert(c, "c must not be nil")
	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp then
		return c:match("^[A-Z]$") ~= nil
	end
	return comp.up ~= nil
end

--- Check if a character is a Vietnamese vowel
--- @param c string The character to check
--- @param strict boolean|nil If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @return boolean True if the character is a Vietnamese vowel, false otherwise
function M.is_vietnamese_vowel(c, strict)
	assert(c, "c must not be nil")
	c = strict and M.lower(c) or M.level(M.lower(c), 2)
	return BASE_VOWEL_PRIORITY[c] ~= nil
end

--- Check if a character is a level 1 Vietnamese vowel
--- @param c string The character to checks
--- @return boolean True if the character is a level 1 Vietnamese vowel, false otherwise
function M.is_level1_vowel(c)
	return c:match("^[aeiouyAEIOUY]$") ~= nil
end

--- Check if a character is a Vietnamese character
--- @param char string The character to check
--- @return boolean True if the character is a Vietnamese character, false otherwise
function M.is_vietnamese_char(char)
	if char == nil or char == "" then
		return false
	elseif UTF8_VNCHAR_COMPONENT[char] ~= nil then
		return true
	end
	return char:match("^%a$") ~= nil
end

--- Get the level of a Vietnamese character
--- @param c string The character to check
--- @param level 1|2 The level to check (1 or 2)
--- @return string The character at the specified level, or the original character if not found
M.level = function(c, level)
	assert(c, "c must not be nil")
	return UTF8_VNCHAR_COMPONENT[c] and UTF8_VNCHAR_COMPONENT[c][level] or c
end

--- Check if a character has a tone
--- @param c string The character to check
--- @return boolean True if the character has a tone, false otherwise
M.has_tone_marked = function(c)
	return UTF8_VNCHAR_COMPONENT[c] ~= nil and UTF8_VNCHAR_COMPONENT[c].tone ~= nil
end

--- Check if a character has a shape
--- @param c string The character to checks
--- @return boolean True if the character has a shape, false otherwise
M.has_shape = function(c)
	return UTF8_VNCHAR_COMPONENT[c] ~= nil and UTF8_VNCHAR_COMPONENT[c].shape ~= nil
end

M.strip_shape = function(c)
	assert(c, "c must not be nil")
	local dict = UTF8_VNCHAR_COMPONENT[c]
	if not dict or not dict.shape then
		return c, nil
	end
	local lv1 = dict[1]
	local diacritic_map = DIACRITIC_MAP[lv1]
	local curr_tone = dict.tone
	if diacritic_map and curr_tone then
		-- restore the tone if it exists
		return diacritic_map[curr_tone] or c, dict.shape
	end
	return lv1, dict.shape
end

--- Attach a tone to a level 2 Vietnamese character
--- @param lv2_c string The level 2 character to attach the tone to
--- @param tone Diacritic The tone to attach_tone_to_lv2_char
--- @return string The character with the attached tone, or the original character if no tone was found
--- @return boolean True if the tone was successfully attached, false otherwise
M.merge_tone_to_lv2_vowel = function(lv2_c, tone)
	assert(lv2_c ~= nil, "c must not be nil")
	assert(tone ~= nil, "tone must not be nil")
	local tone_map = DIACRITIC_MAP[lv2_c]

	if not tone_map then
		-- not a valid char
		return lv2_c, false
	end
	local result = tone_map[tone]
	return result or lv2_c, result ~= nil
end

--- Merge a diacritic into a character
--- @param c string The character to merge the diacritic into
--- @param diacritic Diacritic The diacritic to merge
--- @param force boolean|nil If true, forces the merge even if the diacritic is not applicable
--- @return string The character with the merged diacritic, or the original character if no merge was possible
--- @return Diacritic|nil The original diacritic if it was replaced, or nil if no replace was possible
M.merge_diacritic = function(c, diacritic, force)
	assert(c ~= nil, "c must not be nil")
	assert(diacritic ~= nil, "diacritic must not be nil")
	if Diacritic.is_flat(diacritic) then
		return M.strip_tone(c)
	end
	local is_tone = Diacritic.is_tone(diacritic)
	local lv1, lv2, shape, tone = M.decompose_char(c)
	if is_tone then
		local tone_map = DIACRITIC_MAP[lv2]
		if not tone_map then
			-- not a valid char
			return c, nil
		elseif not force and tone then
			-- had tone already, return original character
			return c, nil
		end
		-- return c if is d char
		return tone_map[diacritic] or c, tone
	end
	local shape_map = DIACRITIC_MAP[lv1]
	if not shape_map then
		-- not a valid char
		return c, nil
	elseif not force and shape then
		--- had shape already, return original character
		return c, nil
	end
	local shaped = shape_map[diacritic]
	if not shaped then
		-- not a valid diacritic for this char
		return c, nil
	elseif tone and DIACRITIC_MAP[shaped] then
		-- restore the tone if it exists
		return DIACRITIC_MAP[shaped][tone] or shaped, shape
	end
	return shaped, shape
end

M.unique_tone_marked = function(chars, chars_size, i, j)
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")
	i = i and i > 0 and i or 1
	j = j and j < chars_size and j or chars_size

	local count = 0
	for k = i, j do
		local c = chars[k]
		if M.has_tone_marked(c) then
			count = count + 1
		end
		if count > 1 then
			return false
		end
	end
	return true
end

--- Strip the tone from a character
--- @param c string The character to strip the tone from
--- @return string The character without the tone (lv2 char), or the original character if no tone was found
--- @return Diacritic|nil The tone if it was stripped, or nil if no tone was found
M.strip_tone = function(c)
	local dict = UTF8_VNCHAR_COMPONENT[c]
	if not dict then
		return c, nil
	end
	return dict[2], dict.tone
end

--- Get the tone mark of a character
--- @param c string The character to get the tone mark from
--- @return Diacritic|nil The tone mark if it exists, or nil if not
M.get_tone_mark = function(c)
	local dict = UTF8_VNCHAR_COMPONENT[c]
	if not dict then
		return nil
	end
	return dict.tone
end

M.strip_diacritics = function(c)
	local dict = UTF8_VNCHAR_COMPONENT[c]
	if not dict then
		return c, nil, nil
	end
	return dict[1], dict.shape, dict.tone
end

--- Find the first and last vowel positions in a character table
--- @param chars table The character table
--- @param chars_size integer The length of the character table
--- @return integer first The index of the first vowel (1-based)
--- @return integer last The index of the last vowel (1-based)
--- @return boolean is_single True if the first and last vowels are the same (single vowel), false otherwise
function M.find_vowel_seq_bounds(chars, chars_size)
	local first, last = -1, -2

	-- Find the first and last vowel in the character table
	for i = 1, chars_size do
		if M.is_vietnamese_vowel(chars[i]) then
			first = i
			break
		end
	end

	if first < 0 then
		return first, last, false
	end

	for i = chars_size, 1, -1 do
		if M.is_vietnamese_vowel(chars[i]) then
			last = i
			break
		end
	end

	return first, last, first == last
end

--- Get the conflict vowel code for a character
--- @param c string The character to get the conflict vowel code for
--- @return string The conflict vowel code, which is "a" if the character is "e" or "a", otherwise the character itself
function M.get_conflict_vowel_code(c)
	local lv1 = M.lower(M.level(c, 1))
	if lv1 == "a" or lv1 == "e" then
		-- a never combine with e, so return a
		return "a"
	end
	return c
end

--- Check if a sequence of characters is a potential vowel sequence
--- @param chars table The character Table
--- @param chars_size integer The size of the character Table
--- @param min_seq_len integer The minimum length of the vowel sequence
--- @param max_seq_len integer The maximum length of the vowel sequence @param strict boolean If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @param strict boolean|nil If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @return boolean True if the sequence is a potential vowel sequence, false otherwise
function M.is_potiental_vowel_seq(chars, chars_size, min_seq_len, max_seq_len, strict)
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")
	local start, stop = M.find_vowel_seq_bounds(chars, chars_size)
	local len = M.caculate_distance(start, stop)
	if len < min_seq_len or len > max_seq_len then
		return false
	elseif stop - 1 > start then
		return M.all_vowels(chars, chars_size, strict, start + 1, stop - 1)
	end
	return true
end

--- Check if at least one character in the list is a Vietnamese vowel
--- @param chars table the list of characters to check
--- @return boolean true if at least one character is a vowel, false otherwise
function M.some_vowels(chars, chars_size, strict)
	for i = 1, chars_size do
		local c = chars[i]
		if M.is_vietnamese_vowel(c, strict) then
			return true
		end
	end
	return false
end

--- Check if all characters from i to j are vowels
--- @param chars table The character table
--- @param chars_size integer The size of the character table
--- @param i integer The starting index (1-based)
--- @param j integer The ending index (1-based)
--- @return boolean True if all characters are vowels, false otherwise
function M.all_vowels(chars, chars_size, strict, i, j)
	assert(chars, "chars must not be nil")
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")

	for k = (i or 1), (j or chars_size) do
		if not M.is_vietnamese_vowel(chars[k], strict) then
			return false
		end
	end
	return true
end

function M.get_max_repetition_time(char)
	if char == nil or char == "" then
		return char, 0
	end

	local lv1_c = M.lower(M.level(char, 1))
	if lv1_c == "o" or lv1_c == "u" then
		return lv1_c, 2
	elseif lv1_c == "i" or lv1_c == "e" or lv1_c == "a" or lv1_c == "y" then
		return lv1_c, 1
	end
	-- consonant
	return lv1_c, 2
end

--- Check if the repetition of vowels in a character sequence exceeds the maximum allowed repetition 13:44
--- @param chars table The character Table
--- @param chars_size integer The size of the character table
--- @param i integer|nil The starting index (1-based)
--- @param j integer|nil The ending index (1-based)
--- @return boolean True if the repetition exceeds the maximum allowed, false otherwise
function M.is_exceeded_vowel_repetition_time(chars, chars_size, i, j)
	assert(chars_size and chars_size > 0, "chars_size must not be nil or less than 1")
	assert(j <= chars_size, "j must not be greater than chars_size")
	assert(i <= j and i > 0, "i must not be greater than j, and i must be greater than 0")

	local times = {}
	for k = (i or 1), (j or chars_size) do
		local level1_c, time = M.get_max_repetition_time(chars[k])
		local curr_time = (times[level1_c] or 0) + 1
		if curr_time > time then
			return true
		end
		times[level1_c] = curr_time
	end
	return false
end

--- Decompose a Vietnamese character into its base character, diacritic, shape diacritic, and tone
--- @param c string The character to decompose_char
--- @return string The base character at level 1
--- @return string The character at level 2
--- @return Diacritic|nil The shape diacritic if it exists, or nil if not
--- @return Diacritic|nil The tone if it exists, or nil if not
function M.decompose_char(c)
	assert(c, "c must not be nil")

	local dict = UTF8_VNCHAR_COMPONENT[c]
	if not dict then
		return c, c, nil, nil
	end
	return dict[1], dict[2], dict.shape, dict.tone
end

--- Copy a list to a new list
--- @param list table: The list to copy_list
--- @return table: A new list containing the same elements as the original copy_list
function M.copy_list(list)
	local new_list = {}
	for i = 1, #list do
		new_list[i] = list[i]
	end
	return new_list
end

--- Get the byte offset of a column in a row of buffers
--- @param bufnr number: Buffer number
--- @param row0based integer: Line number (0-based)
--- @param col0based integer  Column number (0-based)
--- @return integer : Byte offset of the column in the line
function M.col_to_byteoffset(bufnr, row0based, col0based)
	-- api nvim_win_Get_cursor also return byteoffset
	--- byteoffset is start from 0
	local byteoffset = #(nvim_buf_get_text(bufnr, row0based, 0, row0based, col0based, {})[1] or "")
	return byteoffset
end

--- Convert a column index to a cell index in a buffer
--- @param bufnr number: Buffer number
--- @param row0based integer: Row number (0-based)
--- @param col0based integer: Column number (0-based)
--- @return integer: Cell index of the column in the line
function M.col_to_cell_idx(bufnr, row0based, col0based)
	--- byteoffset is start from 0
	local cell_idx = vim.fn.strdisplaywidth((nvim_buf_get_text(bufnr, row0based, 0, row0based, col0based, {})[1] or ""))
	return cell_idx
end

--- Calculate the distance between two indicates
--- @param start_idex number: The starting index (1-based)
--- @param end_idx number: The ending index (1-based)
--- @return number: The distance between the two indicates
function M.caculate_distance(start_idex, end_idx)
	return end_idx - start_idex + 1
end

return M
