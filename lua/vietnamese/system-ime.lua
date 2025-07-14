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
	end
	if Ibus.disabled and Ibus.saved_engine then
		Ibus.disabled = false
		vim.system({
			"ibus",
			"restart",
		}, {}, function(out)
			if out and out.code ~= 0 then
				Ibus.restore(time + 1) -- retry if failed
				return
			end
			vim.system({
				"ibus",
				"engine",
				Ibus.saved_engine,
			}, {}, function(out)
				if out and out.code == 0 then
					require("vietnamese.notifier").info(
						time .. " times. Ibus has been restored to " .. Ibus.saved_engine .. "."
					)
				else
					Ibus.restore(time + 1) -- retry if failed
				end
			end)
		end)
	end
end

Ibus.disable = function(time)
	if time then
		return
	end

	if Ibus.disabled then
		return
	end

	Ibus.get_current_engine(function(engine)
		if engine then
			vim.system({
				"ibus",
				"restart",
			}, {}, function(out)
				if out and out.code ~= 0 then
					Ibus.disable(time + 1) -- retry if failed
					return
				end
				vim.system({
					"ibus",
					"engine",
					"xkb:us::eng",
				}, {}, function(out)
					if out and out.code == 0 then
						Ibus.saved_engine = engine
						Ibus.disabled = true

						require("vietnamese.notifier").info(
							time
								.. " times. "
								.. "Ibus has been disabled. Save "
								.. "current engine: "
								.. Ibus.saved_engine
								.. "."
						)
					else
						Ibus.disable(time + 1) -- retry if failed
					end
				end)
			end)
		end
	end)
end

M.restore = function()
	Ibus.restore(1)
end

M.disable = function()
	Ibus.disable(1)
end

M.Ibus = Ibus
return M
