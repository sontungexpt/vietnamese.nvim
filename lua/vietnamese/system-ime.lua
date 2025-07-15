---- avoid to call too many times
local M = {}
local Ibus = {}

Ibus.get_current_engine = function(cb)
	vim.system({
		"ibus",
		"engine",
	}, {}, function(out)
		if out and out.code == 0 and out.stdout then
			local engine = out.stdout:match("[^\r\n]+")
			cb(engine)
		end
	end)
end

Ibus.restore = function(time)
	if time > 5 then
		return
	elseif not Ibus.disabled then
		return
	end

	Ibus.disabled = false

	vim.system({
		"ibus-daemon",
		"-drx",
	}, {}, function(out)
		if out and out.code == 0 then
			require("vietnamese.notifier").info("successfully restored Ibus after " .. time .. " times.")
		else
			Ibus.restore(time + 1) -- retry if failed
		end
	end)
end

Ibus.disable = function(time)
	if time > 5 then
		return
	elseif Ibus.disabled then
		return
	end

	-- Ibus.get_current_engine(function(engine)
	-- 	if engine then
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
	-- end
	-- end)
end

M.restore = function()
	Ibus.restore(1)
end

M.disable = function()
	Ibus.disable(1)
end

M.Ibus = Ibus
return M
