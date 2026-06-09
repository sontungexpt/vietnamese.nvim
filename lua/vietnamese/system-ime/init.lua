local M = {}

-- Public state
M.backend = nil
M.prev_state = nil
M.expected_inactive = nil -- what we set when disabling
M.current_mode = "active" -- 'active' or 'inactive'

-- Backend registry (extensible)
local registry = {}
local name_map = {}

-- Request sequencing to avoid races between async callbacks
local seq = 0
local current_request_id = 0
local function new_request()
	seq = seq + 1
	current_request_id = seq
	return seq
end
local function is_latest(id)
	return id == current_request_id
end

--------------------------------------------------
-- Register a backend module so detection is extensible
-- Usage: require('vietnamese.system-ime').register_backend(require('vietnamese.system-ime.backends.ibus'))
--------------------------------------------------
function M.register_backend(backend)
	if not backend or type(backend) ~= "table" then
		return
	end

	registry[#registry + 1] = backend
	if backend.name then
		name_map[backend.name] = backend
	end
end

--------------------------------------------------
-- Force set a backend by name or module
--------------------------------------------------
function M.set_backend(backend)
	if type(backend) == "string" then
		M.backend = name_map[backend]
	elseif type(backend) == "table" then
		M.backend = backend
	end
end

function M.get_backend()
	return M.backend
end

--------------------------------------------------
-- Detect available backend (first match)
--------------------------------------------------
function M.detect_backend()
	for _, b in ipairs(registry) do
		pcall(function()
			if b.is_available and b.is_available() then
				M.backend = b
				return
			end
		end)
	end
end

--------------------------------------------------
-- Disable IME safely:
-- 1) read current state
-- 2) if already "inactive" -> just mark inactive (don't store prev_state)
-- 3) otherwise store prev_state, set inactive and remember which inactive id was used
-- All async callbacks check request id so outdated responses are ignored.
--------------------------------------------------
function M.disable()
	local backend = M.backend
	if not backend then
		return
	end

	if M.current_mode == "inactive" then
		return
	end

	local req_id = new_request()

	if not backend.get_state then
		-- Backend doesn't support state query; best-effort set inactive
		if backend.set_inactive then
			backend.set_inactive(nil, function(inactive)
				vim.schedule(function()
					if not is_latest(req_id) then
						return
					end
					if inactive then
						M.expected_inactive = inactive
						M.current_mode = "inactive"
					end
				end)
			end)
		end
		return
	end

	backend.get_state(function(state)
		vim.schedule(function()
			if not is_latest(req_id) then
				return
			end

			-- If we couldn't read state, still attempt to set inactive
			if not state then
				if backend.set_inactive then
					backend.set_inactive(nil, function(inactive)
						vim.schedule(function()
							if not is_latest(req_id) then
								return
							end
							if inactive then
								M.expected_inactive = inactive
								M.current_mode = "inactive"
							end
						end)
					end)
				end
				return
			end

			-- If already inactive, don't overwrite prev_state
			if backend.is_inactive and backend.is_inactive(state) then
				M.prev_state = nil
				M.expected_inactive = state
				M.current_mode = "inactive"
				return
			end

			-- Otherwise store previous engine and switch to inactive
			M.prev_state = state
			if backend.set_inactive then
				backend.set_inactive(state, function(inactive)
					vim.schedule(function()
						if not is_latest(req_id) then
							return
						end
						if inactive then
							M.expected_inactive = inactive
							M.current_mode = "inactive"
						end
					end)
				end)
			else
				-- no set_inactive support; just mark as inactive
				M.current_mode = "inactive"
			end
		end)
	end)
end

--------------------------------------------------
-- Enable IME safely:
-- Will only restore if the system IME still matches expected inactive state (or is_inactive).
-- This prevents overriding user changes while Neovim was focused.
--------------------------------------------------
function M.enable()
	local backend = M.backend
	if not backend then
		return
	end

	if M.current_mode ~= "inactive" then
		return
	end

	local prev = M.prev_state
	if not prev then
		-- Nothing to restore
		M.current_mode = "active"
		M.expected_inactive = nil
		return
	end

	local req_id = new_request()

	-- Double-check current system state to avoid stomping user choice
	if not backend.get_state then
		-- Can't read state: best-effort restore
		if backend.restore then
			backend.restore(prev, function(ok)
				vim.schedule(function()
					if not is_latest(req_id) then
						return
					end
					if ok then
						M.prev_state = nil
						M.expected_inactive = nil
						M.current_mode = "active"
					end
				end)
			end)
		end
		return
	end

	backend.get_state(function(now_state)
		vim.schedule(function()
			if not is_latest(req_id) then
				return
			end

			local can_restore = false
			if not now_state then
				can_restore = true
			elseif backend.is_inactive and backend.is_inactive(now_state) then
				can_restore = true
			elseif M.expected_inactive and now_state == M.expected_inactive then
				can_restore = true
			else
				can_restore = false
			end

			if not can_restore then
				-- User changed IME while we were focused: do not override
				M.prev_state = nil
				M.expected_inactive = nil
				M.current_mode = "active"
				return
			end

			if backend.restore then
				backend.restore(prev, function(ok)
					vim.schedule(function()
						if not is_latest(req_id) then
							return
						end
						if ok then
							M.prev_state = nil
							M.expected_inactive = nil
							M.current_mode = "active"
						end
					end)
				end)
			else
				-- No restore support: just clear state
				M.prev_state = nil
				M.expected_inactive = nil
				M.current_mode = "active"
			end
		end)
	end)
end

--------------------------------------------------
-- Setup: register default backends, detect and initialize, then wire focus autocmds
-- Idempotent: re-run will clear previous autocmd group
--------------------------------------------------
function M.setup()
	-- Register built-in backends if not already registered
	pcall(function()
		M.register_backend(require("vietnamese.system-ime.backends.fcitx5"))
	end)
	pcall(function()
		M.register_backend(require("vietnamese.system-ime.backends.ibus"))
	end)

	-- Detect backend
	M.detect_backend()
	if not M.backend then
		-- No system IME backend available; nothing to do
		return
	end

	-- Initialize backend
	if M.backend.setup then
		M.backend.setup()
	end

	-- Create an augroup so we don't duplicate autocmds on re-setup
	local group = vim.api.nvim_create_augroup("VietnameseSystemIme", { clear = true })

	vim.api.nvim_create_autocmd({ "FocusGained" }, {
		group = group,
		callback = function()
			M.disable()
		end,
	})

	vim.api.nvim_create_autocmd({ "FocusLost", "VimLeave" }, {
		group = group,
		callback = function()
			M.enable()
		end,
	})

	-- Respect user config initial state (if config is loaded when setup runs)
	local ok, cfg = pcall(require, "vietnamese.config")
	if ok and cfg and cfg.is_enabled then
		if cfg.is_enabled() then
			M.disable()
		else
			M.enable()
		end
	else
		-- Default: disable system IME when plugin loaded
		M.disable()
	end
end

return M
