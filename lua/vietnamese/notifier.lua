local notify = vim.notify
local schedule = vim.schedule
local TITLE = "Vietnamese Input Method"
local LOG_LEVELS = vim.log.levels

local M = {}

function M.error(message)
	schedule(function()
		notify(message, LOG_LEVELS.ERROR, { title = TITLE })
	end)
end

function M.info(message)
	schedule(function()
		notify(message, LOG_LEVELS.INFO, { title = TITLE })
	end)
end

function M.warn(message)
	schedule(function()
		notify(message, LOG_LEVELS.WARN, { title = TITLE })
	end)
end

return M
