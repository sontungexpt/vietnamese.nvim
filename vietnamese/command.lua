local nvim_create_user_command = vim.api.nvim_create_user_command

nvim_create_user_command("VietnameseToggle", function()
	local enabled = require("vietnamese.config").toggle_enabled()
	if enabled then
		require("vietnamese.notifier").info("Vietnamese enabled")
	else
		require("vietnamese.notifier").info("Vietnamese disabled")
	end
end, {})
