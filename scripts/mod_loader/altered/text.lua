
GetVanillaText = GetText

function GetText(id, r1, r2, r3)
	if not id then
		error("Attempted to fetch text with id = nil:\n" .. debug.traceback())
	end

	local text = nil
	if modApi.dictionary and modApi.dictionary[id] then
		text = modApi.dictionary[id]
	elseif modApi.modLoaderDictionary and modApi.modLoaderDictionary[id] then
		text = modApi.modLoaderDictionary[id]
	end

	if text then
		-- Expand variables
		if r1 ~= nil and r1 ~= "" then
			text = string.gsub(text,"$1", r1)
		end
		if r2 ~= nil and r2 ~= "" then
			text = string.gsub(text,"$2", r2)
		end
		if r3 ~= nil and r3 ~= "" then
			text = string.gsub(text,"$3", r3)
		end

		return text
	else
		text = GetVanillaText(id, r1, r2, r3)
		
		if text == id then
			if id:match("Upgrade%d$") then
				local skill = _G[id:sub(1,-10)]
				local upgrade = tonumber(id:sub(-1,-1))
				
				if type(skill) == 'table' and type(skill.UpgradeList) == 'table' then
					text = skill.UpgradeList[upgrade] or text
				end
			end
		end
		
		return text
	end
end

local vanillaGetPilotDialog = GetPilotDialog
function GetPilotDialog(personality, event)
	local result = vanillaGetPilotDialog(personality, event)
	
	return GetPilotDialog_Deprecated(personality, event)
end
