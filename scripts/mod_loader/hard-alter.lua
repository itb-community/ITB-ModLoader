--[[
	Contains hard alterations: permament changes to game files.
	This file is loaded first, so it must not use any of the mod loader's functions.
--]]

--[[
	Rewrites the specified game file so that the local variable inside
	of it becomes globally accessible.
--]]
local function globalizeLocalVariable(filePath, variableName)
	if not _G[variableName] then
		local file = assert(io.open(filePath, "r"), "Failed to open file: "..filePath)
		local content = file:read("*all")
		file:close()
		file = nil

		local prefix = "local "
		local index = string.find(content, prefix..variableName)

		if not index or index == -1 then
			error(string.format(
				"Could not find local variable '%s' in file '%s'.",
				variableName,
				filePath
			))
		end

		content, index = string.gsub(content, prefix..variableName, variableName)

		file = assert(io.open(filePath, "w"), "Failed to open file: "..filePath)
		file:write(content)
		file:close()
		file = nil

		dofile(filePath)

		LOG("Globalized", variableName)
	end
end

globalizeLocalVariable("scripts/text.lua", "Global_Texts")
globalizeLocalVariable("scripts/spawner_backend.lua", "WeakPawns")
