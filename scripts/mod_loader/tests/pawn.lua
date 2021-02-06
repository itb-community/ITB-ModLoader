local testsuite = Tests.Testsuite()
testsuite.name = "Pawn-related tests"

local assertEquals = Assert.Equals
local buildPawnTest = Tests.BuildPawnTest


testsuite.test_ApplyDamage_ShouldReduceHealth = buildPawnTest({
	-- The pawn should be correctly damaged
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()

		expectedHealth = pawn:GetHealth() - 1
	end,
	execute = function()
		pawn:ApplyDamage(SpaceDamage(1))
	end,
	check = function()
		local actualHealth = pawn:GetHealth()

		assertEquals(expectedHealth, actualHealth, "Pawn did not take correct amount of damage")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SafeDamageOnForest_ShouldNotCreateFire = buildPawnTest({
	-- When standing on a forest and receiving safe damage, the pawn should not be set on fire
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()

		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_FOREST)
	end,
	execute = function()
		pawn:ApplyDamage(SpaceDamage(1))
	end,
	check = function()
		local actualFire = pawn:IsFire()
		local actualTerrain = Board:GetTerrain(loc)

		assertEquals(false, actualFire, "Pawn had been set on fire")
		assertEquals(TERRAIN_FOREST, actualTerrain, "Terrain type has been changed")
	end,
	cleanup = function()
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

testsuite.test_PawnSetFire_ShouldNotSetBoardFire = buildPawnTest({
	-- Setting a pawn on fire using SetFire(true) should set the pawn on fire, but leave the board unaffected
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
		-- Set the terrain to road, in case the pawn spawns on a forest
		-- Since the pawn is set on fire, the forest catches fire as well on next game tick, causing the test to fail
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_ROAD)
	end,
	execute = function()
		pawn:SetFire(true)
	end,
	check = function()
		local actualFire = pawn:IsFire()

		assertEquals(true, actualFire, "Pawn had not been set on fire")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetTerrain(loc, terrain)
	end
})

testsuite.test_PawnExtinguishOnFireTile_ShouldRemainOnFire = buildPawnTest({
	-- Attempting to extinguish a pawn on fire while it is standing on a fire tile should have no effect
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_ROAD)
		Board:SetFire(loc, true)
	end,
	execute = function()
		pawn:SetFire(false)
	end,
	check = function()
		local actualPawnFire = pawn:IsFire()
		local actualBoardFire = Board:IsFire(loc)

		assertEquals(true, actualPawnFire, "Pawn had been extinguished")
		assertEquals(true, actualBoardFire, "Board had been extinguished")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetFire(loc, false)
		Board:SetTerrain(loc, terrain)
	end
})

testsuite.test_PawnArmorWithAcid_ShouldReturnTrue = Tests.BuildPawnTest({
	-- BoardPawn:IsArmor() shouldn't check for presence of ACID, since there are cases where
	-- we might want to know whether a pawn has armor, even when it is covered in ACID.
	prepare = function()
		pawnId = Board:SpawnPawn("JudoMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_ROAD)
	end,
	execute = function()
		pawn:SetAcid(true)
	end,
	check = function()
		isArmor = pawn:IsArmor()
		Assert.Equals(true, isArmor, "BoardPawn.IsArmor returned false for a pawn covered in ACID")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		Board:SetTerrain(loc, terrain)
	end
})

return testsuite
