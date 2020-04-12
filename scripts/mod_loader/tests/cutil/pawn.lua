local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals
local buildPawnTest = Tests.BuildPawnTest

local function getRandomTarget(skillTable, caster, casterLoc)
	local oldPawn = Pawn
	Pawn = caster
	casterLoc = casterLoc or Pawn:GetSpace()
	local plist = skillTable:GetTargetArea(casterLoc)
	Pawn = oldPawn
	return random_element(extract_table(plist))
end

local function OrderPawnToMoveTo(caster, targetLoc)
	local oldPawn = Pawn
	Pawn = caster
	caster:FireWeapon(targetLoc, 0)
	caster = oldPawn
end

testsuite.test_IsPlayerControlled_ShouldReturnTrueIfPlayerCanIssueOrders = buildPawnTest({
	-- The mech unit should be controllable by default, but be uncontrollable after attacking.
	-- The vek unit should be uncontrollable by default.
	prepare = function()
		mechPawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		expectedMechControl = _G[mechPawn:GetType()].DefaultTeam == TEAM_PLAYER
		expectedVekControl = _G[vekPawn:GetType()].DefaultTeam == TEAM_PLAYER
		expectedInactiveMechControl = false
		
		targetLoc = getRandomTarget(Prime_Punchmech, mechPawn)
	end,
	execute = function()
		modApi:runLater(function()
			actualMechControl = mechPawn:IsPlayerControlled()
			actualVekControl = vekPawn:IsPlayerControlled()
			
			-- Firing a weapon should remove player control from the mech when the SkillEffect has finished. Exception to this rule is when a pilot still allows further actions.
			mechPawn:FireWeapon(targetLoc, 1)
		end)
	end,
	check = function()
		assertEquals(expectedMechControl, actualMechControl, "IsPlayerControlled() returned incorrect default control state for mech")
		assertEquals(expectedVekControl, actualVekControl, "IsPlayerControlled() returned incorrect default control state for vek")
		assertEquals(expectedInactiveMechControl, mechPawn:IsPlayerControlled(), "IsPlayerControlled() returned incorrect control state for inactive mech")
	end,
	cleanup = function()
		Board:RemovePawn(mechPawn)
		Board:RemovePawn(vekPawn)
	end
})

testsuite.test_GetMaxHealth_ShouldBeEqualToFullyHealedPawn = buildPawnTest({
	-- The pawn's max health should be the same as the pawn's current health at pawn creation, as well as after fully healed.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))

		expectedInitialMaxHealth = pawn:GetHealth()
	end,
	execute = function()
		-- kill pawn and heal it back up to full.
		pawn:ApplyDamage(SpaceDamage(expectedInitialMaxHealth))
		pawn:ApplyDamage(SpaceDamage(-INT_MAX))
		
		expectedHealedMaxHealth = pawn:GetHealth()
	end,
	check = function()
		assertEquals(expectedInitialMaxHealth, pawn:GetMaxHealth(), "Pawn's max health differed from initial health")
		assertEquals(expectedHealedMaxHealth, pawn:GetMaxHealth(), "Pawn's max health differed after fully healed")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_WhenIncreasingMaxHealth_CurrentHealthShouldRemainUnchanged = buildPawnTest({
	-- The pawn should have its max health increased, but current health should remain at its old value.
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("PunchMech")

		expectedHealth = _G[pawn:GetType()].Health
		expectedMaxHealth = expectedHealth + 2
	end,
	execute = function()
		pawn:SetMaxHealth(expectedMaxHealth)
	end,
	check = function()
		assertNotEquals(expectedHealth, pawn:GetMaxHealth(), "Pawn's max health was not changed")
		assertEquals(expectedMaxHealth, pawn:GetMaxHealth(), "Pawn's max health was not changed")
		assertEquals(expectedHealth, pawn:GetHealth(), "Pawn's current health was changed")
	end
})

testsuite.test_WhenIncreasingMaxHealth_ShouldSurviveHitForOldMaxHealth = buildPawnTest({
	-- The pawn should have its max health increased, and survive a hit equal to its old health after being healed up
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))

		oldHealth = pawn:GetHealth()
		newMaxHealth = _G[pawn:GetType()].Health + 2

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
		pawn = PAWN_FACTORY:CreatePawn("Testsuites_NoWeaponPawn")

		expectedWeaponCount = 0
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end,
	globalCleanup = function()
		Testsuites_NoWeaponPawn = nil
	end
})

testsuite.test_WeaponCount_ShouldCountWeapons_WhenOneWeapon = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("PunchMech")

		expectedWeaponCount = 1
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end
})

testsuite.test_WeaponCount_ShouldCountWeapons_WhenTwoWeapons = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("RocketMech")

		expectedWeaponCount = 2
	end,
	execute = function()
		actualWeaponCount = pawn:GetWeaponCount()
	end,
	check = function()
		assertEquals(expectedWeaponCount, actualWeaponCount, "GetWeaponCount() reported incorrect number of weapons")
	end
})

testsuite.test_GetWeaponType_ShouldReturnCorrectWeapons = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("RocketMech")

		local ptable = _G[pawn:GetType()]
		expectedWeapon1 = ptable.SkillList[1]
		expectedWeapon2 = ptable.SkillList[2]
	end,
	execute = function()
		actualWeapon1 = pawn:GetWeaponType(1)
		actualWeapon2 = pawn:GetWeaponType(2)
	end,
	check = function()
		assertEquals(expectedWeapon1, actualWeapon1, "GetWeaponType(1) returned incorrect weapons")
		assertEquals(expectedWeapon2, actualWeapon2, "GetWeaponType(2) returned incorrect weapons")
	end
})

testsuite.test_SpawnedMinions_ShouldHaveOwnerSetToPawnThatCreatedThem = buildPawnTest({
	prepare = function()
		caster = Board:GetPawn(Board:AddPawn("Spider1"))
		caster:SetTeam(TEAM_PLAYER)
		casterLoc = caster:GetSpace()
		expectedOwnerId = caster:GetId()

		local weaponType = caster:GetWeaponType(1)
		targetLoc = getRandomTarget(_G[weaponType], caster)

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
		Board:SetTerrain(casterLoc, casterTerrain)
		if target then
			Board:RemovePawn(target)
		end
		Board:SetTerrain(targetLoc, targetTerrain)
	end
})

testsuite.test_SetOwner_ShouldChangeOwner = buildPawnTest({
	prepare = function()
		-- Pawns have to exist on the board, otherwise the minion gets assigned -1 as owner.
		owner = Board:GetPawn(Board:AddPawn("PunchMech"))
		minion = Board:GetPawn(Board:AddPawn("PunchMech"))

		expectedPawnId = owner:GetId()
	end,
	execute = function()
		minion:SetOwner(expectedPawnId)
	end,
	check = function()
		local actualOwnerId = minion:GetOwner()
		assertEquals(expectedPawnId, actualOwnerId, "SetOwner() did not change pawn owner")
	end,
	cleanup = function()
		Board:RemovePawn(owner)
		Board:RemovePawn(minion)
	end
})

testsuite.test_GetImpactMaterial_ShouldReturnCorrectImpactMaterial = buildPawnTest({
	prepare = function()
		mechPawn = PAWN_FACTORY:CreatePawn("PunchMech")
		vekPawn = PAWN_FACTORY:CreatePawn("Scorpion1")

		expectedMechImpactMaterial = _G[mechPawn:GetType()].ImpactMaterial
		expectedVekImpactMaterial = _G[vekPawn:GetType()].ImpactMaterial
	end,
	execute = function()
		actualMechImpactMaterial = mechPawn:GetImpactMaterial()
		actualVekImpactMaterial = vekPawn:GetImpactMaterial()
	end,
	check = function()
		assertEquals(expectedMechImpactMaterial, actualMechImpactMaterial, "GetImpactMaterial() returned incorrect impact material")
		assertEquals(expectedVekImpactMaterial, actualVekImpactMaterial, "GetImpactMaterial() returned incorrect impact material")
	end
})

testsuite.test_SetImpactMaterial_ShouldChangeImpactMaterial = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("PunchMech")

		expectedImpactMaterial = IMPACT_INSECT
		originalImpactMaterial = _G[pawn:GetType()].ImpactMaterial
	end,
	execute = function()
		pawn:SetImpactMaterial(expectedImpactMaterial)
	end,
	check = function()
		local actualImpactMaterial = pawn:GetImpactMaterial()

		assertEquals(expectedImpactMaterial, actualImpactMaterial, "SetImpactMaterial() did not change impact material")
		assertEquals(originalImpactMaterial, PunchMech.ImpactMaterial, "SetImpactMaterial() changed impact material on the pawn table")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_GetColor_ShouldReturnSquadColor = buildPawnTest({
	prepare = function()
		pawns = {}
		expectedColors = {}
		actualColors = {}

		for i = 0, 7 do
			local squad = getStartingSquad(i)
			local pawnType = squad[2]
			pawns[i] = PAWN_FACTORY:CreatePawn(pawnType)
			expectedColors[i] = _G[pawnType].ImageOffset
		end
	end,
	execute = function()
		for i = 0, 7 do
			actualColors[i] = pawns[i]:GetColor()
		end
	end,
	check = function()
		for i = 0, 7 do
			assertEquals(expectedColors[i], actualColors[i], "GetColor() returned incorrect color")
		end
	end
})

testsuite.test_SetColor_ShouldChangeColor = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("PunchMech")
		pawnTable = _G[pawn:GetType()]

		expectedSquadColor = pawnTable.ImageOffset
		expectedPawnColor = expectedSquadColor + 1
	end,
	execute = function()
		pawn:SetColor(expectedPawnColor)
	end,
	check = function()
		local actualPawnColor = pawn:GetColor()

		assertEquals(expectedPawnColor, actualPawnColor, "SetColor() did not change pawn color")
		assertEquals(expectedSquadColor, pawnTable.ImageOffset, "SetColor() changed ImageOffset on the pawn type table")
	end
})

testsuite.test_GetMassive = buildPawnTest({
	prepare = function()
		pawnMech = PAWN_FACTORY:CreatePawn("PunchMech")
		pawnTableMech = _G[pawnMech:GetType()]

		pawnVek = PAWN_FACTORY:CreatePawn("Scorpion1")
		pawnTableVek = _G[pawnVek:GetType()]

		expectedMassiveMech = pawnTableMech.Massive
		expectedMassiveVek = pawnTableVek.Massive
	end,
	execute = function()
		actualMassiveMech = pawnMech:IsMassive()
		actualMassiveVek = pawnVek:IsMassive()
	end,
	check = function()
		assertEquals(expectedMassiveMech, actualMassiveMech, "IsMassive() returned incorrect value")
		assertEquals(expectedMassiveVek, actualMassiveVek, "IsMassive() returned incorrect value")
	end
})

testsuite.test_SetMassiveTrue_ShouldPreventDrowning = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		loc = pawn:GetSpace()

		terrain = Board:GetTerrain(loc)

		assertNotEquals(true, _G[pawn:GetType()].Massive, "Assumed pawn would not be Massive")
	end,
	execute = function()
		pawn:SetMassive(true)

		Board:SetTerrain(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(true, pawn:IsMassive(), "SetMassive() did not change pawn Massive status")
		assertEquals(false, pawn:IsDead(), "Pawn changed into Massive using SetMassive() died in water")
	end,
	cleanup = function()
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetMassiveFalse_ShouldDrown = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		loc = pawn:GetSpace()

		terrain = Board:GetTerrain(loc)

		assertEquals(true, _G[pawn:GetType()].Massive, "Assumed pawn would be Massive")
	end,
	execute = function()
		pawn:SetMassive(false)

		Board:SetTerrain(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(false, pawn:IsMassive(), "SetMassive() did not change pawn Massive status")
		assertEquals(true, pawn:IsDead(), "Pawn changed into non-Massive using SetMassive() did not die in water")
	end,
	cleanup = function()
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

testsuite.test_IsMovementAvailable_ShouldReturnFalse_AfterMoving = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		expectedLoc = getRandomTarget(Move, pawn)

		assertEquals(true, pawn:IsMovementAvailable(), "Assumed pawn would be able to move after creation")
	end,
	execute = function()
		OrderPawnToMoveTo(pawn, expectedLoc)
	end,
	check = function()
		assertEquals(expectedLoc, pawn:GetSpace(), "Pawn did not move to the expected location")
		assertEquals(false, pawn:IsMovementAvailable(), "IsMovementAvailable() returned incorrect value")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetMovementAvailableFalse_ShouldPreventMovement = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		expectedLoc = pawn:GetSpace()
		targetLoc = getRandomTarget(Move, pawn)

		assertEquals(true, pawn:IsMovementAvailable(), "Assumed pawn would be able to move after creation")
	end,
	execute = function()
		pawn:SetMovementAvailable(false)

		pawn:SetActive(true)
		pawn:Move(targetLoc)
	end,
	check = function()
		assertEquals(expectedLoc, pawn:GetSpace(), "SetMovementAvailable(false) did not prevent pawn movement - pawn moved from its location")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetMovementAvailableTrue_ShouldAllowPawnToMoveAgain = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		expectedLoc = pawn:GetSpace()
		targetLoc = getRandomTarget(Move, pawn)

		assertEquals(true, pawn:IsMovementAvailable(), "Assumed pawn would be able to move after creation")
	end,
	execute = function()
		-- pawn:FireWeapon() uses up movement token, but doesn't respect it being false.
		OrderPawnToMoveTo(pawn, expectedLoc)

		pawn:SetMovementAvailable(true)

		-- pawn:Move() respects movement token being false, but doesn't use it up.
		pawn:SetActive(true)
		pawn:Move(expectedLoc)
	end,
	check = function()
		assertEquals(expectedLoc, pawn:GetSpace(), "SetMovementAvailable(true) did not restore pawn movement token - pawn did not return to its starting location")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetFlyingTrue_ShouldPreventDrowning = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		loc = pawn:GetSpace()
		terrain = Board:GetTerrain(loc)

		assertNotEquals(true, _G[pawn:GetType()].Flying, "Assumed pawn would not be Flying")
	end,
	execute = function()
		pawn:SetFlying(true)

		Board:SetTerrain(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(true, pawn:IsFlying(), "SetFlying() did not change pawn Flying status")
		assertEquals(false, pawn:IsDead(), "Pawn changed into Flying using SetFlying() died in water")
	end,
	cleanup = function()
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetFlyingFalse_ShouldDrown = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Hornet1"))

		loc = pawn:GetSpace()
		terrain = Board:GetTerrain(loc)

		assertEquals(true, _G[pawn:GetType()].Flying, "Assumed pawn would be Flying")
	end,
	execute = function()
		pawn:SetFlying(false)

		Board:SetTerrain(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(false, pawn:IsFlying(), "SetFlying() did not change pawn Flying status")
		assertEquals(true, pawn:IsDead(), "Pawn changed into non-Flying using SetFlying() did not die in water")
	end,
	cleanup = function()
		Board:SetTerrain(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

return testsuite
