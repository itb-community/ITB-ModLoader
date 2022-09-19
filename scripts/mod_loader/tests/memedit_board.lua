local testsuite = Tests.Testsuite()
testsuite.name = "Memedit-generated-board-functions tests"


testsuite.test_tile_acid = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()

	Board:SetAcid(p, true)
	local isAcid = modApi.memedit.dll.board.isAcid(p)
	Assert.Equals(true, isAcid)

	Board:SetAcid(p, false)
	local isNotAcid = not modApi.memedit.dll.board.isAcid(p)
	Assert.Equals(true, isNotAcid)

	return true
end

testsuite.test_tile_frozen = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)

	Board:SetFrozen(p, true)
	local isFrozen = modApi.memedit.dll.board.isFrozen(p)
	Assert.Equals(true, isFrozen)

	Board:SetFrozen(p, false)
	local isNotFrozen = not modApi.memedit.dll.board.isFrozen(p)
	Assert.Equals(true, isNotFrozen)

	return true
end

testsuite.test_tile_health = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetNonUniqueBuildingTile()

	Board:SetTerrain(p, TERRAIN_BUILDING)
	Board:SetHealth(p, 3,4)
	local health = modApi.memedit.dll.board.getHealth(p)
	local maxHealth = modApi.memedit.dll.board.getMaxHealth(p)
	Assert.Equals(3, health)
	Assert.Equals(4, maxHealth)

	Board:ClearSpace(p)
	return true
end

testsuite.test_tile_rubbleType = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetNonUniqueBuildingTile()

	Board:SetTerrain(p, TERRAIN_BUILDING)
	Board:SetTerrain(p, TERRAIN_RUBBLE)
	local rubbleTypeBuilding = modApi.memedit.dll.board.getRubbleType(p)
	Assert.Equals(0, rubbleTypeBuilding)

	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	Board:SetTerrain(p, TERRAIN_RUBBLE)
	local rubbleTypeMountain = modApi.memedit.dll.board.getRubbleType(p)
	Assert.Equals(1, rubbleTypeMountain)

	Board:ClearSpace(p)
	return true
end

testsuite.test_tile_shield = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)

	Board:SetShield(p, true)
	local isShield = modApi.memedit.dll.board.isShield(p)
	Assert.Equals(true, isShield)

	Board:SetShield(p, false)
	local isNotShield = not modApi.memedit.dll.board.isShield(p)
	Assert.Equals(true, isNotShield)

	return true
end

testsuite.test_tile_smoke = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()

	Board:SetSmoke(p, true, true)
	local isSmoke = modApi.memedit.dll.board.isSmoke(p)
	Assert.Equals(true, isSmoke)

	Board:SetSmoke(p, false, true)
	local isNotSmoke = not modApi.memedit.dll.board.isSmoke(p)
	Assert.Equals(true, isNotSmoke)

	return true
end

testsuite.test_tile_terrain = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()

	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	local terrain = modApi.memedit.dll.board.getTerrain(p)
	Assert.Equals(TERRAIN_MOUNTAIN, terrain)

	Board:ClearSpace(p)
	return true
end

testsuite.test_tile_terrainIcon = function()
	Tests.RequireBoard()
	Tests.RequireMemedit()
	local p = Tests.GetCleanTile()

	Board:SetTerrainIcon(p, "testTerrainIcon")
	local terrainIcon = modApi.memedit.dll.board.getTerrainIcon(p)
	Assert.Equals("testTerrainIcon", terrainIcon)

	Board:SetTerrainIcon(p, "")
	local terrainIcon = modApi.memedit.dll.board.getTerrainIcon(p)
	Assert.Equals("", terrainIcon)

	return true
end


return testsuite
