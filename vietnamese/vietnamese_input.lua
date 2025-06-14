-- vietnamese_input.lua
local vietnamese_input = require("vietnamese_input")

vim.api.nvim_create_user_command("VietnameseInputEnable", function()
	vietnamese_input.setup()
	print("Vietnamese input method enabled")
end, {})

vim.api.nvim_create_user_command("VietnameseInputMethod", function(opts)
	vietnamese_input.engine.set_input_method(opts.args)
	print("Vietnamese input method set to: " .. opts.args)
end, { nargs = 1 })
