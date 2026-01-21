local Align = {
	provider = function()
		return "%="
	end,
}

local Space = {
	provider = function()
		return " "
	end,
}

return {
	Align = Align,
	Space = Space,
}
