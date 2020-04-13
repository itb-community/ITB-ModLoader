local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals
local buildPawnTest = Tests.BuildPawnTest

local MS_WAIT_FOR_SAVING_GAME = 100

local function isValidTile(loc)
	return not Board:IsBlocked(loc, PATH_PROJECTILE)
end

-- return all tiles on the board validating the function is_valid_tile.
-- is_valid_tile defaults to isValidTile if no function is provided.
local function getBoardLocations(is_valid_tile)
	is_valid_tile = is_valid_tile or isValidTile
	local result = {}
	local size = Board:GetSize()
	for x = 0, size.x -1 do
		for y = 0, size.y - 1 do
			local loc = Point(x,y)
			
			if isValidTile(loc) then
				result[#result+1] = loc
			end
		end
	end
	
	return result
end

-- returns a random location from a set of locations, validating the function is_valid_tile.
-- is_valid_tile defaults to isValidTile if no function is provided.
-- locations defaults to all locations validating is_valid_tile if no set is provided.
-- the returned location is removed from the set.
local function getRandomLocation(locations, is_valid_tile)
	is_valid_tile = is_valid_tile or isValidTile
	locations = locations or getBoardLocations(is_valid_tile)
	
	return random_removal(locations)
end

local function getTileSaveData(loc)
	local region = GetCurrentRegion()
	local tile_data
	local tile_index = 1
	
	if region and region.player and region.player.map_data and region.player.map_data.map then
		
		repeat
			tile_data = region.player.map_data.map[tile_index]
			tile_index = tile_index + 1
			
			if tile_data and tile_data.loc == loc then
				break
			end
		until tile_data == nil
	end
	
	return tile_data
end

testsuite.test_SetFrozen_ShouldFreezePawnsAndMountains = buildPawnTest({
	-- The mountain and pawn should be frozen, while the road should not.
	-- The mountain and pawn should then be unfrozen.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		pawnLoc = pawn:GetSpace()
		
		local locations = getBoardLocations()
		mountainLoc = getRandomLocation(locations)
		roadLoc = getRandomLocation(locations)
		
		defaultMountainTerrain = Board:GetTerrain(mountainLoc)
		defaultRoadTerrain = Board:GetTerrain(roadLoc)
		Board:SetTerrainVanilla(mountainLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(roadLoc, TERRAIN_ROAD)
	end,
	execute = function()
		-- Board:SetFrozen(location, frozen, no_animation)
		Board:SetFrozen(pawnLoc, true, true)
		Board:SetFrozen(mountainLoc, true, true)
		Board:SetFrozen(roadLoc, true, true)
		
		actualPawnFrozenState = pawn:IsFrozen()
		actualMountainFrozenState = Board:IsFrozen(mountainLoc)
		actualRoadFrozenState = Board:IsFrozen(roadLoc)
		
		Board:SetFrozen(pawnLoc, false, true)
		Board:SetFrozen(mountainLoc, false, true)
		Board:SetFrozen(roadLoc, false, true)
		
		actualPawnUnfrozenState = pawn:IsFrozen()
		actualMountainUnfrozenState = Board:IsFrozen(mountainLoc)
		actualRoadUnfrozenState = Board:IsFrozen(roadLoc)
	end,
	check = function()
		assertEquals(true, actualPawnFrozenState, "Pawn was incorrectly not frozen")
		assertEquals(true, actualMountainFrozenState, "Mountain was incorrectly not frozen")
		assertEquals(false, actualRoadFrozenState, "Road was incorrectly frozen")
		
		assertEquals(false, actualPawnUnfrozenState, "Pawn was incorrectly not unfrozen")
		assertEquals(false, actualMountainUnfrozenState, "Mountain was incorrectly not unfrozen")
		assertEquals(false, actualRoadUnfrozenState, "Road was incorrectly frozen")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetTerrainVanilla(mountainLoc, defaultMountainTerrain)
		Board:SetTerrainVanilla(roadLoc, defaultRoadTerrain)
	end
})

testsuite.test_SetFire_ShouldSetFireToTerrainAndPawns = buildPawnTest({
	-- pawn and tile should light on fire and be extinguished.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		
		pawnLoc = pawn:GetSpace()
		tileLoc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(tileLoc)
		Board:SetTerrainVanilla(tileLoc, TERRAIN_ROAD)
		
		local fx = SkillEffect()
		fx.iFire = EFFECT_REMOVE
		
		fx.loc = pawnLoc; Board:AddEffect(fx)
		fx.loc = tileLoc; Board:AddEffect(fx)
	end,
	execute = function()
		-- Light pawn and tile on fire.
		Board:SetFire(pawnLoc)
		Board:SetFire(tileLoc)
		
		actualPawnFireState = Board:IsFire(pawnLoc)
		actualTileFireState = Board:IsFire(tileLoc)
		
		-- Extinguish pawn and tile.
		Board:SetFire(pawnLoc, false)
		Board:SetFire(tileLoc, false)
		
		actualPawnExtinguishedState = Board:IsFire(pawnLoc)
		actualTileExtinguishedState = Board:IsFire(tileLoc)
	end,
	check = function()
		assertEquals(true, actualPawnFireState, "Pawn was incorrectly not on fire")
		assertEquals(true, actualTileFireState, "Tile was incorrectly not on fire")
		assertEquals(false, actualPawnExtinguishedState, "Pawn was incorrectly not extinguished")
		assertEquals(false, actualTileExtinguishedState, "Tile was incorrectly not extinguished")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetTerrainVanilla(tileLoc, defaultTerrain)
	end
})

testsuite.test_SetShield_ShouldShieldMountainAndPawnButNotRoad = buildPawnTest({
	-- The mountain and pawn should be shielded, but the road should not.
	-- The mountain and pawn should then be unshielded.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		pawnLoc = pawn:GetSpace()
		
		local locations = getBoardLocations()
		mountainLoc = getRandomLocation(locations)
		roadLoc = getRandomLocation(locations)
		
		defaultMountainTerrain = Board:GetTerrain(mountainLoc)
		defaultRoadTerrain = Board:GetTerrain(roadLoc)
		Board:SetTerrainVanilla(mountainLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(roadLoc, TERRAIN_ROAD)
	end,
	execute = function()
		--Board:SetShield(location, shield, no_animation)
		Board:SetShield(pawnLoc, true, true)
		Board:SetShield(mountainLoc, true, true)
		Board:SetShield(roadLoc, true, true)
		
		actualPawnShieldedState = pawn:IsShield()
		actualMountainShieldedState = Board:IsShield(mountainLoc)
		actualRoadShieldedState = Board:IsShield(roadLoc)
		
		Board:SetShield(pawnLoc, false, true)
		Board:SetShield(mountainLoc, false, true)
		Board:SetShield(roadLoc, false, true)
		
		actualPawnUnshieldedState = pawn:IsShield()
		actualMountainUnshieldedState = Board:IsShield(mountainLoc)
		actualRoadUnshieldedState = Board:IsShield(roadLoc)
	end,
	check = function()
		assertEquals(true, actualPawnShieldedState, "Pawn was incorrectly not shielded")
		assertEquals(true, actualMountainShieldedState, "Mountain was incorrectly not shielded")
		assertEquals(false, actualRoadShieldedState, "Road was incorrectly shielded")
		
		assertEquals(false, actualPawnUnshieldedState, "Pawn was incorrectly not unshielded")
		assertEquals(false, actualMountainUnshieldedState, "Mountain was incorrectly not unshielded")
		assertEquals(false, actualRoadUnshieldedState, "Road was incorrectly shielded")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetFrozen(mountainLoc, false)
		Board:SetTerrainVanilla(mountainLoc, defaultMountainTerrain)
		Board:SetTerrainVanilla(roadLoc, defaultRoadTerrain)
	end
})

testsuite.test_SetHealth_SavegameShouldReflectChange = buildPawnTest({
	-- The mountain should have its health set to 0.
	prepare = function()
		loc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(loc)
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		
		expectedHealth = 0
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetHealth(loc, expectedHealth)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTileHealth = tile_data.health_min or tile_data.health_max or 2
		
		assertEquals(expectedHealth, actualTileHealth, "Tile health was incorrect")
	end,
	cleanup = function()
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
	end
})

testsuite.test_SetMaxHealth_SavegameShouldReflectChange = buildPawnTest({
	-- The building should have its max health set to 3.
	prepare = function()
		loc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(loc)
		Board:SetTerrainVanilla(loc, TERRAIN_BUILDING)
		
		expectedMaxHealth = 3
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetMaxHealth(loc, expectedMaxHealth)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTileMaxHealth = tile_data.health_max or 2
		
		assertEquals(expectedMaxHealth, actualTileMaxHealth, "Tile max health was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's potential damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
	end
})

testsuite.test_SetBuilding_SavegameShouldReflectChange = buildPawnTest({
	-- The building should have its health set to 1 and its max health set to 3.
	prepare = function()
		loc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(loc)
		
		expectedTerrain = TERRAIN_BUILDING
		expectedHealth = 1
		expectedMaxHealth = 3
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetBuilding(loc, expectedHealth, expectedMaxHealth)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTerrain = tile_data.terrain
		actualTileHealth = tile_data.health_min or tile_data.health_max or 2
		actualTileMaxHealth = tile_data.health_max or 2
		
		assertEquals(expectedTerrain, actualTerrain, "Terrain was incorrect")
		assertEquals(expectedHealth, actualTileHealth, "Building health was incorrect")
		assertEquals(expectedMaxHealth, actualTileMaxHealth, "Building max health was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
	end
})

testsuite.test_SetMountain_SavegameShouldReflectChange = buildPawnTest({
	-- The mountain should have its health set to 1 and its max health set to 2.
	prepare = function()
		loc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(loc)
		
		expectedTerrain = TERRAIN_MOUNTAIN
		expectedHealth = 1
		expectedMaxHealth = 2
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetMountain(loc, expectedHealth, expectedMaxHealth)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTerrain = tile_data.terrain
		actualTileHealth = tile_data.health_min or tile_data.health_max or 2
		actualTileMaxHealth = tile_data.health_max or 2
		
		assertEquals(expectedTerrain, actualTerrain, "Terrain was incorrect")
		assertEquals(expectedHealth, actualTileHealth, "Mountain health was incorrect")
		assertEquals(expectedMaxHealth, actualTileMaxHealth, "Mountain max health was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
	end
})

testsuite.test_SetIce_SavegameShouldReflectChange = buildPawnTest({
	-- The terrain should become ice, have its health set to 1 and its max health set to 2.
	prepare = function()
		loc = getRandomLocation()
		
		defaultTerrain = Board:GetTerrain(loc)
		
		expectedTerrain = TERRAIN_ICE
		expectedHealth = 1
		expectedMaxHealth = 2
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetIce(loc, expectedHealth, expectedMaxHealth)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTerrain = tile_data.terrain
		actualTileHealth = tile_data.health_min or tile_data.health_max or 2
		actualTileMaxHealth = tile_data.health_max or 2
		
		assertEquals(expectedTerrain, actualTerrain, "Terrain was incorrect")
		assertEquals(expectedHealth, actualTileHealth, "Ice health was incorrect")
		assertEquals(expectedMaxHealth, actualTileMaxHealth, "Ice max health was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
	end
})

testsuite.test_SetRubble_SavegameShouldReflectChange = buildPawnTest({
	-- The mountain should become rubble and have its health set to 0.
	-- The building should become rubble and have its health set to 0.
	-- The rubble should become a building or mountain with its health set to the tile's max health.
	prepare = function()
		local locations = getBoardLocations()
		mountainLoc = getRandomLocation(locations)
		buildingLoc = getRandomLocation(locations)
		rubbleLoc = getRandomLocation(locations)
		
		defaultMountainTerrain = Board:GetTerrain(mountainLoc)
		defaultBuildingTerrain = Board:GetTerrain(buildingLoc)
		defaultRubbleTerrain = Board:GetTerrain(rubbleLoc)
		
		expectedMountainTerrain = TERRAIN_RUBBLE
		expectedBuildingTerrain = TERRAIN_RUBBLE
		
		expectedMountainHealth = 0
		expectedBuildingHealth = 0
		
		Board:SetTerrainVanilla(mountainLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(buildingLoc, TERRAIN_BUILDING)
		Board:SetTerrainVanilla(rubbleLoc, TERRAIN_RUBBLE)
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetRubble(mountainLoc, true)
		Board:SetRubble(buildingLoc, true)
		Board:SetRubble(rubbleLoc, false)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		mountain_tile_data = getTileSaveData(mountainLoc) or {}
		actualMountainTerrain = mountain_tile_data.terrain
		actualMountainHealth = mountain_tile_data.health_min or mountain_tile_data.health_max or 2
		
		building_tile_data = getTileSaveData(buildingLoc) or {}
		actualBuildingTerrain = building_tile_data.terrain
		actualBuildingHealth = building_tile_data.health_min or building_tile_data.health_max or 2
		
		rubble_tile_data = getTileSaveData(rubbleLoc) or {}
		actualRubbleHealth = rubble_tile_data.health_min or rubble_tile_data.health_max or 2
		actualRubbleMaxHealth = rubble_tile_data.health_max or 2
		
		assertEquals(expectedMountainTerrain, actualMountainTerrain, "Mountain terrain did not turn to rubble")
		assertEquals(expectedMountainHealth, actualMountainHealth, "Mountain health did not change to 0")
		
		assertEquals(expectedBuildingTerrain, expectedBuildingTerrain, "Building terrain did not turn to rubble")
		assertEquals(expectedBuildingHealth, actualBuildingHealth, "Building health did not change to 0")
		
		assertEquals(actualRubbleHealth, actualRubbleMaxHealth, "Rubble health did not match max health")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(mountainLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(buildingLoc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(rubbleLoc, TERRAIN_MOUNTAIN)
		
		Board:SetTerrainVanilla(mountainLoc, defaultMountainTerrain)
		Board:SetTerrainVanilla(buildingLoc, defaultBuildingTerrain)
		Board:SetTerrainVanilla(rubbleLoc, defaultRubbleTerrain)
	end
})

testsuite.test_SetUniqueBuilding_SavegameShouldReflectChange = buildPawnTest({
	-- The building should become a bar, and it's health and max health should be 1.
	prepare = function()
		loc = getRandomLocation()
		
		defaulTerrain = Board:GetTerrain(loc)
		
		expectedUniqueBuilding = "str_bar1"
		expectedHealth = 1
		expectedMaxHealth = 1
		
		Board:SetTerrainVanilla(loc, TERRAIN_BUILDING)
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:SetUniqueBuilding(loc, expectedUniqueBuilding)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualUniqueBuilding = tile_data.unique
		actualHealth = tile_data.health_min or tile_data.health_max or 2
		actualMaxHealth = tile_data.health_max or 2
		
		assertEquals(expectedUniqueBuilding, actualUniqueBuilding, "Unique building was incorrect")
		assertEquals(expectedHealth, actualHealth, "Health did not change to 1")
		assertEquals(expectedMaxHealth, actualMaxHealth, "Max health did not change to 1")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaulTerrain)
	end
})

testsuite.test_GetUniqueBuilding_ShouldBeBar = buildPawnTest({
	-- The building should become a bar.
	prepare = function()
		loc = getRandomLocation()
		defaultTerrain = Board:GetTerrain(loc)
		
		buildings = Board:GetBuildingsVanilla()
		
		-- remove all buildings.
		for _, p in ipairs(extract_table(buildings)) do
			Board:SetTerrain(p, TERRAIN_ROAD)
		end
		
		expectedUniqueBuilding = "str_bar1"
		
		-- add a single building that we turn into a bar.
		Board:SetTerrainVanilla(loc, TERRAIN_BUILDING)
		Board:AddUniqueBuilding(expectedUniqueBuilding)
	end,
	execute = function()
		actualUniqueBuilding = Board:GetUniqueBuilding(loc)
	end,
	check = function()
		assertEquals(expectedUniqueBuilding, actualUniqueBuilding, "Unique building was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
		
		for _, p in ipairs(extract_table(buildings)) do
			Board:SetTerrainVanilla(p, TERRAIN_BUILDING)
		end
	end
})

testsuite.test_RemoveUniqueBuilding_SaveGameShouldReflectUniqueBuildingTurnedIntoRegularBuilding = buildPawnTest({
	-- The bar should become a normal building.
	prepare = function()
		loc = getRandomLocation()
		defaultTerrain = Board:GetTerrain(loc)
		
		buildings = Board:GetBuildingsVanilla()
		
		-- remove all buildings.
		for _, p in ipairs(extract_table(buildings)) do
			Board:SetTerrain(p, TERRAIN_ROAD)
		end
		
		expectedTerrain = TERRAIN_BUILDING
		expectedUniqueBuilding = nil
		
		-- add a single building that we turn into a bar.
		Board:SetTerrainVanilla(loc, TERRAIN_BUILDING)
		Board:AddUniqueBuilding("str_bar1")
		
		msTimeout = MS_WAIT_FOR_SAVING_GAME
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		Board:RemoveUniqueBuilding(loc)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait for a while until we can be pretty sure the save game has been updated.
		return modApi:elapsedTime() > endTime
    end,
	check = function()
		tile_data = getTileSaveData(loc) or {}
		actualTerrain = tile_data.terrain
		actualUniqueBuilding = tile_data.unique
		
		assertEquals(expectedTerrain, actualTerrain, "Terrain was incorrect")
		assertEquals(expectedUniqueBuilding, actualUniqueBuilding, "Unique building was incorrect")
	end,
	cleanup = function()
		-- change terrain to mountain first to clear the tile's damaged state.
		Board:SetTerrainVanilla(loc, TERRAIN_MOUNTAIN)
		Board:SetTerrainVanilla(loc, defaultTerrain)
		
		for _, p in ipairs(extract_table(buildings)) do
			Board:SetTerrainVanilla(p, TERRAIN_BUILDING)
		end
	end
})

testsuite.test_IsGameBoard_ShouldReturnTrue = buildPawnTest({
	prepare = function()
		expectedResult = true
	end,
	execute = function()
		actualResult = Board:IsGameBoard()
	end,
	check = function()
		assertEquals(expectedResult, actualResult, "GameBoard state was incorrect")
	end,
})

testsuite.test_SetSnow_ShouldChangeTileToSnow = buildPawnTest({
	prepare = function()
		loc = getRandomLocation(nil, function(p)
			return isValidTile(p) and Board:GetCustomTile(p) == ""
		end)
		
		expectedIsSnow = "snow.png"
		expectedIsNotSnow = ""
	end,
	execute = function()
		Board:SetSnow(loc, true)
		actualIsSnow = Board:GetCustomTile(loc)
		
		Board:SetSnow(loc, false)
		actualIsNotSnow = Board:GetCustomTile(loc)
	end,
	check = function()
		assertEquals(expectedIsSnow, actualIsSnow, "Tile did not change to snow")
		assertEquals(expectedIsNotSnow, actualIsNotSnow, "Tile did not change from snow")
	end,
})

return testsuite
