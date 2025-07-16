local vim, type = vim, type
local api, v = vim.api, vim.v
local nvim_win_get_cursor, nvim_win_set_cursor, nvim_buf_set_text, nvim_buf_get_text =
	api.nvim_win_get_cursor, api.nvim_win_set_cursor, api.nvim_buf_set_text, api.nvim_buf_get_text

local util = require("vietnamese.util")
local config = require("vietnamese.config")

local is_vietnamese_char, reverse_list, iter_chars, iter_chars_reverse =
	util.is_vietnamese_char, util.reverse_list, util.iter_chars, util.iter_chars_reverse

local THRESHOLD_WORD_LEN = 8
--- assuming that each char is two bytes
--- plus 2 for one char with the tone (3byte for tone char)
local WORST_CASE_WORD_LEN = THRESHOLD_WORD_LEN * 2 + 2

local M = {}

--- Check if a character is a valid input character for the current method
local function is_diacritic_pressed(char, method_config)
	if type(method_config.is_diacritic_pressed) == "function" then
		return method_config.is_diacritic_pressed(char)
	end
	local method_util = require("vietnamese.util.method-config")
	if
		method_util.is_tone_key(char, method_config)
		or method_util.is_tone_removal_key(char, method_config)
		or method_util.is_shape_key(char, method_config)
	then
		return true
	end
	return false
end

--- Get valid Vietnamese characters to the **left** of the cursor.
--- It fetches chunks of text from the left side, expanding by THRESHOLD_WORD_LEN each time.
--- It collects characters that are valid Vietnamese letters and stops when a non-Vietnamese char is found.
--- If the cursor is at the tail of a Vietnamese word, it includes the cursor character.
--- @param bufnr number: Buffer number
--- @param row_0based number: Cursor row (0-based)
--- @param col_0based number: Cursor column (0-based)
--- @return table: Reversed list of left characters (from closest to furthest from cursor)
--- @return number: Length of left_chars collected
local function collect_left_chars(bufnr, row_0based, col_0based)
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

	for _, ch in iter_chars_reverse(text_chunk) do
		if is_vietnamese_char(ch) then
			count = count + 1
			collected_chars[count] = ch
		else
			break -- Stop collecting if we hit a non-Vietnamese character
		end

		if count == THRESHOLD_WORD_LEN then
			break
		end
	end

	return reverse_list(collected_chars, count), count
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
local function find_vnword_under_cursor(bufnr, row_0based, col_0based)
	-- Get both sides of the word
	local left_chars, left_len = collect_left_chars(bufnr, row_0based, col_0based)
	if left_len == THRESHOLD_WORD_LEN or left_len < 1 then
		return nil, 0, 0
	end

	local right_chars, right_len = collect_right_chars_from_cursor(bufnr, row_0based, col_0based)

	local word_len = left_len + right_len
	if word_len >= THRESHOLD_WORD_LEN then
		return nil, 0, 0
	end

	--- combine right to left to get full word
	local word_chars = left_chars
	for i = 1, right_len do
		word_chars[left_len + i] = right_chars[i]
	end

	return word_chars, word_len, left_len + 1
end
M.find_vnword_under_cursor = find_vnword_under_cursor

M.setup = function()
	local GROUP = api.nvim_create_augroup("VietnameseEngine", { clear = true })
	local NAMESPACE = api.nvim_create_namespace("VietnameseEngine")
	local system_ime = require("vietnamese.system-ime")
	local bim_ok, bim_handler = pcall(require, "bim.handler")

	local inserted_char = ""
	local inserted_idx = 0
	local inserting = false
	local delete_pressed = false
	local working_bufnr = -1

	local cword, cwlen = nil, 0
	local is_vowel_pressed = false
	local is_diacritic_key_pressed = false

	local reset_state = function()
		cword, cwlen, inserted_idx = nil, 0, 0
		inserted_char = ""
		is_vowel_pressed = false
		is_diacritic_key_pressed = false
		working_bufnr = -1
	end

	local function register_onkey(cb, opts)
		vim.on_key(cb, NAMESPACE, opts)
	end

	local unregister_onkey = function()
		vim.on_key(nil, NAMESPACE)
	end

	--- disable system IME on startup
	system_ime.disable()

	api.nvim_create_autocmd({
		--  "VimEnter", -- no need because we call in setup functoin
		"FocusGained",
		"FocusLost",
		"VimLeave",
	}, {
		group = GROUP,
		callback = function(args)
			if not config.is_enabled() then
				return
			elseif args.event == "FocusGained" then
				system_ime.disable()
			else
				system_ime.enable()
			end
		end,
	})

	--- Why not handle all logic in vim.onkey?
	--- > Because we don't want it change the behavior of InsertCharPre autocmd
	--- > If handle all on onkey we need to return "" for some case
	--- and it will break the InsertCharPre autocmd
	--- Not only that it will have more strange behavior with buffer because the onkey may execute
	--- before buffer is ready
	api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
		group = GROUP,
		callback = function(args)
			if config.is_enabled() and config.is_buf_enabled(args.buf) and args.event == "InsertEnter" then
				---@diagnostic disable-next-line: unused-local
				register_onkey(function(key, typed)
					inserted_char = typed
					delete_pressed = typed == "\b" or typed == "\x7f"
				end)
			else
				unregister_onkey()
			end
		end,
	})
	api.nvim_create_autocmd({
		"InsertCharPre",
		"TextChangedI",
	}, {
		group = GROUP,
		callback = function(args)
			local bufnr = args.buf
			if not config.is_enabled() or not config.is_buf_enabled(bufnr) then
				return
			elseif args.event == "InsertCharPre" then
				if v.char == inserted_char then
					inserting = true
					working_bufnr = bufnr
					is_vowel_pressed = util.is_level1_vowel(inserted_char)
					is_diacritic_key_pressed = is_diacritic_pressed(inserted_char, config.get_method_config())

					if is_diacritic_key_pressed or is_vowel_pressed then
						local pos = nvim_win_get_cursor(0)
						cword, cwlen, inserted_idx = find_vnword_under_cursor(bufnr, pos[1] - 1, pos[2])
						return
					end
				end
				reset_state()
				-- make sure that we are inserted
				-- and does not have any plugins change the inserted behavior
				return
			elseif working_bufnr ~= bufnr then
				-- make sure InsertedCharPre and TextChangedI in same buffer
				reset_state()
				return
			elseif not inserting then
				-- why not merge with above condiction
				-- To ensures that if not inserting it will jump to this block
				-- If merge maybe it will jump to the inserting block incorrectly
				if delete_pressed then
					-- check again to make sure it is delete key
					-- not implemented yet
					return
				end
				return
			else
				inserting = false

				-- nothing to handle
				if not cword then
					return
				end

				local method_config = config.get_method_config()
				if not method_config then
					reset_state()
					return
				end

				local changed = false
				local word_engine = require("vietnamese.WordEngine"):new(cword, cwlen, inserted_char, inserted_idx)

				-- check the diacritic key first
				if
					is_diacritic_key_pressed
					and word_engine:is_potential_diacritic_key(method_config)
					and word_engine:is_potential_vnword()
				then
					changed = word_engine:processes_diacritic(method_config, config.get_tone_strategy())
				end

				-- if not changed, then check the vowel
				if not changed and is_vowel_pressed then
					changed = word_engine:processes_new_vowel(method_config, config.get_tone_strategy())
				end

				-- if still not changed, then end
				if not changed then
					reset_state()
					return
				end

				local pos = nvim_win_get_cursor(0)
				local row = pos[1] -- Row is 1-indexed in API
				local row_0based, col_0based = row - 1, pos[2]

				local new_word = word_engine:tostring()

				local wstart, wend = word_engine:col_bounds(col_0based)

				nvim_buf_set_text(0, row_0based, wstart, row_0based, wend, { new_word })

				local new_cursor_col = word_engine:get_curr_cursor_col(col_0based)
				if col_0based ~= new_cursor_col then
					-- Restore cursor position
					nvim_win_set_cursor(0, { row, new_cursor_col })

					-- intergrate with bim plugin
					if bim_ok then
						bim_handler.trigger_cursor_move_accepted()
					end
				end

				reset_state()
			end
		end,
	})
end

return M
