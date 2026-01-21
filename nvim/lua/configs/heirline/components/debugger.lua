local DAPMessages = {
	condition = function()
		local session = require("dap").session()
		return session ~= nil
	end,
	provider = function()
		return " " .. require("dap").status()
	end,
	hl = "Debug",
	-- see Click-it! section for clickable actions
}

return {
	DAPMessages = DAPMessages,
}
