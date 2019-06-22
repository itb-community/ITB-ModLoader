local pawn = Tests.BoardTestsuite()

local assertEquals = Tests.AssertEquals

local function requireBoard()
	assert(Board ~= nil, "Error: this test requires a Board to be available")
end

function pawn.test_1(resultTable)
	-- The pawn should be correctly damaged
	requireBoard()

	local pawnId = Board:SpawnPawn("PunchMech")
	local pawn = Board:GetPawn(pawnId)

	local health = pawn:GetHealth()

	local dmg = SpaceDamage(1)
	pawn:ApplyDamage(dmg)

	modApi:runLater(function()
		local healthAfter = pawn:GetHealth()
		Board:RemovePawn(pawn)

		assertEquals(health - dmg.iDamage, healthAfter)

		LOG("SUCCESS")
		resultTable.result = true
	end)
end

Testsuites.pawn = pawn
