--[[
	Contains hard alterations: permanent changes to game files.
	This file is loaded first, so it must not use any of the mod loader's functions.
--]]

--[[
	Rewrites the specified game file by looking for the specified regex pattern,
	and replacing it with the specified replacement text. The text can reference
	regex capture groups.
--]]
local function replaceFileContent(filePath, regex, replacementText)
	local file = File(filePath)
	local content = file:read_to_string()

	content, _ = string.gsub(content, regex, replacementText)

	file:write_string(content)
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
globalizeLocalVariable("scripts/spawner_backend.lua", "exclusiveElements")
globalizeLocalVariable("scripts/game.lua", "GameObject")
globalizeLocalVariable("scripts/text_population.lua", "PopEvent")
globalizeLocalVariable("scripts/personalities/personalities.lua", "PilotPersonality")

-- Fix spawner backend's guard sometimes failing, leading to a crash
replaceFileContent("scripts/spawner_backend.lua", "if Board == NULL then", "if Board == NULL or not Board then")

-- Modify RandomMap in maps/maphelper.lua to always return a mapname
replaceFileContent("maps/maphelper.lua", "if v == sector or v == \"any_sector\" then", "if sector == nil or v == sector or v == \"any_sector\" then")
replaceFileContent("maps/maphelper.lua", "%s*-- LOG%(\"COULD NOT FIND MAP WITH TAGS \"..tag..\" and \"..sector%)%s+return \"\"", "\n\t\tif sector ~= nil then\n\t\t\treturn RandomMap%(tag, nil%)\n\t\tend\n\n\t\treturn \"null\"")

ReplaceFileContent = replaceFileContent
