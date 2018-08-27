
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

		content = string.sub(content, 8)
		file = io.open(path, "w+b")
		file:write(content)
		file:close()

		dofile(path)
		LOG("Globalized Global_Texts")
	end
end
GlobalizeGlobalTexts()

oldGetPopulationTexts = GetPopulationTexts
function GetPopulationTexts(event, count)
	local nullReturn = count == 1 and "" or {}
	
	if modApi.PopEvents[event] == nil then
		return nullReturn
	end
	
	if Game == nil then
        return nullReturn
    end
	
	local list = copy_table(modApi.PopEvents[event])
	local ret = {}
	for i = 1, count do
		if #list == 0 then
			break
		end
		
		ret[#ret+1] = random_removal(list)
		
		
		if modApi.PopEvents[event].Odds ~= nil and random_int(100) > modApi.PopEvents[event].Odds then
			ret[#ret] = nil
		end
	end
	
	if #ret == 0 then
		return nullReturn
	end

	local corp_name = Game:GetCorp().bark_name
	local squad_name = Game:GetSquad()
	for i,v in ipairs(ret) do
		ret[i] = string.gsub(ret[i], "#squad", squad_name)
		ret[i] = string.gsub(ret[i], "#corp", corp_name)
		for j, fn in ipairs(modApi.onGetPopEvent) do
			ret[i] = fn(ret[i],ret,i,event,count)
		end
	end
	
	if count == 1 then
		return ret[1]
	end
	
	return ret
end

local oldGetText = GetText
function GetText(id)
	if modApi.textOverrides and modApi.textOverrides[id] then
		return modApi.textOverrides[id]
	end
	
	return oldGetText(id)
end
