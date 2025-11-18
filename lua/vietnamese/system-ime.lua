---- avoid to call too many times
local MAX_RETRY = 5

--- IME class to manage Input Method Editors (IMEs)
--- @class IME
--- @field name string The name of the IME
--- @field enabled_cmd string[] The command to enable the IME
--- @field disabled_cmd string[] The command to disable the IME
--- @field installed boolean Indicates if the IME is installed
--- @field disabled boolean Indicates if the IME is currently disabled
local IME = {}
IME.__index = IME

function IME:new(name, enabled_cmd, disabled_cmd)
	local executable = vim.fn.executable

	return setmetatable({
		name = name,
		enabled_cmd = enabled_cmd or {},
		disabled_cmd = disabled_cmd or {},
		installed = executable(enabled_cmd[1]) == 1 and executable(disabled_cmd[1]) == 1,
		disabled = false,
	}, self)
end

--- Retry command execution with a maximum number of retries
--- @param cmd string[] The command to execute
--- @param max_retries integer The maximum number of max_retries
--- @param on_success function? Callback function to call on success
--- @param on_error function? Callback function to call on error
local function retry_cmd(cmd, max_retries, on_success, on_error, time)
	time = time or 1
	if time > max_retries then
		return
	end

	vim.system(cmd, {}, function(out)
		if out and out.code == 0 then
			if on_success then
				on_success(out)
			end
		else
			if on_error then
				on_error(out, time)
			end
			retry_cmd(cmd, max_retries, on_success, on_error, time + 1)
		end
	end)
end

--- Enable the IME
function IME:enable()
	if not self.installed or not self.disabled then
		return
	end

	retry_cmd(self.enabled_cmd, MAX_RETRY, function()
		self.disabled = false
		require("vietnamese.notifier").info(self.name .. " has been enabled.")
	end)
end

--- Disable the IME
function IME:disable()
	if not self.installed or self.disabled then
		return
	end

	retry_cmd(self.disabled_cmd, MAX_RETRY, function()
		self.disabled = true
		require("vietnamese.notifier").info(self.name .. " has been disabled.")
	end)
end

local IME_SUPPORTEDS = {
	IME:new("Ibus", {
		"ibus-daemon",
		"-drx",
	}, {
		"ibus",
		"exit",
	}),

	IME:new("Fcitx4", {
		"fcitx-remote",
		"-o",
	}, {
		"fcitx-remote",
		"-c",
	}),

	IME:new("Fcitx5", {
		"fcitx5-remote",
		"-r",
	}, {
		"fcitx5-remote",
		"-c",
	}),
}

local M = {}

M.enable = function()
	for _, ime in ipairs(IME_SUPPORTEDS) do
		ime:enable()
	end
end

M.disable = function()
	for _, ime in ipairs(IME_SUPPORTEDS) do
		ime:disable()
	end
end

M.setup = function()
	local config = require("vietnamese.config")

	--- disable system IME on startup
	M.disable()

	vim.api.nvim_create_autocmd({
		--  "VimEnter", -- no need because we call in setup functoin
		"FocusGained",
		"FocusLost",
		"VimLeave",
	}, {
		callback = function(args)
			if not config.is_enabled() then
				return
			elseif args.event == "FocusGained" then
				M.disable()
			else
				M.enable()
			end
		end,
	})
end

return M
