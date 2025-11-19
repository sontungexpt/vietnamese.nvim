local vim = vim
local nvim_buf_get_text, str_utf_pos = vim.api.nvim_buf_get_text, vim.str_utf_pos

local Codec = require("vietnamese.util.codec")
local lower_char = Codec.lower_char

local M = {}

--- Reverse a table in place
--- @param tbl table: Table to reverse
--- @param len integer: Optional length of the table to reverse (default is #tbl)
--- @return table reversed Reversed table
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

--- Convert a string to lowercase
--- @param word string The string to Convert @return string The lowercase version of the starting
M.lower = function(word)
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
	return table.concat(chars)
end

--- Convert a string to uppercase
--- @param word string The string to Convert
--- @return string The uppercase version of the starting
function M.upper(word)
	local iter, len = M.iter_chars(word)
	local upper_char = Codec.upper_char

	if len == 0 then
		return ""
	elseif len < 2 then
		return upper_char(word)
	end
	local chars = {}
	for i, char in iter do
		chars[i] = upper_char(char)
	end
	return table.concat(chars)
end

--- Get the byte offset of a column in a row of buffers
--- @param bufnr number: Buffer number
--- @param row0 integer: Line number (0-based)
--- @param col0 integer  Column number (0-based)
--- @return integer : Byte offset of the column in the line
function M.col_to_byteoffset(bufnr, row0, col0)
	--- api nvim_win_Get_cursor also return byteoffset
	--- byteoffset is start from 0
	return #(nvim_buf_get_text(bufnr, row0, 0, row0, col0, {})[1] or "")
end

--- Convert a column index to a cell index in a buffer
--- @param bufnr number: Buffer number
--- @param row0 integer: Row number (0-based)
--- @param col0 integer: Column number (0-based)
--- @return integer: Cell index of the column in the line
function M.col_to_cell_idx(bufnr, row0, col0)
	--- byteoffset is start from 0
	return vim.fn.strdisplaywidth((nvim_buf_get_text(bufnr, row0, 0, row0, col0, {})[1] or ""))
end

--- Sort a list using insertion sorts
--- @param list table: The list to sort
--- @param list_size integer: The size of the list to sort
--- @param cmp function: A comparison function that takes two elements and returns true if the first element should come after the second
--- @return table sorted_list The sorted list
function M.insertion_sort(list, list_size, cmp)
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
	local start_time = vim.uv.hrtime()
	local result = { func(...) }
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
	return unpack(result)
end

return M
