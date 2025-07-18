local vim = vim
local api = vim.api
local nvim_buf_get_text = api.nvim_buf_get_text
local str_utf_pos = vim.str_utf_pos
local string_char = string.char

local CONSTANT = require("vietnamese.constant")
local Diacritic, UTF8_VNCHAR_COMPONENT, DIACRITIC_MAP, VOWEL_PRIORITY =
	CONSTANT.Diacritic, CONSTANT.UTF8_VNCHAR_COMPONENT, CONSTANT.DIACRITIC_MAP, CONSTANT.VOWEL_PRIORITY

local M = {}

--- Reverse a table in place
--- @param tbl table: Table to reverse
--- @param len integer: Optional length of the table to reverse (default is #tbl)
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

local function concat_tight_range(list, i, j, list_size)
	i = i or 1
	j = j or list_size or #list

	local len = j - i + 1
	if len < 1 then
		error("Invalid range: " .. i .. " to " .. j)
	elseif len == 1 then
		return list[i]
	elseif len == 2 then
		return list[i] .. list[j]
	elseif len == 3 then
		return list[i] .. list[i + 1] .. list[j]
	elseif len < 31 then
		return table.concat(list, "", i, j)
	end

	local buf = {}
	for k = i, j do
		buf[#buf + 1] = list[k]
	end
	return table.concat(buf)
end
M.concat_tight_range = concat_tight_range

--- Convert a string to a table of characters
--- @param str string: The string to Convert
--- @return table: A table containing the characters of the starting
--- @return number: The length of the character table
function M.str2chars(str)
	local chars = {}
	local pos = str_utf_pos(str)
	local len = #pos

	-- hoisting
	local start, start_next
	for i = 1, len do
		start, start_next = pos[i], pos[i + 1]
		chars[i] = str:sub(start, start_next ~= nil and start_next - 1 or #str)
	end
	return chars, len
end

--- Get the UTF-8 positions of characters in a string
--- @param str string: The string to get positions from
--- @return fun(): (number|nil, string|nil) An iterator function that returns the start position of each character
--- @return integer: The length of the position table
--- and the character itself
--- This function is used to iterate over the characters in a string
function M.iter_chars(str)
	local pos = str_utf_pos(str)
	local len = #pos
	local i = 0
	return function()
		i = i + 1
		if i > len then
			return nil, nil
		end
		local start_idx = pos[i]
		local start_next = pos[i + 1]
		return i, str:sub(start_idx, start_next ~= nil and start_next - 1 or #str)
	end,
		len
end

--- Iterate over characters in a string in reverse ordered
--- @param str string: The string to iterate over
--- @return fun(): (number|nil, string|nil, number|nil) An iterator function that returns the index, character, and position
--- @return integer: The length of the position table
--- index: The index start from 1 of the character in the string
--- string: The character at the current index
--- real_index: The real index of the character in the string
function M.iter_chars_reverse(str)
	local pos = str_utf_pos(str)
	local len = #pos
	local i = len + 1
	return function()
		i = i - 1
		if i < 1 then
			return nil, nil, nil
		end
		local start_idx = pos[i]
		local start_next = pos[i + 1]
		return len - i + 1, str:sub(start_idx, start_next ~= nil and start_next - 1 or nil), i
	end,
		len
end

--- Convert a character to lowercase
--- @param c string: The character to convert
--- @return string: The lowercase version of the character
local function lower_char(c)
	local len = #c
	if len == 1 then
		local byte = c:byte()
		if byte > 64 and byte < 91 then
			return string_char(byte + 32) -- Convert uppercase ASCII to lowercase
		end
		return c
	elseif len == 2 or len == 3 then
		local comp = UTF8_VNCHAR_COMPONENT[c]
		return comp and comp.lo or c
	elseif len == 0 or len == 4 then
		return c
	end
	error("Invalid character length: " .. len .. " for character: " .. c)
end
M.lower_char = lower_char

--- Convert a string to lowercase
--- @param word string The string to Convert
--- @return string The lowercase version of the starting
local function lower(word)
	local iter, len = M.iter_chars(word)
	if len == 1 then
		return lower_char(word)
	elseif len == 0 then
		return ""
	end

	local chars = {}
	for i, c in iter do
		chars[i] = lower_char(c)
	end
	return concat_tight_range(chars)
end
M.lower = lower

--- Check if a character is uppercase
--- @param c string The character to checks
--- @return boolean True if the character is uppercase, false otherwise
function M.is_lower(c)
	assert(c, "c must not be nil")
	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp then
		return c:match("^[a-z]$") ~= nil
	end
	return comp.lo == c
end

--- Convert a character to uppercase
--- @param c string: The character to Convert
--- @return string uppered_char The uppercase version of the characters
--- @see M.upper
local function upper_char(c)
	local len = #c
	if len == 1 then
		local byte = c:byte()
		if byte > 96 and byte < 123 then
			return string_char(byte - 32) -- Convert lowercase ASCII to uppercase
		end
		return c:upper()
	elseif len == 2 or len == 3 then
		local comp = UTF8_VNCHAR_COMPONENT[c]
		return comp and comp.up or c
	elseif len == 0 or len == 4 then
		return c
	end
	error("Invalid character length: " .. len .. " for character: " .. c)
end

--- Convert a string to uppercase
--- @param word string The string to Convert
--- @return string The uppercase version of the starting
function M.upper(word)
	local iter, len = M.iter_chars(word)
	if len == 0 then
		return ""
	elseif len < 2 then
		return upper_char(word)
	end
	local chars = {}
	for i, char in iter do
		chars[i] = upper_char(char)
	end
	return concat_tight_range(chars)
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
	return comp.up == c
end

--- Get the level of a Vietnamese character
--- @param c string The character to check
--- @param level 1|2 The level to check (1 or 2)
--- @return string The character at the specified level, or the original character if not found
local level = function(c, level)
	local comp = UTF8_VNCHAR_COMPONENT[c]
	return comp and comp[level] or c
end
M.level = level

--- Decompose a Vietnamese character into its base character, diacritic, shape diacritic, and tone
--- @param c string The character to decompose_char
--- @return string The base character at level 1
--- @return string The character at level 2
--- @return Diacritic|nil The shape diacritic if it exists, or nil if not
--- @return Diacritic|nil The tone if it exists, or nil if not
local function decompose_char(c)
	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp then
		return c, c, nil, nil
	end
	return comp[1], comp[2], comp.shape, comp.tone
end
M.decompose_char = decompose_char

--- Check if a character is a Vietnamese vowel
--- @param c string The character to check
--- @param strict boolean|nil If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @return boolean is_vowel True if the character is a Vietnamese vowel, false otherwise
local function is_vietnamese_vowel(c, strict)
	if #c > 3 then
		return false
	elseif strict then
		return VOWEL_PRIORITY[lower_char(c)] ~= nil
	elseif UTF8_VNCHAR_COMPONENT[c] and c ~= "đ" and c ~= "Đ" then
		-- all utf8 vowel characters are considered Vietnamese vowels
		return true
	end
	--- ascii vơwel
	return VOWEL_PRIORITY[c:lower()] ~= nil
end
M.is_vietnamese_vowel = is_vietnamese_vowel

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
	local len = #char
	if len == 1 then
		-- ascii check
		local byte = char:byte()
		return (byte > 96 and byte < 123) -- a-z
			or (byte > 64 and byte < 91) -- A-Z
	elseif len < 1 or len > 3 then
		return false
	end
	-- check for all 2-byte and 3-byte Vietnamese characters
	return UTF8_VNCHAR_COMPONENT[char] ~= nil
end

--- Check if a character has a tone
--- @param c string The character to check
--- @return boolean True if the character has a tone, false otherwise
local has_tone_marked = function(c)
	local len = #c
	if len < 2 or len > 3 then
		-- an ascii character or a 4-byte character
		return false
	end
	local comp = UTF8_VNCHAR_COMPONENT[c]
	return comp ~= nil and comp.tone ~= nil
end
M.has_tone_marked = has_tone_marked

--- Strip the tone from a character
--- @param c string The character to strip the tone from
--- @return string lv2_c The character without the tone (lv2 char), or the original character if no tone was found
--- @return Diacritic|nil removed_tone The tone if it was stripped, or nil if no tone was found
local strip_tone = function(c)
	local len = #c
	if len < 2 or len > 3 then
		-- skip ascii characters or 4-byte characters
		return c, nil
	end

	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp then
		return c, nil
	end
	return comp[2], comp.tone
end

M.strip_tone = strip_tone
--- Check if a character has a shape
--- @param c string The character to checks
--- @return boolean True if the character has a shape, false otherwise
M.has_shape = function(c)
	local len = #c
	if len < 2 or len > 3 then
		return false
	end
	local comp = UTF8_VNCHAR_COMPONENT[c]
	return comp ~= nil and comp.shape ~= nil
end

--- Strip the shape from a Vietnamese character
--- @param c string The character to strip the shape from
--- @return string removed_shape_char The character without the shape (level 1 character), or the original character if no shape was find_vowel_seq_bounds
--- @return Diacritic|nil stripped_shape The shape of the character if it exists, or nil if notify
M.strip_shape = function(c)
	local len = #c
	if len < 2 or len > 3 then
		-- skip ascii characters or 4-byte characters
		return c, nil
	end

	local comp = UTF8_VNCHAR_COMPONENT[c]
	if not comp or not comp.shape then
		return c, nil
	end

	local lv1 = comp[1]
	local diacritic_map = DIACRITIC_MAP[lv1]
	local curr_tone = comp.tone
	if diacritic_map and curr_tone then
		-- restore the tone if it exists
		return diacritic_map[curr_tone] or c, comp.shape
	end
	return lv1, comp.shape
end

--- Attach a tone to a level 2 Vietnamese character
--- @param lv2_c string The level 2 character to attach the tone to
--- @param tone Diacritic The tone to attach_tone_to_lv2_char
--- @return string The character with the attached tone, or the original character if no tone was found
--- @return boolean True if the tone was successfully attached, false otherwise
M.merge_tone_lv2 = function(lv2_c, tone)
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
	if Diacritic.is_flat(diacritic) then
		return strip_tone(c)
	end
	local is_tone = Diacritic.is_tone(diacritic)
	local lv1, lv2, shape, tone = decompose_char(c)
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

--- Check if a character is unique tone marked in a range of characters
--- @param chars table The character Table
--- @param chars_size integer The size of the character Table
--- @param i integer|nil The starting index (1-based)
--- @param j integer|nil The ending index (1-based)
--- @return boolean unique True if there is at most one tone marked character in the range, false otherwise
M.unique_tone_marked = function(chars, chars_size, i, j)
	local found = false
	for k = (i or 1), (j or chars_size) do
		if has_tone_marked(chars[k]) then
			if found then
				return false
			end
			found = true
		end
	end
	return true
end

--- Get the tone mark of a character
--- @param c string The character to get the tone mark from
--- @return Diacritic|nil The tone mark if it exists, or nil if not
M.get_tone_mark = function(c)
	local len = #c
	if len < 2 or len > 3 then
		return nil
	end

	local dict = UTF8_VNCHAR_COMPONENT[c]
	return dict and dict.tone
end

--- Get the shape of a character
--- @param c string The character to get the shape from
--- @return Diacritic|nil The shape of the character if it exists, or nil if notify
M.get_shape = function(c)
	local len = #c
	if len < 2 or len > 3 then
		return nil
	end
	local dict = UTF8_VNCHAR_COMPONENT[c]
	return dict and dict.shape
end

M.strip_diacritics = function(c)
	local len = #c
	if len < 2 or len > 3 then
		-- skip ascii characters or 4-byte characters
		return c, nil, nil
	end
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
local function find_vowel_seq_bounds(chars, chars_size)
	local first, last = -1, -2

	-- Find the first and last vowel in the character table
	for i = 1, chars_size do
		if is_vietnamese_vowel(chars[i]) then
			first = i

			for j = chars_size, i, -1 do
				if is_vietnamese_vowel(chars[j]) then
					last = j
					break
				end
			end

			break
		end
	end
	return first, last, first == last
end
M.find_vowel_seq_bounds = find_vowel_seq_bounds

--- Check if a sequence of characters is a potential vowel sequence
--- @param chars table The character Table
--- @param chars_size integer The size of the character Table
--- @param strict boolean|nil If true, checks for strict Vietnamese vowels (no accept tone char like "á", "à", etc.)
--- @return boolean True if the sequence is a potential vowel sequence, false otherwise
function M.is_potential_vowel_seq(chars, chars_size, strict)
	local start, stop = find_vowel_seq_bounds(chars, chars_size)
	local len = stop - start + 1
	if len < 1 or len > 3 then
		return false
	end

	return len == 3 and is_vietnamese_vowel(chars[start + 1], strict) or true
end

--- Check if at least one character in the list is a Vietnamese vowel
--- @param chars table the list of characters to check
--- @return boolean true if at least one character is a vowel, false otherwise
function M.some_vowels(chars, chars_size, strict)
	for i = 1, chars_size do
		local c = chars[i]
		if is_vietnamese_vowel(c, strict) then
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
	for k = (i or 1), (j or chars_size) do
		if not is_vietnamese_vowel(chars[k], strict) then
			return false
		end
	end
	return true
end

local two_repetition_chars = {
	["o"] = true,
	["u"] = true,
	["c"] = true,
	["n"] = true,
	["m"] = true,
	["g"] = true,
	["h"] = true,
	["p"] = true,
	["t"] = true,
}
local function get_max_repetition_time(char)
	if char == nil or char == "" then
		return "", 0
	end
	local lv1_c = lower_char(level(char, 1))
	return lv1_c, two_repetition_chars[lv1_c] and 2 or 1
end

--- Check if the repetition of vowels in a character sequence exceeds the maximum allowed repetition 13:44
--- @param chars table The character Table
--- @param chars_size integer The size of the character table
--- @param i integer|nil The starting index (1-based)
--- @param j integer|nil The ending index (1-based)
--- @return boolean True if the repetition exceeds the maximum allowed, false otherwise
function M.exceeded_repetition_time(chars, chars_size, i, j)
	local times = {}
	local lv1c, time, curr_time
	for k = (i or 1), (j or chars_size) do
		lv1c, time = get_max_repetition_time(chars[k])
		curr_time = (times[lv1c] or 0) + 1
		if curr_time > time then
			return true
		end
		times[lv1c] = curr_time
	end
	return false
end

--- Copy a list to a new list
--- @param list table: The list to copy_list
--- @return table: A new list containing the same elements as the original copy_list
function M.copy_list(list, list_size)
	local new_list = {}
	for i = 1, list_size or #list do
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

--- Check if a character is "d" or "đ" or "D" or "Đ"
--- @param char string: The character to check
--- @return boolean: True if the character is "d" or "đ" or "D" or "Đ", false otherwise
function M.is_d(char)
	return char == "d" or char == "đ" or char == "D" or char == "Đ"
end

function M.is_lower_uo(u, o)
	if u == "u" or u == "ư" then
		return o == "o" or o == "ơ" or o == "ô"
	end
	return false
end

--- Sort a list using insertion sorts
--- @param list table: The list to sort
--- @param list_size integer: The size of the list to sort
--- @param cmp function: A comparison function that takes two elements and returns true if the first element should come after the second
--- @return table sorted_list The sorted list
function M.isort_b2(list, list_size, cmp)
	if list_size == 2 then
		if cmp(list[1], list[2]) then
			list[1], list[2] = list[2], list[1]
		end
	end

	for i = 2, list_size do
		local key = list[i]
		local j = i - 1

		while j > 0 and cmp(list[j], key) do
			list[j + 1] = list[j]
			j = j - 1
		end
		list[j + 1] = key
	end
	return list
end

--- Calculate the byte length of a range of characters
--- @param chars string[]: The character Table
--- @param chars_size integer: The size of the character table
--- @param i integer|nil: The starting index (1-based)
--- @param j integer|nil: The ending index (1-based)
function M.byte_len(chars, chars_size, i, j)
	local len = 0
	for k = i or 1, j or chars_size do
		len = len + #chars[k]
	end
	return len
end

function M.benchmark(func, ...)
	---@diagnostic disable-next-line: undefined-field
	local start_time = vim.uv.hrtime()
	local result = { func(...) }
	---@diagnostic disable-next-line: undefined-field
	local end_time = vim.uv.hrtime()
	local elapsed_time = (end_time - start_time) / 1e6 -- Convert to milliseconds

	-- print to file
	local path = "/home/stilux/Data/Workspace/neovim-plugins/vietnamese.nvim/lua/benchmark.log"
	local file = io.open(path, "a")
	if file then
		file:write(string.format("Benchmark: %s took %.2f ms\n", func, elapsed_time))
		file:close()
	end

	-- print to vim notify

	-- vim.notify(string.format("Benchmark: %s took %.2f ms", func, elapsed_time), vim.log.levels.INFO, {
	-- 	title = "Vietnamese Utils Benchmark",
	-- })
	---@diagnostic disable-next-line: deprecated
	return unpack(result)
end

return M
