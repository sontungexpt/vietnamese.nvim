local nvim_create_user_command = vim.api.nvim_create_user_command

nvim_create_user_command("VietnameseToggle", function()
	local enabled = require("vietnamese.config").toggle_enabled()
	if enabled then
		require("vietnamese.notifier").info("Vietnamese enabled")
	else
		require("vietnamese.notifier").info("Vietnamese disabled")
	end
end, {})

nvim_create_user_command("VietnameseMethod", function(args)
	require("vietnamese.config").set_input_method(args.args)
end, {
	nargs = 1,
	complete = function()
		return require("vietnamese.config").get_support_methods()
	end,
})

nvim_create_user_command("VietnameseToneStragegy", function(args)
	require("vietnamese.config").set_tone_strategy(args.args)
end, {
	nargs = 1,
	complete = function()
		return vim.tbl_values(require("vietnamese.config").ToneStrategy)
	end,
})
