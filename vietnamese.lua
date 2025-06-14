local M = {}
local engine = require("vietnamese.engine")
local config = require("vietnamese.config")

M.setup = function(user_config)
	local config = config.set_user_config(user_config)
	-- vim.api.nvim_create_autocmd("InsertCharPre", {
	-- 	callback = function(args)
	-- 		local char = vim.v.char
	-- 		if not engine.should_process(char) then
	-- 			return
	-- 		end

	-- 		local cursor_pos = vim.api.nvim_win_get_cursor(0)
	-- 		local row, col = cursor_pos[1] - 1, cursor_pos[2]
	-- 		local line = vim.api.nvim_get_current_line()

	-- 		local word_start, word_end = engine.find_word_boundaries(line, col)
	-- 		local raw_text = line:sub(word_start + 1, col) .. char

	-- 		if not engine.is_valid_sequence(raw_text) then
	-- 			return
	-- 		end

	-- 		local processed = engine.process_raw_text(raw_text)
	-- 		if not processed then
	-- 			return
	-- 		end

	-- 		vim.api.nvim_buf_set_text(0, row, word_start, row, col, { processed })
	-- 		vim.api.nvim_win_set_cursor(0, { row + 1, word_start + #processed })

	-- 		vim.schedule(function()
	-- 			vim.v.char = ""
	-- 		end)
	-- 	end,
	-- })
	-- -- vietnamese_input/init.lua
	engine.setup(config)
end

return M
