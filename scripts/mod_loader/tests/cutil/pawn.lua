local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals
local buildPawnTest = Tests.BuildPawnTest

testsuite.test_WhenIncreasingMaxHealth_CurrentHealthShouldRemainUnchanged = buildPawnTest({
	-- The pawn should have its max health increased, but current health should remain at its old value.
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()

		assertEquals(3, pawn:GetHealth(), "Pawn did not have the expected starting max health value")

		expectedHealth = pawn:GetHealth()
		expectedMaxHealth = 5
	end,
	execute = function()
		pawn:SetMaxHealth(expectedMaxHealth)
	end,
	check = function()
		assertNotEquals(expectedHealth, pawn:GetMaxHealth(), "Pawn's max health was not changed")
		assertEquals(expectedMaxHealth, pawn:GetMaxHealth(), "Pawn's max health was not changed")
		assertEquals(expectedHealth, pawn:GetHealth(), "Pawn's current health was changed")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_WhenIncreasingMaxHealth_ShouldSurviveHitForOldMaxHealth = buildPawnTest({
	-- The pawn should have its max health increased, and survive a hit equal to its old health after being healed up
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)
		loc = pawn:GetSpace()

		assertEquals(3, pawn:GetHealth(), "Pawn did not have the expected starting max health value")

		oldHealth = pawn:GetHealth()
		newMaxHealth = 5
		expectedHealth = newMaxHealth - oldHealth
	end,
	execute = function()
		pawn:SetMaxHealth(newMaxHealth)
		-- SetMaxHealth does not change the pawn's current health; heal it back up first.
		pawn:ApplyDamage(SpaceDamage(-newMaxHealth))
		pawn:ApplyDamage(SpaceDamage(oldHealth))
	end,
	check = function()
		assertEquals(false, pawn:IsDead(), "Pawn's max health was not increased; pawn is dead")
		assertEquals(expectedHealth, pawn:GetHealth(), "Pawn's max health was not increased; remaining health mismatch'")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

return testsuite
