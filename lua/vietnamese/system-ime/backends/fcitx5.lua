local M = {}

M.name = "Fcitx5"
M.initialized = false

local INACTIVE_ID = "keyboard-us"

--------------------------------------------------
-- Check if fcitx5-remote exists in PATH
--------------------------------------------------
function M.is_available()
	return vim.fn.executable("fcitx5-remote") == 1
end

--------------------------------------------------
-- Initialize backend (non-blocking ping)
--------------------------------------------------
function M.setup()
	if M.initialized then
		return
	end

	-- Non-blocking ping to warm up daemon
	vim.system({ "fcitx5-remote" }, {}, function() end)

	M.initialized = true
end

--------------------------------------------------
-- Internal async system wrapper
-- Ensures callback is only called on success
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
-- Get current IME engine name (async)
--------------------------------------------------
function M.get_state(callback)
	safe_system({ "fcitx5-remote", "-n" }, function(result)
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
	return INACTIVE_ID
end

--------------------------------------------------
-- Returns true if given state is considered "inactive"
--------------------------------------------------
function M.is_inactive(state)
	if not state then
		return false
	end
	return state == INACTIVE_ID
end

--------------------------------------------------
-- Switch to inactive layout (async)
-- Calls callback(inactive_state) on success, callback(nil) on failure
--------------------------------------------------
function M.set_inactive(current_state, callback)
	safe_system({ "fcitx5-remote", "-s", INACTIVE_ID }, function(result)
		if not result then
			if callback then
				callback(nil)
			end
			return
		end

		if callback then
			callback(INACTIVE_ID)
		end
	end)
end

--------------------------------------------------
-- Restore previous IME engine (async)
-- Calls callback(true) on success, callback(nil) on failure
--------------------------------------------------
function M.restore(prev_state, callback)
	if not prev_state or prev_state == "" then
		if callback then
			callback(nil)
		end
		return
	end

	safe_system({ "fcitx5-remote", "-s", prev_state }, function()
		if callback then
			callback(true)
		end
	end)
end

return M
