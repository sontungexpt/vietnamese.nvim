---- avoid to call too many times
local enabled = true
local M = {}

M.enable = function()
	if enabled then
		return
	end

	vim.system({
		"ibus",
		"engine",
		"BambooUs",
	}, {}, function(out)
		if out and out.code == 0 then
			enabled = true
			require("vietnamese.notifier").info("Ibus has been disabled.")
		end
	end)
end

M.disable = function()
	if not enabled then
		return
	end

	vim.system({
		"ibus",
		"engine",
		"xkb:us:eng",
	}, {}, function(out)
		if out and out.code == 0 then
			enabled = false
			require("vietnamese.notifier").info("Ibus has been enabled.")
		end
	end)
end

return M
