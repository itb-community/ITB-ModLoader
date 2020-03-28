
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
		return GetVanillaText(id, r1, r2, r3)
	end
end
