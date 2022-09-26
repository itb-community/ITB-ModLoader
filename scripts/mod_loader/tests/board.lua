local testsuite = Tests.Testsuite()
testsuite.name = "Board-related tests"

local getMemedit = modApi.getMemedit


testsuite.test_GetFireType = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local memedit = getMemedit()

	if memedit then
		Board:ClearSpace(p)
		Board:SetFire(p, false)
		local fireType_None = Board:GetFireType(p)

		Board:ClearSpace(p)
		Board:SetFire(p, true)
		local fireType_NormalFire = Board:GetFireType(p)

		Board:ClearSpace(p)
		Board:SetTerrain(p, TERRAIN_FOREST)
		Board:SetFire(p, true)
		local fireType_ForestFire = Board:GetFireType(p)

		Assert.Equals(FIRE_TYPE_NONE, fireType_None)
		Assert.Equals(FIRE_TYPE_NORMAL_FIRE, fireType_NormalFire)
		Assert.Equals(FIRE_TYPE_FOREST_FIRE, fireType_ForestFire)

		Board:ClearSpace(p)
	else
		Assert.ShouldError(Board.GetFireType, {Board, p}, "Function should fail without memedit")
	end

	return true
end

testsuite.test_GetTerrainIcon = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local memedit = getMemedit()

	if memedit then
		Board:SetTerrainIcon(p, "terrainIcon_Test")
		local terrainIcon_Test = Board:GetTerrainIcon(p)

		Board:SetTerrainIcon(p, "")
		local terrainIcon_None = Board:GetTerrainIcon(p)

		Assert.Equals("", terrainIcon_None)
		Assert.Equals("terrainIcon_Test", terrainIcon_Test)

		Board:SetTerrainIcon(p,"")
	else
		Assert.ShouldError(Board.GetTerrainIcon, {Board, p}, "Function should fail without memedit")
	end

	return true
end

testsuite.test_IsForest = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local memedit = getMemedit()

	if memedit then
		Board:SetTerrain(p, TERRAIN_FOREST)
		local isForest = Board:IsForest(p)

		Board:SetTerrain(p, TERRAIN_ROAD)
		local isNotForest = not Board:IsForest(p)

		Assert.Equals(true, isForest)
		Assert.Equals(true, isNotForest)

		Board:ClearSpace(p)
	else
		Assert.ShouldError(Board.IsForest, {Board, p}, "Function should fail without memedit")
	end

	return true
end

testsuite.test_IsForestFire = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local memedit = getMemedit()

	if memedit then
		Board:SetTerrain(p, TERRAIN_FOREST)
		Board:SetFire(p, true)
		local isForestFire = Board:IsForestFire(p)

		Board:ClearSpace(p)
		Board:SetTerrain(p, TERRAIN_ROAD)
		Board:SetFire(p, true)
		local isNotForestFire = not Board:IsForestFire(p)

		Assert.Equals(true, isForestFire)
		Assert.Equals(true, isNotForestFire)

		Board:ClearSpace(p)
	else
		Assert.ShouldError(Board.IsForestFire, {Board, p}, "Function should fail without memedit")
	end

	return true
end

testsuite.test_IsShield = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local memedit = getMemedit()

	if memedit then
		Board:ClearSpace(p)
		Board:SetTerrain(p, TERRAIN_MOUNTAIN)
		Board:AddShield(p)
		local isShielded = Board:IsShield(p)

		Board:ClearSpace(p)
		Board:SetTerrain(p, TERRAIN_MOUNTAIN)
		Board:AddShield(p)
		Board:RemoveShield(p)
		local isUnshielded = not Board:IsShield(p)

		Board:ClearSpace(p)
		Board:SetTerrain(p, TERRAIN_ROAD)
		local isUnshieldable = not Board:IsShield(p)

		Assert.Equals(true, isShielded)
		Assert.Equals(true, isUnshielded)
		Assert.Equals(true, isUnshieldable)

		Board:ClearSpace(p)
	else
		Assert.ShouldError(Board.IsShield, {Board, p}, "Function should fail without memedit")
	end

	return true
end

testsuite.test_SetAcid = function()
	Tests.RequireBoard()
	local p = Tests.GetCleanTile()
	local skipAnimation = true

	Board:ClearSpace(p)
	Board:SetAcid(p, true, skipAnimation)
	local isAcid = Board:IsAcid(p)

	Board:ClearSpace(p)
	Board:SetAcid(p, false, skipAnimation)
	local isNotAcid = not Board:IsAcid(p)

	Assert.Equals(true, isAcid)
	Assert.Equals(true, isNotAcid)

	Board:ClearSpace(p)

	return true
end

testsuite.test_SetFrozen = function()
	Tests.RequireBoard()
	local p = Tests.GetNonUniqueBuildingTile()
	local skipAnimation = true
	local damage = SpaceDamage(p, 1)

	Board:ClearSpace(p)
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	Board:SetFrozen(p, true, skipAnimation)
	Board:DamageSpace(damage)
	local undamagedMountainHp = Board:GetHealth(p)

	Board:ClearSpace(p)
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	Board:SetFrozen(p, false, skipAnimation)
	Board:DamageSpace(damage)
	local damagedMountainHp = Board:GetHealth(p)

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	local maxHealth = pawn:GetHealth()
	Board:ClearSpace(p)
	Board:AddPawn(pawn, p)
	Board:SetFrozen(p, true, skipAnimation)
	Board:DamageSpace(damage)
	local undamagedPawnHp = pawn:GetHealth()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	local maxHealth = pawn:GetHealth()
	Board:ClearSpace(p)
	Board:AddPawn(pawn, p)
	Board:SetFrozen(p, false, skipAnimation)
	Board:DamageSpace(damage)
	local damagedPawnHp = pawn:GetHealth()

	Assert.Equals(2, undamagedMountainHp)
	Assert.Equals(1, damagedMountainHp)
	Assert.Equals(maxHealth, undamagedPawnHp)
	Assert.Equals(maxHealth - 1, damagedPawnHp)

	Board:ClearSpace(p)

	return true
end

testsuite.test_SetShield = function()
	Tests.RequireBoard()
	local p = Tests.GetNonUniqueBuildingTile()
	local skipAnimation = true
	local damage = SpaceDamage(p, 1)

	Board:ClearSpace(p)
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	Board:SetShield(p, true, skipAnimation)
	Board:DamageSpace(damage)
	local undamagedMountainHp = Board:GetHealth(p)

	Board:ClearSpace(p)
	Board:SetTerrain(p, TERRAIN_MOUNTAIN)
	Board:SetShield(p, false, skipAnimation)
	Board:DamageSpace(damage)
	local damagedMountainHp = Board:GetHealth(p)

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	local maxHealth = pawn:GetHealth()
	Board:ClearSpace(p)
	Board:AddPawn(pawn, p)
	Board:SetShield(p, true, skipAnimation)
	Board:DamageSpace(damage)
	local undamagedPawnHp = pawn:GetHealth()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	local maxHealth = pawn:GetHealth()
	Board:ClearSpace(p)
	Board:AddPawn(pawn, p)
	Board:SetShield(p, false, skipAnimation)
	Board:DamageSpace(damage)
	local damagedPawnHp = pawn:GetHealth()

	Assert.Equals(2, undamagedMountainHp)
	Assert.Equals(1, damagedMountainHp)
	Assert.Equals(maxHealth, undamagedPawnHp)
	Assert.Equals(maxHealth - 1, damagedPawnHp)

	Board:ClearSpace(p)

	return true
end

return testsuite
