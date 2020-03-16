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

testsuite.test_WeaponCount_ShouldCountWeapons_WhenNoWeapons = buildPawnTest({
	globalSetup = function()
		Testsuites_NoWeaponPawn = PunchMech:new({
			SkillList = {}
		})
	end,
	prepare = function()
		pawnId = Board:SpawnPawn("Testsuites_NoWeaponPawn")
		pawn = Board:GetPawn(pawnId)

		expectedWeaponCount = 0
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end,
	globalCleanup = function()
		Testsuites_NoWeaponPawn = nil
	end
})

testsuite.test_WeaponCount_ShouldCountWeapons_WhenOneWeapon = buildPawnTest({
	prepare = function()
		pawnId = Board:SpawnPawn("PunchMech")
		pawn = Board:GetPawn(pawnId)

		expectedWeaponCount = 1
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_WeaponCount_ShouldCountWeapons_WhenTwoWeapons = buildPawnTest({
	prepare = function()
		pawnId = Board:SpawnPawn("RocketMech")
		pawn = Board:GetPawn(pawnId)

		expectedWeaponCount = 2
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SpawnedMinions_ShouldHaveOwnerSetToPawnThatCreatedThem = buildPawnTest({
	prepare = function()
		caster = PAWN_FACTORY:CreatePawn("Spider1")
		caster:SetTeam(TEAM_PLAYER)
		Board:AddPawn(caster)
		casterLoc = caster:GetSpace()
		expectedOwnerId = caster:GetId()

		local weaponType = caster:GetWeaponType(1)
		local weaponTable = _G[weaponType]
		local plist = weaponTable:GetTargetArea(caster:GetSpace())
		targetLoc = random_element(extract_table(plist))

		casterTerrain = Board:GetTerrain(casterLoc)
		targetTerrain = Board:GetTerrain(targetLoc)
		Board:SetTerrain(casterLoc, TERRAIN_ROAD)
		Board:SetTerrain(targetLoc, TERRAIN_ROAD)
	end,
	execute = function()
		caster:FireWeapon(targetLoc, 1)
	end,
	check = function()
		target = Board:GetPawn(targetLoc)
		ownerId = target:GetOwner()

		assertEquals(expectedOwnerId, ownerId, "GetOwner() reported incorrect owner")
	end,
	cleanup = function()
		Board:RemovePawn(caster)
		Board:RemovePawn(target)
		Board:SetTerrain(casterLoc, casterTerrain)
		Board:SetTerrain(targetLoc, targetTerrain)
	end
})

return testsuite
