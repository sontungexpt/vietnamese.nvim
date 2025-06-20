local notify = vim.notify
local TITLE = "Vietnamese Input Method"
local LOG_LEVELS = vim.log.levels

local M = {}

function M.error(message)
	notify(message, LOG_LEVELS.ERROR, { title = TITLE })
end

function M.info(message)
	notify(message, LOG_LEVELS.INFO, { title = TITLE })
end

return M
