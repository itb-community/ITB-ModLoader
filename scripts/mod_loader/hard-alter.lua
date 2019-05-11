--[[
	Contains hard alterations: permament changes to game files.
	This file is loaded first, so it must not use any of the mod loader's functions.
--]]

--[[
	Rewrites the specified game file by looking for the specified regex pattern,
	and replacing it with the specified replacement text. The text can reference
	regex capture groups.
--]]
local function replaceFileContent(filePath, regex, replacementText)
	local file = assert(io.open(filePath, "r"), "Failed to open file: "..filePath)
	local content = file:read("*all")
	file:close()
	file = nil

	content, _ = string.gsub(content, regex, replacementText)

	file = assert(io.open(filePath, "w"), "Failed to open file: "..filePath)
	file:write(content)
	file:close()
	file = nil
end

--[[
	Rewrites the specified game file so that the local variable inside
	of it becomes globally accessible.
--]]
local function globalizeLocalVariable(filePath, variableName)
	if not _G[variableName] then
		local prefix = "local "
		replaceFileContent(filePath, prefix..variableName, variableName)
		dofile(filePath)

		LOG("Globalized", variableName)
	end
end

globalizeLocalVariable("scripts/text.lua", "Global_Texts")
globalizeLocalVariable("scripts/spawner_backend.lua", "WeakPawns")

-- Fix spawner backend's guard sometimes failing, leading to a crash
replaceFileContent("scripts/spawner_backend.lua", "Board == NULL", "Board == NULL or not Board")
