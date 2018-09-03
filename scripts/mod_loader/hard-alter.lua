--[[
	Contains hard alterations: permament changes to game files.
	This file is loaded first, so it must not use any of the mod loader's functions.
--]]

--[[
	Rewrites text.lua so that Global_Texts table inside
	of it becomes globally accessible.
--]]
local function GlobalizeGlobalTexts()
	if not Global_Texts then
		local path = "scripts/text.lua"
		local file = io.open(path, "rb")

		local content = file:read("*all")
		file:close()
		file = nil

		local index = string.find(content, "local Global_Texts") + 6

		content = string.sub(content, index)
		file = io.open(path, "w+b")
		file:write(content)
		file:close()

		dofile(path)
		LOG("Globalized Global_Texts")
	end
end
GlobalizeGlobalTexts()
