local pawn = Tests.BoardTestsuite()

local assertEquals = Tests.AssertEquals
local requireBoard = Tests.RequireBoard
local getTileState = Tests.GetTileState
local assertTileStateEquals = Tests.AssertTileStateEquals
local safeRunLater = Tests.SafeRunLater

function pawn.test_1(resultTable)
	-- The pawn should be correctly damaged
	requireBoard()
	resultTable = resultTable or {}

	-- Prepare
	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)
	local loc = pawn:GetSpace()

	local expectedHealth = pawn:GetHealth() - 1
	local expectedTileState = getTileState(loc)

	-- Execute
	pawn:ApplyDamage(SpaceDamage(1))

	-- Check
	safeRunLater(resultTable, function()
		local actualTileState = getTileState(loc)
		local actualHealth = pawn:GetHealth()
		
		Board:RemovePawn(pawn)
		
		assertEquals(expectedHealth, actualHealth)
		assertTileStateEquals(expectedTileState, actualTileState)
		
		LOG("SUCCESS")
		resultTable.result = true
	end)
end

Testsuites.pawn = pawn
