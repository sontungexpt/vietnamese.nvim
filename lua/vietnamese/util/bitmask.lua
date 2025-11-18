local bit = require("bit")
local bor, lshift, band = bit.bor, bit.lshift, bit.band

local M = {}

--- Mark a bit in a bitmask
--- @param bitmask integer The bitmask to mark the bit in
--- @param bit_index integer The index of the bit to mark
M.mark_bit = function(bitmask, bit_index)
	return bor(bitmask, lshift(1, bit_index))
end

--- Check if a bit is marked
--- @param bitmask integer The bitmask to check
--- @param bit_index integer The index of the bit to check
M.is_marked = function(bitmask, bit_index)
	return band(bitmask, lshift(1, bit_index)) ~= 0
end

return M
