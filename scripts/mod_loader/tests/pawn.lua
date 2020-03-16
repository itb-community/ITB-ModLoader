local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local buildPawnTest = Tests.BuildPawnTest


testsuite.test_ApplyDamage_ShouldReduceHealth = buildPawnTest(
	-- The pawn should be correctly damaged
	function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()

		expectedHealth = pawn:GetHealth() - 1
	end,
	function()
		pawn:ApplyDamage(SpaceDamage(1))
	end,
	function()
		local actualHealth = pawn:GetHealth()
		Board:RemovePawn(pawn)

		assertEquals(expectedHealth, actualHealth, "Pawn did not take correct amount of damage")
	end
)

testsuite.test_SafeDamageOnForest_ShouldNotCreateFire = buildPawnTest(
	-- When standing on a forest and receiving safe damage, the pawn should not be set on fire
	function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
	
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_FOREST)
	end,
	function()
		pawn:ApplyDamage(SpaceDamage(1))
	end,
	function()
		local actualFire = pawn:IsFire()
		local actualTerrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)

		assertEquals(false, actualFire, "Pawn had been set on fire")
		assertEquals(TERRAIN_FOREST, actualTerrain, "Terrain type has been changed")
	end
)

testsuite.test_PawnSetFire_ShouldNotSetBoardFire = buildPawnTest(
	-- Setting a pawn on fire using SetFire(true) should set the pawn on fire, but leave the board unaffected
	function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
		-- Set the terrain to road, in case the pawn spawns on a forest
		-- Since the pawn is set on fire, the forest catches fire as well on next game tick, causing the test to fail
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_ROAD)
	end,
	function()
		pawn:SetFire(true)
	end,
	function()
		local actualFire = pawn:IsFire()
		Board:RemovePawn(pawn)
		Board:SetTerrain(loc, terrain)

		assertEquals(true, actualFire, "Pawn had not been set on fire")
	end
)

testsuite.test_PawnExtinguishOnFireTile_ShouldRemainOnFire = buildPawnTest(
	-- Attempting to extinguish a pawn on fire while it is standing on a fire tile should have no effect
	function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()
		terrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, TERRAIN_ROAD)
		Board:SetFire(loc, true)
	end,
	function()
		pawn:SetFire(false)
	end,
	function()
		local actualPawnFire = pawn:IsFire()
		local actualBoardFire = Board:IsFire(loc)
		Board:RemovePawn(pawn)
		Board:SetFire(loc, false)
		Board:SetTerrain(loc, terrain)

		assertEquals(true, actualPawnFire, "Pawn had been extinguished")
		assertEquals(true, actualBoardFire, "Board had been extinguished")
	end
)

return testsuite
