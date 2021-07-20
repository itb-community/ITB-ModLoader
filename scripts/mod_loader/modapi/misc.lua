
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
	Assert.Equals({ "string", "number" }, type(id))
	Assert.Equals("string", type(name))
	tip = tip or nil
	Assert.Equals("string", type(tip))
	data = data or {}
	Assert.Equals("table", type(data))
	for i, option in ipairs(mod_loader.mod_options[self.currentMod]) do
		Assert.NotEquals(option.id, id, "Option id is already taken: ".. id)
	end

	local option = {
		id = id,
		name = name,
		tip = tip,
		data = data
	}

	if data.values then
		Assert.True(#data.values > 0, "Table of values for the dropdown must not be empty")
		option.type = "dropdown"
		option.values = data.values
		option.value = data.value or data.values[1]
		option.strings = data.strings
		option.tooltips = data.tooltips
	else
		option.type = "checkbox"
		option.enabled = data.enabled == nil and true or data.enabled
	end

	table.insert(mod_loader.mod_options[self.currentMod].options, option)
end
