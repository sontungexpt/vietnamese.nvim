local vim, type = vim, type
local api, v, o = vim.api, vim.v, vim.o
local tbl_move = table.move

local nvim_win_set_cursor = api.nvim_win_set_cursor
local nvim_win_get_cursor = api.nvim_win_get_cursor
local nvim_buf_get_text = api.nvim_buf_get_text
local nvim_buf_set_text = api.nvim_buf_set_text
local nvim_create_autocmd = api.nvim_create_autocmd

--- module
local Codec = require("vietnamese.util.codec")
local Util = require("vietnamese.util")
local Config = require("vietnamese.config")
local WordEngine = require("vietnamese.WordEngine")

local is_vn_char = Codec.is_vn_char

local reverse_list = Util.reverse_list
local iter_chars = Util.iter_chars
local iter_chars_reverse = Util.iter_chars_reverse

local get_method_config = Config.get_method_config
local get_orthography_stragegy = Config.get_orthography_stragegy

local NAMESPACE = api.nvim_create_namespace("Vietnamese")
local THRESHOLD_WORD_LEN = 8
--- assuming that each char is two bytes
--- plus 2 for one char with the tone (3byte for tone char)
local WORST_CASE_WORD_LEN = THRESHOLD_WORD_LEN * 2 + 2

local M = {}

--- Check if a character is a valid input character for the current method
local is_diacritic_pressed = function(char, method_config)
	if type(method_config.is_diacritic_pressed) == "function" then
		return method_config.is_diacritic_pressed(char)
	end
	local McUtil = require("vietnamese.util.method-config")
	return McUtil.is_tone_key(char, method_config)
		or McUtil.is_tone_removal_key(char, method_config)
		or McUtil.is_shape_key(char, method_config)
end

--- Get valid Vietnamese characters to the **left** of the cursor.
--- It fetches chunks of text from the left side, expanding by THRESHOLD_WORD_LEN each time.
--- It collects characters that are valid Vietnamese letters and stops when a non-Vietnamese char is found.
--- @param bufnr integer: Buffer number
--- @param row0 integer: Cursor row (0-based)
--- @param col0 integer: Cursor column (0-based)
--- @return string[] chars List of left characters (from closest to furthest from cursor)
--- @return integer size Length of left_chars collected
local function scan_left_word_segment(bufnr, row0, col0)
	-- Get the text from start_col to end_col
	local text_chunk = nvim_buf_get_text(
		bufnr,
		row0,
		col0 - WORST_CASE_WORD_LEN > 0 and col0 - WORST_CASE_WORD_LEN or 0,
		row0,
		col0,
		{}
	)[1]
	if not text_chunk or text_chunk == "" then
		return {}, 0
	end

	local chars, n = {}, 0 -- Table to store characters we collect
	for _, ch in iter_chars_reverse(text_chunk) do
		if is_vn_char(ch) then
			n = n + 1
			chars[n] = ch
		else
			break -- Stop collecting if we hit a non-Vietnamese character
		end

		if n == THRESHOLD_WORD_LEN then
			break
		end
	end

	return reverse_list(chars, n), n
end

--- Get valid Vietnamese characters to the **right** of the cursor.
--- It fetches chunks of text from the right side, expanding by THRESHOLD_WORD_LEN each time.
--- It collects characters that are valid Vietnamese letters and stops when a non-Vietnamese char is found.
--- @param bufnr integer: Buffer number
--- @param row0 integer: Cursor row (0-based)
--- @param col0 integer: Cursor column (0-based)
--- @return string[] chars List of right characters (from closest to furthest from cursor)
--- @return integer size Length of right_chars collected
local function scan_right_word_segment(bufnr, row0, col0)
	local text_chunk = nvim_buf_get_text(bufnr, row0, col0, row0, col0 + WORST_CASE_WORD_LEN, {})[1]
	if not text_chunk or text_chunk == "" then
		return {}, 0
	end

	local chars, n = {}, 0
	for _, ch in iter_chars(text_chunk) do
		if is_vn_char(ch) then
			n = n + 1
			chars[n] = ch
		else
			break -- Stop collecting if we hit a non-Vietnamese character
		end
		if n == THRESHOLD_WORD_LEN then
			break -- Stop if we reach the threshold
		end
	end

	return chars, n
end

--- Main function to extract a processable Vietnamese word under cursor.
--- Combines characters from left of the cursor, the cursor character itself, and characters to the right.
--- Checks thresholds and rules to avoid collecting too many characters or empty segments.
--- @param bufnr integer Buffer number
--- @param row0 integer Row of the cursor (0-based)
--- @param col0 integer Column of the cursor (0-based)
--- @return string[]|nil chars List of characters in the word
--- @return integer size Length of the word
--- @return integer start_idx Index of the inserted character
local function extract_vn_word(bufnr, row0, col0)
	-- Get both sides of the word
	local left_chars, left_len = scan_left_word_segment(bufnr, row0, col0)
	if left_len == THRESHOLD_WORD_LEN or left_len < 1 then
		return nil, 0, 0
	end

	local right_chars, right_len = scan_right_word_segment(bufnr, row0, col0)

	local char_count = left_len + right_len
	if char_count >= THRESHOLD_WORD_LEN then
		return nil, 0, 0
	end
	local chars = tbl_move(right_chars, 1, right_len, left_len + 1, left_chars)
	return chars, char_count, left_len + 1
end

--- Calls a function without triggering events
--- @param events string The events to ignore
--- @param fn function The function to call
local do_without_events = function(events, fn)
	local old = o.eventignore
	o.eventignore = events
	fn()
	o.eventignore = old
end

M.setup = function()
	--- state
	local active_bufnr = -1

	local inserted_char = ""
	local inserted_idx = 0
	local current_word = nil
	local current_word_len = 0

	local is_inserting = false
	local is_delete_pressed = false
	local is_aeiouy_pressed = false
	local is_diacritic_key_pressed = false

	local reset_state = function()
		current_word = nil
		current_word_len = 0
		inserted_idx = 0
		is_aeiouy_pressed = false
		is_diacritic_key_pressed = false
	end

	local function is_backspace(key)
		local b1, b2, b3, b4 = string.byte(key, 1, 4)
		return b1 == 128 and b2 == 107 and b3 == 98 and b4 == nil
	end

	local function is_delete(key)
		local b1, b2, b3, b4 = string.byte(key, 1, 4)
		return b1 == 128 and b2 == 107 and b3 == 68 and b4 == nil
	end

	--- Why not handle all logic in vim.onkey?
	--- > Because we don't want it change the behavior of InsertCharPre autocmd
	--- > If handle all on onkey we need to return "" for some case
	--- and it will break the InsertCharPre autocmd
	--- Not only that it will have more strange behavior with buffer because the onkey may execute
	--- before buffer is ready
	nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
		callback = function(args)
			if Config.is_enabled() and Config.is_buf_enabled(args.buf) and args.event == "InsertEnter" then
				vim.on_key(function(key, typed)
					is_delete_pressed = is_backspace(typed) or is_delete(typed)
					inserted_char = typed
				end, NAMESPACE)
			else
				vim.on_key(nil, NAMESPACE)
			end
		end,
	})

	nvim_create_autocmd({ "InsertCharPre", "TextChangedI" }, {
		callback = function(args)
			local bufnr = args.buf
			if not Config.is_enabled() or not Config.is_buf_enabled(bufnr) then
				return
			elseif args.event == "InsertCharPre" then
				if v.char == inserted_char then
					is_inserting = true
					active_bufnr = bufnr
					is_aeiouy_pressed = inserted_char:match("^[aeiouyAEIOUY]$") ~= nil
					is_diacritic_key_pressed = is_diacritic_pressed(inserted_char, get_method_config())

					if is_diacritic_key_pressed or is_aeiouy_pressed then
						local pos = nvim_win_get_cursor(0)
						current_word, current_word_len, inserted_idx = extract_vn_word(bufnr, pos[1] - 1, pos[2])
						return
					end
				end
				reset_state()
				-- make sure that we are inserted
				-- and does not have any plugins change the inserted behavior
				return
			elseif active_bufnr ~= bufnr then
				-- make sure InsertedCharPre and TextChangedI in same buffer
				reset_state()
				return
			elseif not is_inserting then
				-- why not merge with above condiction
				-- To ensures that if not inserting it will jump to this block
				-- If merge maybe it will jump to the inserting block incorrectly
				if is_delete_pressed then
					-- check again to make sure it is delete key
					-- not implemented yet
					return
				end
				return
			else
				is_inserting = false

				-- nothing to handle
				if not current_word then
					return
				end

				local method_config = get_method_config()
				if not method_config then
					reset_state()
					return
				end

				local changed = false
				local word_engine = WordEngine:new(current_word, current_word_len, inserted_char, inserted_idx)

				-- check the diacritic key first
				if
					is_diacritic_key_pressed
					and word_engine:is_potential_diacritic_key(method_config)
					and word_engine:is_potential_vnword()
				then
					changed = word_engine:processes_diacritic(method_config, get_orthography_stragegy())
				end
				-- if not changed, then check the vowel
				if not changed and is_aeiouy_pressed then
					changed = word_engine:processes_new_vowel(method_config, get_orthography_stragegy())
				end
				-- if still not changed, then end
				if not changed then
					reset_state()
					return
				end

				local pos = nvim_win_get_cursor(0)
				local row = pos[1] -- Row is 1-indexed in API
				local row0, col0 = row - 1, pos[2]

				local new_word = word_engine:tostring()

				local wstart, wend = word_engine:col_bounds(col0)

				do_without_events("TextChanged,TextChangedI", function()
					nvim_buf_set_text(0, row0, wstart, row0, wend, { new_word })
				end)

				local new_cursor_col = word_engine:get_curr_cursor_col(col0)

				if col0 ~= new_cursor_col then
					-- Restore cursor position
					do_without_events("CursorMoved,CursorMovedI", function()
						nvim_win_set_cursor(0, { row, new_cursor_col })
					end)
				end

				reset_state()
			end
		end,
	})
end

return M
