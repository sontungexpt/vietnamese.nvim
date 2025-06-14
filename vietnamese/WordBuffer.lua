local UTF8_VN_CHAR_DICT = require("vietnamese.constant").UTF8_VN_CHAR_DICT

local WordBuffer = {}

function WordBuffer:new(word_chars, cursor_char_pos, length)
	local obj = {
		word_chars = word_chars,
		cursor_char_pos = cursor_char_pos,
		length = length or #word_chars,
	}

	local private_fields = nil

	setmetatable(obj, {
		__index = self,
		__newindex = function(t, k, v)
			if private_fields == nil then
				private_fields = {}
				for k in pairs(obj) do
					private_fields[k] = true
				end
			end
			if not private_fields[k] then
				rawset(t, k, v)
			else
				error("Attempt to modify a private field: " .. k)
			end
		end,
	})
	return obj
end

function WordBuffer:get()
	return self.word_chars
end

function WordBuffer:get_word_without_cursor_char()
	local word_chars = {}
	for i = 1, self.length do
		if i ~= self.cursor_char_pos then
			word_chars[#word_chars + 1] = self.word_chars[i]
		end
	end
	return word_chars
end

function WordBuffer:get_length()
	return self.length
end

function WordBuffer:get_left_chars()
	local left_chars = {}
	for i = 1, self.cursor_char_pos - 1 do
		left_chars[i] = self.word_chars[i]
	end
	return left_chars
end

function WordBuffer:get_left_chars_length()
	return self.cursor_char_pos - 1
end

function WordBuffer:get_cursor_char()
	return self.word_chars[self.cursor_char_pos]
end

function WordBuffer:get_right_chars()
	local right_chars = {}
	for i = self.cursor_char_pos + 1, self.length do
		right_chars[i - self.cursor_char_pos] = self.word_chars[i]
	end
	return right_chars
end

function WordBuffer:get_right_chars_length()
	return self.length - self.cursor_char_pos
end

function WordBuffer:__len()
	return self.length
end

function WordBuffer:__tostring()
	return table.concat(self.left_chars) .. self.cursor_char .. table.concat(self.right_chars)
end

function M:decompose_word(excluded_cursor_char_pos)
	local decomposed_chars = {}
	local cursor_char_pos = self.cursor_char_pos

	for i = 1, self.length do
		if excluded_cursor_char_pos and i == cursor_char_pos then
			-- Skip the cursor character if it is excluded
			goto continue
		end

		local char = self.word_chars[i]

		if UTF8_VN_CHAR_DICT[char] then
			local char_structure = UTF8_VN_CHAR_DICT[char]
			decomposed_chars[#decomposed_chars + 1] = char_structure[1] -- base vowel
			local diacritic = char_structure.diacritic
			if diacritic then
				decomposed_chars[#decomposed_chars + 1] = diacritic
			end
			local tone = char_structure.tone
			if tone then
				decomposed_chars[#decomposed_chars + 1] = tone
			end
		else
			decomposed_chars[#decomposed_chars + 1] = char
		end

		::continue::
	end
	return decomposed_chars
end

return WordBuffer
