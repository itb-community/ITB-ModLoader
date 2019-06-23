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

Testsuites.pawn = pawn
