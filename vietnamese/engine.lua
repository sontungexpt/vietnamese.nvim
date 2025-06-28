local vim = vim
local api = vim.api
local nvim_win_get_cursor, nvim_win_set_cursor, nvim_buf_set_text, nvim_buf_get_text =
	api.nvim_win_get_cursor, api.nvim_win_set_cursor, api.nvim_buf_set_text, api.nvim_buf_get_text

local require = require
local util = require("vietnamese.util")
local config = require("vietnamese.config")
local is_vietnamese_char = util.is_vietnamese_char
local reverse_tbl = util.reverse_list
local iter_chars = util.iter_chars
local iter_chars_reverse = util.iter_chars_reverse

local METHOD_CONFIG_PATH = "vietnamese.method."

-- assuming the worst case word length is 18 characters
-- each Vietnamese character can take 2 cells
-- The max valid Vietnamese word length is 8 characters but we add 2 cells to assure that the word
-- will be get accurate
local THRESHOLD_WORD_LEN = 8
local WORST_CASE_WORD_LEN = THRESHOLD_WORD_LEN * 2 + 2

local SUPPORTED_METHODS = {
	telex = true,
	vni = true,
}

-- vietnamese_input/engine.lua
local M = {}

--- Check if a character is a valid input character for the current method
local function is_diacritic_pressed(char, method_config)
	if type(method_config.is_diacritic_pressed) == "function" then
		return method_config.is_diacritic_pressed(char)
	end
	local method_util = require("vietnamese.util.method-config")
	if method_util.is_tone_key(char, method_config) then
		return true
	elseif method_util.is_tone_removal_key(char, method_config) then
		return true
	elseif method_util.is_shape_key(char, method_config) then
		return true
	end
	return false
end

function M.get_config()
	return config.get_config()
end

function M.get_method_config()
	local user_config = M.get_config()
	local current_method = user_config.input_method

	local method_config = SUPPORTED_METHODS[current_method] and require(METHOD_CONFIG_PATH .. current_method)
		or user_config.custom_methods[current_method]

	if type(method_config) ~= "table" then
		require("vietnamese.notifier").error(
			"Invalid method configuration for '" .. current_method .. "'. Please check your configuration."
		)
		return nil
	end

	return method_config
end

function M.set_input_method(method)
	require("vietnamese.config").set_input_method(method)
end

function M.get_input_method()
	return require("vietnamese.config").input_method
end

--- Get valid Vietnamese characters to the **left** of the cursor.
--- It fetches chunks of text from the left side, expanding by THRESHOLD_WORD_LEN each time.
--- It collects characters that are valid Vietnamese letters and stops when a non-Vietnamese char is found.
--- If the cursor is at the tail of a Vietnamese word, it includes the cursor character.
---
--- @param bufnr number: Buffer number
--- @param row_0based number: Cursor row (0-based)
--- @param col_0based number: Cursor column (0-based)
--- @return table: Reversed list of left characters (from closest to furthest from cursor)
--- @return number: Length of left_chars collected
local function collect_left_chars(bufnr, row_0based, col_0based, inserting)
	-- Get the text from start_col to end_col
	local text_chunk = nvim_buf_get_text(
		bufnr,
		row_0based,
		col_0based - WORST_CASE_WORD_LEN > 0 and col_0based - WORST_CASE_WORD_LEN or 0,
		row_0based,
		col_0based,
		{}
	)[1]
	if not text_chunk or text_chunk == "" then
		return {}, 0
	end

	local collected_chars = {} -- Table to store characters we collect
	local count = 0 -- Length of the left_chars_reversed table

	for i, ch in iter_chars_reverse(text_chunk) do
		if inserting and i == 1 then
			collected_chars[1] = ch
			count = 1
		elseif is_vietnamese_char(ch) then
			count = count + 1
			collected_chars[count] = ch
		else
			break -- Stop collecting if we hit a non-Vietnamese character
		end

		if count == THRESHOLD_WORD_LEN then
			break
		end
	end

	return reverse_tbl(collected_chars, count), count
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
local function collect_right_chars_from_cursor(bufnr, row_0based, col_0based)
	local text_chunk =
		nvim_buf_get_text(bufnr, row_0based, col_0based, row_0based, col_0based + WORST_CASE_WORD_LEN, {})[1]
	if not text_chunk or text_chunk == "" then
		return {}, 0
	end

	local collected_chars = {}
	local count = 0
	for _, ch in iter_chars(text_chunk) do
		if is_vietnamese_char(ch) then
			count = count + 1
			collected_chars[count] = ch
		else
			break -- Stop collecting if we hit a non-Vietnamese character
		end
		if count == THRESHOLD_WORD_LEN then
			break -- Stop if we reach the threshold
		end
	end

	return collected_chars, count
end

--- Main function to extract a processable Vietnamese word under cursor.
--- Combines characters from left of the cursor, the cursor character itself, and characters to the right.
--- Checks thresholds and rules to avoid collecting too many characters or empty segments.
--- @param bufnr number: Buffer number
--- @param row_0based number: Row of the cursor (0-based)
--- @param col_0based number: Column of the cursor (0-based)
--- @return WordEngine|nil: CursorWord object containing the word
function M.find_vnword_under_cursor(bufnr, row_0based, col_0based, inserting)
	-- Get both sides of the word
	local left_chars, left_len = collect_left_chars(bufnr, row_0based, col_0based, inserting)
	if left_len == THRESHOLD_WORD_LEN then
		return nil
	elseif inserting and left_len < 2 then
		return nil
	elseif left_len < 1 then
		return nil
	end

	local right_chars, right_len = collect_right_chars_from_cursor(bufnr, row_0based, col_0based)

	local word_len = left_len + right_len
	if word_len >= THRESHOLD_WORD_LEN then
		return nil
	end

	--- combine right to left to get full word
	local word_chars = left_chars
	for i = 1, right_len do
		word_chars[left_len + i] = right_chars[i]
	end

	return require("vietnamese.WordEngine"):new(word_chars, left_len + 1, inserting, word_len)
end

M.setup = function()
	local inserted_char = ""
	local inserting = false

	local col_before_insert = -1

	api.nvim_create_autocmd({
		"InsertCharPre",
		"TextChangedI",
	}, {
		callback = function(args)
			if not config.is_enabled() then
				return
			end
			if args.event == "InsertCharPre" then
				inserted_char = vim.v.char
				inserting = true
				local pos = nvim_win_get_cursor(0)
				col_before_insert = pos[2] -- Column is 0-indexed
				return
			elseif not inserting then
				-- we are removing characters, so we don't need to process
				return
			end
			--       -- If we are inserting, we need to process the character
			inserting = false -- Reset inserting state

			local method_config = M.get_method_config()

			if not is_diacritic_pressed(inserted_char, method_config) then
				return
			end

			local pos = nvim_win_get_cursor(0)
			local row = pos[1] -- Row is 1-indexed in API
			local row_0based = row - 1 -- Row is 0-indexed in API
			local col_0based = pos[2] -- Column is 0-indexed

			local cursor_word = M.find_vnword_under_cursor(args.buf, row_0based, col_0based, true)
			if
				not cursor_word
				or not cursor_word:is_potential_diacritic_key(inserted_char, M.get_method_config())
				or not cursor_word:is_potential_vnword()
			then
				return
			end
			local should_update = cursor_word:processes_diacritic(method_config)
			if not should_update then
				return
			end

			local new_word = cursor_word:tostring()

			-- -- Save cursor position relative to word
			-- local relative_pos = col - word_start

			local bytoffset_start, byteoffset_end = cursor_word:col_bounds(col_0based)

			nvim_buf_set_text(0, row_0based, bytoffset_start, row_0based, byteoffset_end, { new_word })

			local new_col_0based = cursor_word:get_curr_cursor_col(col_0based)
			if col_0based ~= new_col_0based then
				-- -- Restore cursor position
				nvim_win_set_cursor(0, { row, new_col_0based })
			end

			-- Notify the user about the processed word
			inserted_char = "" -- Reset inserted character
		end,
	})
end

return M
