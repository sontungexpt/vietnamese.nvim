local M = {}

M.name = "IBus"
M.initialized = false

local FALLBACK_ENGINE = "xkb:us::eng"

--------------------------------------------------
-- Check if ibus CLI exists
--------------------------------------------------
function M.is_available()
	return vim.fn.executable("ibus") == 1
end

--------------------------------------------------
-- Initialize backend
-- Ensure ibus-daemon is running (non-blocking)
--------------------------------------------------
function M.setup()
	if M.initialized then
		return
	end

	M.initialized = true
end

--------------------------------------------------
-- Internal async wrapper
-- Calls callback(nil) on failure
--------------------------------------------------
local function safe_system(cmd, callback)
	vim.system(cmd, { text = true }, function(result)
		if not result or result.code ~= 0 then
			if callback then
				callback(nil)
			end
			return
		end

		if callback then
			callback(result)
		end
	end)
end

--------------------------------------------------
-- Get current engine name (async)
--------------------------------------------------
function M.get_state(callback)
	safe_system({ "ibus", "engine" }, function(result)
		if not result or not result.stdout then
			callback(nil)
			return
		end

		local engine = result.stdout:gsub("%s+", "")
		if engine == "" then
			callback(nil)
			return
		end

		callback(engine)
	end)
end

--------------------------------------------------
-- Returns the engine/id used for "inactive" state
--------------------------------------------------
function M.get_inactive_state()
	return FALLBACK_ENGINE
end

--------------------------------------------------
-- Returns true if given state is considered "inactive"
--------------------------------------------------
function M.is_inactive(state)
	if not state then
		return false
	end
	return state == FALLBACK_ENGINE
end

--------------------------------------------------
-- Switch to inactive engine (async)
-- Calls callback(inactive_state) on success, callback(nil) on failure
--------------------------------------------------
function M.set_inactive(current_state, callback)
	-- default fallback engine
	local fallback_engine = FALLBACK_ENGINE

	safe_system({ "ibus", "engine", fallback_engine }, function(result)
		if not result then
			if callback then
				callback(nil)
			end
			return
		end

		if callback then
			callback(fallback_engine)
		end
	end)
end

--------------------------------------------------
-- Restore previous engine (async safe)
-- Calls callback(true) on success, callback(nil) on failure
--------------------------------------------------
function M.restore(prev_state, callback)
	if not prev_state or prev_state == "" then
		if callback then
			callback(nil)
		end
		return
	end

	safe_system({ "ibus", "engine", prev_state }, function()
		if callback then
			callback(true)
		end
	end)
end

return M
