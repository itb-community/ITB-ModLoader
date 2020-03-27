
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

oldGetText = GetText
function GetText(id, r1, r2, r3)
	if not id then
		error("Attempted to fetch text with id = nil:\n" .. debug.traceback())
	end

	local text = nil
	if modApi.dictionary and modApi.dictionary[id] then
		text = modApi.dictionary[id]
	elseif modApi.textOverrides and modApi.textOverrides[id] then
		text = modApi.textOverrides[id]
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
		return oldGetText(id, r1, r2, r3)
	end
end
