local pawn = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertTableEquals = Tests.AssertTableEquals
local assertBoardStateEquals = Tests.AssertBoardStateEquals
local requireBoard = Tests.RequireBoard
local getTileState = Tests.GetTileState
local getPawnState = Tests.GetPawnState
local getBoardState = Tests.GetBoardState
local waitUntilBoardNotBusy = Tests.WaitUntilBoardNotBusy


function pawn.test_1(resultTable)
	-- The pawn should be correctly damaged
	requireBoard()
	resultTable = resultTable or {}

	-- Prepare
	local expectedBoardState = getBoardState()

	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)
	local loc = pawn:GetSpace()

	local expectedHealth = pawn:GetHealth() - 1

	-- Execute
	pawn:ApplyDamage(SpaceDamage(1))

	-- Check
	waitUntilBoardNotBusy(resultTable, function()
		local actualHealth = pawn:GetHealth()
		Board:RemovePawn(pawn)

		assertEquals(expectedHealth, actualHealth, "Pawn did not take correct amount of damage")
		assertBoardStateEquals(expectedBoardState, getBoardState(), "Tested operation had side effects")

		LOG("SUCCESS")
		resultTable.result = true
	end)
end

function pawn.test_2(resultTable)
	-- When standing on a forest and receiving safe damage, the pawn should not be set on fire
	requireBoard()
	resultTable = resultTable or {}

	-- Prepare
	local expectedBoardState = getBoardState()

	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)
	local loc = pawn:GetSpace()

	local terrain = Board:GetTerrain(loc)
	Board:SetTerrain(loc, TERRAIN_FOREST)

	-- Execute
	pawn:ApplyDamage(SpaceDamage(1))

	-- Check
	waitUntilBoardNotBusy(resultTable, function()
		local actualFire = pawn:IsFire()
		local actualTerrain = Board:GetTerrain(loc)
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)

		assertEquals(false, actualFire, "Pawn had been set on fire")
		assertEquals(TERRAIN_FOREST, actualTerrain, "Terrain type has been changed")
		assertBoardStateEquals(expectedBoardState, getBoardState(), "Tested operation had side effects")
		
		LOG("SUCCESS")
		resultTable.result = true
	end)
end

function pawn.test_3(resultTable)
	-- Setting a pawn on fire using SetFire(true) should set the pawn on fire, but leave the board unaffected
	requireBoard()
	resultTable = resultTable or {}

	-- Prepare
	local expectedBoardState = getBoardState()

	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)
	local loc = pawn:GetSpace()
	-- Set the terrain to road, in case the pawn spawns on a forest
	-- Since the pawn is set on fire, the forest catches fire as well on next game tick, causing the test to fail
	local terrain = Board:GetTerrain(loc)
	Board:SetTerrain(loc, TERRAIN_ROAD)
	
	-- Execute
	pawn:SetFire(true)

	-- Check
	waitUntilBoardNotBusy(resultTable, function()
		local actualFire = pawn:IsFire()
		Board:RemovePawn(pawn)
		Board:SetTerrain(loc, terrain)

		assertEquals(true, actualFire, "Pawn had not been set on fire")
		assertBoardStateEquals(expectedBoardState, getBoardState(), "Tested operation had side effects")
		
		LOG("SUCCESS")
		resultTable.result = true
	end)
end

function pawn.test_4(resultTable)
	-- Attempting to extinguish a pawn on fire while it is standing on a fire tile should have no effect
	requireBoard()
	resultTable = resultTable or {}

	-- Prepare
	local expectedBoardState = getBoardState()

	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)
	local loc = pawn:GetSpace()
	local terrain = Board:GetTerrain(loc)
	Board:SetFire(loc, true)
	
	-- Execute
	pawn:SetFire(false)

	-- Check
	waitUntilBoardNotBusy(resultTable, function()
		local actualPawnFire = pawn:IsFire()
		local actualBoardFire = Board:IsFire(loc)
		Board:RemovePawn(pawn)
		Board:SetFire(loc, false)
		Board:SetTerrain(loc, terrain)

		assertEquals(true, actualPawnFire, "Pawn had been extinguished")
		assertEquals(true, actualBoardFire, "Board had been extinguished")
		assertBoardStateEquals(expectedBoardState, getBoardState(), "Tested operation had side effects")
		
		LOG("SUCCESS")
		resultTable.result = true
	end)
end


Testsuites.pawn = pawn
