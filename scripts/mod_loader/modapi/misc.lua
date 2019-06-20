
function modApi:deltaTime()
	return self.msDeltaTime
end

function modApi:elapsedTime()
	-- return cached time, so that mods don't get different
	-- timings depending on when in the frame they called
	-- this function.
	return self.msLastElapsed
end

function modApi:isVersion(version,comparedTo)
	assert(type(version) == "string")
	if not comparedTo then
		comparedTo = self.version
	end
	assert(type(comparedTo) == "string")
	
	local v1 = self:splitString(version,"%D")
	local v2 = self:splitString(comparedTo,"%D")
	
	for i = 1, math.min(#v1,#v2) do
		local n1 = tonumber(v1[i])
		local n2 = tonumber(v2[i])
		if n1 > n2 then
			return false
		elseif n1 < n2 then
			return true
		end
	end
	
	return #v1 <= #v2
end

function modApi:addGenerationOption(id, name, tip, data)
	assert(type(id) == "string" or type(id) == "number")
	assert(type(name) == "string")
	tip = tip or nil
	assert(type(tip) == "string")
	data = data or {}
	assert(type(data) == "table") -- Misc stuff
	for i, option in ipairs(mod_loader.mod_options[self.currentMod]) do
		assert(option.id ~= id)
	end
	
	local option = {
		id = id,
		name = name,
		tip = tip,
		check = true,
		enabled = true,
		data = data
	}
	
	if data.values then
		assert(#data.values > 0)
		option.check = false
		option.enabled = nil
		option.values = data.values
		option.value = data.value or data.values[1]
		option.strings = data.strings
	elseif data.enabled == false then
		option.enabled = false
	end
	
	table.insert(mod_loader.mod_options[self.currentMod].options, option)
end
