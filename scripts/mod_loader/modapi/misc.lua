
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

function modApi:getCurrentMod()
	Assert.ModInitializingOrLoading("This function should only be called while mods are initializing or loading")

	return mod_loader.mods[self.currentMod]
end

function modApi:getModOptions(modId)
	Assert.Equals({"string", "nil"}, type(modId), "Argument #1")

	if modId == nil then
		Assert.ModInitializingOrLoading("Argument #1 must be specified outside of init or load")
		modId = self.currentMod
	end

	Assert.True(mod_loader:hasMod(modId), "Mod not found")

	local modContent = mod_loader.currentModContent or mod_loader:getModConfig()
	return modContent[modId].options
end

-- gameSquadIndex is the index the game uses to refer to squads:
-- 0-7   -> non-ae-mechs
-- 8-9   -> random/custom
-- 10    -> secret
-- 11-15 -> ae-mechs

-- modLoaderSquadIndex is the index the mod loader uses to refer to squads:
-- 1-8   -> non-ae-mechs
-- 9     -> secret
-- 10-14 -> ae-mechs

-- modSquadIndex is the index the modded squad has in modApi.mod_squads
-- Like modLoaderSquadIndex, it is 1-indexed. Vanilla squads are in the same indexes
-- as for modLoaderSquadIndex, while mod squads are added from index 15 and onwards.
-- This index can vary between ITB launches, but will remain constant until ITB closes.

-- Converts gameSquadIndex to modLoaderSquadIndex
function modApi:squadIndex_game2modLoader(gameSquadIndex)
	if false
		or gameSquadIndex == modApi.constants.SQUAD_INDEX_RANDOM
		or gameSquadIndex == modApi.constants.SQUAD_INDEX_CUSTOM
	then
		Assert.Error("Invalid gameSquadIndex -> modLoaderSquadIndex conversion")
	end

	if gameSquadIndex > modApi.constants.SQUAD_INDEX_CUSTOM then
		return gameSquadIndex - 1
	else
		return gameSquadIndex + 1
	end
end

-- Converts modLoaderSquadIndex to gameSquadIndex
function modApi:squadIndex_modLoader2game(modLoaderSquadIndex)
	if modLoaderSquadIndex >= modApi.constants.SQUAD_INDEX_CUSTOM then
		return modLoaderSquadIndex + 1
	else
		return modLoaderSquadIndex - 1
	end
end

function modApi:getModSquadByModLoaderSquadIndex(modLoaderSquadIndex)
	local modSquadIndex = modApi.squadIndices[modLoaderSquadIndex]
	return modApi.mod_squads[modSquadIndex].id
end

function modApi:getModSquadIdByGameSquadIndex(gameSquadIndex)
	local modLoaderSquadIndex = self:squadIndex_game2modLoader(gameSquadIndex)
	return self:getModSquadByModLoaderSquadIndex(modLoaderSquadIndex)
end

-- Returns the modSquadIndex the squad id has, or -1 if none can be found.
-- Each mod squad is assigned a modSquadIndex when it is added to the mod loader,
-- and remains constant for the duration of the application.
function modApi:getSquadsModSquadIndex(squadId)
	for modSquadIndex, squadData in pairs(modApi.mod_squads) do
		if squadData.id == squadId then
			return modSquadIndex
		end
	end

	return -1
end

-- Returns the current modLoaderSquadIndex for the squadId, or -1 if none can be found.
-- Using the squad editor to change which squads are available in the hangar can change
-- the modLoaderSquadIndex for a squad.
function modApi:getSquadsCurrentModLoaderSquadIndex(squadId)
	local modSquadIndex = self:getSquadsModSquadIndex(squadId)

	for modLoaderSquadIndex, i in ipairs(modApi.squadIndices) do
		if i == modSquadIndex then
			return modLoaderSquadIndex
		end
	end

	return -1
end
