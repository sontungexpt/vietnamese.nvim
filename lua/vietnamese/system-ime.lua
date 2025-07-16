---- avoid to call too many times
local M = {}
local Ibus = {
	command = "ibus",
	get_current_engine = function(cb)
		vim.system({
			"ibus",
			"engine",
		}, {}, function(out)
			if out and out.code == 0 and out.stdout then
				local engine = out.stdout:match("[^\r\n]+")
				cb(engine)
			end
		end)
	end,
}

Ibus.enable = function(time)
	if time > 5 then
		return
	elseif not Ibus.disabled then
		return
	end

	vim.system({
		"ibus-daemon",
		"-drx",
	}, {}, function(out)
		if out and out.code == 0 then
			Ibus.disabled = false
			require("vietnamese.notifier").info("successfully restored Ibus after " .. time .. " times.")
		else
			Ibus.enable(time + 1) -- retry if failed
		end
	end)
end

Ibus.disable = function(time)
	if time > 5 then
		return
	elseif Ibus.disabled then
		return
	end

	vim.system({
		"ibus",
		"exit",
		-- "engine",
		-- "xkb:us::eng",
	}, {}, function(out)
		if out and out.code == 0 then
			Ibus.disabled = true
			require("vietnamese.notifier").info("Ibus has been disabled after " .. time .. " times.")
		else
			Ibus.disable(time + 1) -- retry if failed
		end
	end)
end

local Fcitx4 = {
	command = "fcitx-remote",
}

Fcitx4.enable = function(time)
	if time > 5 then
		return
	elseif not Fcitx4.disabled then
		return
	end

	vim.system({
		"fcitx-remote",
		"-o",
	}, {}, function(out)
		if out and out.code == 0 then
			Fcitx4.disabled = false
			require("vietnamese.notifier").info("Fcitx5 has been enabled.")
		else
			require("vietnamese.notifier").error("Failed to enable Fcitx5.")
		end
	end)
end

Fcitx4.disable = function(time)
	if time > 5 then
		return
	elseif Fcitx4.disabled then
		return
	end

	vim.system({
		"fcitx-remote",
		"-c",
	}, {}, function(out)
		if out and out.code == 0 then
			Fcitx4.disabled = true
			require("vietnamese.notifier").info("Fcitx5 has been disabled.")
		else
			require("vietnamese.notifier").error("Failed to disable Fcitx5.")
		end
	end)
end

local SUPPORTED_IMES = {
	Ibus,
	Fcitx4,
}

M.identify_system_IME = function()
	for _, ime in ipairs(SUPPORTED_IMES) do
		if vim.fn.executable(ime.command) == 1 then
			ime.installed = true
		end
	end
end

M.enable = function()
	for _, ime in ipairs(SUPPORTED_IMES) do
		if ime.installed then
			ime.enable(1)
		end
	end
end

M.disable = function()
	for _, ime in ipairs(SUPPORTED_IMES) do
		if ime.installed then
			ime.disable(1)
		end
	end
end

return M
