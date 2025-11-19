local user_command = vim.api.nvim_create_user_command

user_command("VietnameseToggle", function()
	local enabled = require("vietnamese.config").toggle_enabled()
	if enabled then
		require("vietnamese.notifier").info("Vietnamese enabled")
	else
		require("vietnamese.notifier").info("Vietnamese disabled")
	end
end, {})

user_command("VietnameseMethod", function(args)
	require("vietnamese.config").set_input_method(args.args)
end, {
	nargs = 1,
	complete = require("vietnamese.config").get_supported_methods,
})

user_command("VietnameseToneStragegy", function(args)
	require("vietnamese.config").set_orthography_stragegy(args.args)
end, {
	nargs = 1,
	complete = require("vietnamese.config").get_supported_orthography_strategies,
})
