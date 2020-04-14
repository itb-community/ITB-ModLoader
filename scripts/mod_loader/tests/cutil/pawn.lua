local testsuite = Tests.Testsuite()

local assertEquals = Tests.AssertEquals
local assertNotEquals = Tests.AssertNotEquals
local buildPawnTest = Tests.BuildPawnTest

local MS_WAIT_TIMEOUT = 1000

local function getRandomTarget(skillTable, caster, casterLoc)
	local oldPawn = Pawn
	Pawn = caster
	casterLoc = casterLoc or Pawn:GetSpace()
	local plist = skillTable:GetTargetArea(casterLoc)
	Pawn = oldPawn
	return random_element(extract_table(plist))
end

local function orderPawnToMoveTo(caster, targetLoc)
	local oldPawn = Pawn
	Pawn = caster
	caster:FireWeapon(targetLoc, 0)
	caster = oldPawn
end

local function getPawnSaveData(pawnId)
	local region = GetCurrentRegion()
	local pawn_data
	local pawn_index = 1
	
	if region and region.player and region.player.map_data then
		
		repeat
			pawn_data = region.player.map_data["pawn".. pawn_index]
			pawn_index = pawn_index + 1
			
			if pawn_data and pawn_data.id == pawnId then
				break
			end
		until pawn_data == nil
	end
	
	return pawn_data
end

testsuite.test_SetFrozen_noAnimation_ShouldFreezePawn = buildPawnTest({
	-- Using SetFrozen with the `no_animation` flag set to true should still freeze the pawn.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
	end,
	execute = function()
		pawn:SetFrozen(true, true)
	end,
	check = function()
		assertEquals(true, pawn:IsFrozen(), "Pawn was not frozen.")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetShield_noAnimation_ShouldShieldPawn = buildPawnTest({
	-- Using SetShield with the `no_animation` flag set to true should still shield the pawn.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
	end,
	execute = function()
		pawn:SetShield(true, true)
	end,
	check = function()
		assertEquals(true, pawn:IsShield(), "Pawn was not shielded.")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetAcid_noAnimation_ShouldAffectPawnWithAcid = buildPawnTest({
	-- Using SetAcid with the `no_animation` flag set to true should still affect the pawn with acid.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
	end,
	execute = function()
		pawn:SetAcid(true, true)
	end,
	check = function()
		assertEquals(true, pawn:IsAcid(), "Pawn was not affected with acid.")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_AddWeapon_ShouldAllowAttackingWithNewWeapon = buildPawnTest({
	-- The pawn should be able to attack with newly added weapon.
	-- using Prime_ShieldBash for its property of not pushing or affecting tiles outside of its target.
	prepare = function()
		oldSkillList = PunchMech.SkillList
		PunchMech.SkillList = {}
		
		mechPawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		
		targetLoc = getRandomTarget(Prime_ShieldBash, mechPawn)
		targetTerrain = Board:GetTerrain(targetLoc)
		
		Board:SetTerrainVanilla(targetLoc, TERRAIN_ROAD)
		
		expectedInitialHealth = vekPawn:GetHealth()
		expectedAlteredHealth = expectedInitialHealth - Prime_ShieldBash.Damage
		
		vekPawn:SetSpace(targetLoc)
	end,
	execute = function()
		mechPawn:AddWeapon("Prime_ShieldBash")
		mechPawn:FireWeapon(targetLoc, 1)
	end,
	check = function()
		assertNotEquals(expectedInitialHealth, vekPawn:GetHealth(), "Vekpawn's initial health was unchanged.")
		assertEquals(expectedAlteredHealth, vekPawn:GetHealth(), "Vekpawn's altered health was incorrect.")
	end,
	cleanup = function()
		PunchMech.SkillList = oldSkillList
		Board:RemovePawn(mechPawn)
		Board:RemovePawn(vekPawn)
		Board:SetTerrainVanilla(targetLoc, targetTerrain)
	end
})

testsuite.test_RemoveWeapon_ShouldPreventPawnFromAttacking = buildPawnTest({
	-- The pawn should be unable to attack after having its weapon removed.
	-- Using Aegis Mech for Prime_ShieldBash's property of not pushing or affecting tiles outside of its target.
	prepare = function()
		mechPawn = Board:GetPawn(Board:AddPawn("GuardMech"))
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		
		targetLoc = getRandomTarget(Prime_ShieldBash, mechPawn)
		targetTerrain = Board:GetTerrain(targetLoc)
		
		Board:SetTerrainVanilla(targetLoc, TERRAIN_ROAD)
		
		expectedHealth = vekPawn:GetHealth()
		
		vekPawn:SetSpace(targetLoc)
	end,
	execute = function()
		mechPawn:RemoveWeapon(1)
		mechPawn:FireWeapon(targetLoc, 1)
	end,
	check = function()
		assertEquals(expectedHealth, vekPawn:GetHealth(), "Vekpawn's health was changed.")
	end,
	cleanup = function()
		Board:RemovePawn(mechPawn)
		Board:RemovePawn(vekPawn)
		Board:SetTerrainVanilla(targetLoc, targetTerrain)
	end
})

testsuite.test_SetMoveSkill_ShouldBeAbleToAttackWithMoveSkill = buildPawnTest({
	-- Should be able to punch adjacent tiles if move skill is swapped out.
	-- using Prime_ShieldBash for its property of not pushing or affecting tiles outside of its target.
	prepare = function()
		mechPawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		
		targetLoc = getRandomTarget(Prime_ShieldBash, mechPawn)
		targetTerrain = Board:GetTerrain(targetLoc)
		
		Board:SetTerrainVanilla(targetLoc, TERRAIN_ROAD)
		
		expectedInitialHealth = vekPawn:GetHealth()
		expectedAlteredHealth = expectedInitialHealth - Prime_ShieldBash.Damage
		
		vekPawn:SetSpace(targetLoc)
	end,
	execute = function()
		mechPawn:SetMoveSkill("Prime_ShieldBash")
		mechPawn:FireWeapon(targetLoc, 0)
	end,
	check = function()
		assertNotEquals(expectedInitialHealth, vekPawn:GetHealth(), "Vekpawn's initial health was unchanged.")
		assertEquals(expectedAlteredHealth, vekPawn:GetHealth(), "Vekpawn's altered health was incorrect.")
	end,
	cleanup = function()
		Board:RemovePawn(mechPawn)
		Board:RemovePawn(vekPawn)
		Board:SetTerrainVanilla(targetLoc, targetTerrain)
	end
})

testsuite.test_SetUndoLoc_SaveGameShouldReflectChange = buildPawnTest({
	-- The pawn's undo location in the save game should change after setting it.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		pawnId = pawn:GetId()
		
		expectedUndoLoc = getRandomTarget(Move, pawn)
		
		msTimeout = MS_WAIT_TIMEOUT
		endTime = modApi:elapsedTime() + msTimeout
	end,
	execute = function()
		pawn:SetUndoLoc(expectedUndoLoc)
		
		-- wait one frame before saving.
		modApi:runLater(function()
			DoSaveGame()
		end)
	end,
	checkAwait = function()
		-- wait until we can find the pawn in the save data.
		return getPawnSaveData(pawnId) ~= nil or modApi:elapsedTime() > endTime
    end,
	check = function()
		assertEquals(expectedUndoLoc, (getPawnSaveData(pawnId) or {}).undo_point, "Pawn's undo location was incorrect")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

testsuite.test_GetUndoLoc_ShouldUpdateAfterSettingUndoLoc = buildPawnTest({
	-- The pawn's undo location should change after setting it.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		
		expectedInitialUndoLoc = Point(-1,-1)
		expectedAlteredUndoLoc = getRandomTarget(Move, pawn)
	end,
	execute = function()
		actualInitialUndoLoc = pawn:GetUndoLoc()
		
		pawn:SetUndoLoc(expectedAlteredUndoLoc)
		actualAlteredUndoLoc = pawn:GetUndoLoc()
	end,
	check = function()
		assertEquals(expectedInitialUndoLoc, actualInitialUndoLoc, "Pawn's initial undo location was incorrect")
		assertEquals(expectedAlteredUndoLoc, actualAlteredUndoLoc, "Pawn's altered undo location was incorrect")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
	end
})

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
		targetTerrain = Board:GetTerrain(targetLoc)
		Board:SetTerrainVanilla(targetLoc, TERRAIN_ROAD)
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
		
		Board:SetTerrainVanilla(targetLoc, targetTerrain)
	end
})

testsuite.test_SetHealth_ShouldUpdatePawnHealth = buildPawnTest({
	prepare = function()
		pawn = PAWN_FACTORY:CreatePawn("PunchMech")

		expectedPawnHealth = 1
	end,
	execute = function()
		pawn:SetHealth(expectedPawnHealth)
		actualPawnHealth = pawn:GetHealth()
	end,
	check = function()
		assertEquals(expectedPawnHealth, actualPawnHealth, "Pawn health was not updated")
	end
})

testsuite.test_GetBaseMaxHealth_ShouldNotIncreaseWithSoldierPsionOnBoard = buildPawnTest({
	prepare = function()
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		expectedBaseMaxHealth = vekPawn:GetHealth()
	end,
	execute = function()
		actualBaseMaxHealth = vekPawn:GetBaseMaxHealth()
		
		-- Create a soldier psion to increase health and max health by 1.
		psionPawn = Board:GetPawn(Board:AddPawn("Jelly_Health1"))
	end,
	check = function()
		assertEquals(expectedBaseMaxHealth, actualBaseMaxHealth, "Vek pawn's old max health was incorrectly different from base max health")
		assertNotEquals(vekPawn:GetHealth(), actualBaseMaxHealth, "Vek pawn's new max health was incorrectly not different from base max health")
	end,
	cleanup = function()
		Board:RemovePawn(vekPawn)
		Board:RemovePawn(psionPawn)
	end
})

testsuite.test_SetBaseMaxHealth_ShouldNotUpdateHealthUnlessBonusIsApplied = buildPawnTest({
	prepare = function()
		vekPawn = Board:GetPawn(Board:AddPawn("Scorpion1"))
		expectedInitialHealth = vekPawn:GetHealth()
		expectedAlteredHealth = 2
	end,
	execute = function()
		vekPawn:SetBaseMaxHealth(1)
		actualInitialHealth = vekPawn:GetHealth()
		
		-- Create a soldier psion to update health based on pawn's base max health.
		psionPawn = Board:GetPawn(Board:AddPawn("Jelly_Health1"))
	end,
	check = function()
		assertEquals(expectedInitialHealth, actualInitialHealth, "Vek pawn's health incorrectly was updated")
		assertEquals(expectedAlteredHealth, vekPawn:GetHealth(), "Vek pawn's was incorrect after creating Soldier Psion")
	end,
	cleanup = function()
		Board:RemovePawn(vekPawn)
		Board:RemovePawn(psionPawn)
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
		Board:SetTerrainVanilla(casterLoc, TERRAIN_ROAD)
		Board:SetTerrainVanilla(targetLoc, TERRAIN_ROAD)
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
		Board:SetTerrainVanilla(casterLoc, casterTerrain)
		if target then
			Board:RemovePawn(target)
		end
		Board:SetTerrainVanilla(targetLoc, targetTerrain)
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

		Board:SetTerrainVanilla(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(true, pawn:IsMassive(), "SetMassive() did not change pawn Massive status")
		assertEquals(false, pawn:IsDead(), "Pawn changed into Massive using SetMassive() died in water")
	end,
	cleanup = function()
		Board:SetTerrainVanilla(loc, terrain)
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

		Board:SetTerrainVanilla(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(false, pawn:IsMassive(), "SetMassive() did not change pawn Massive status")
		assertEquals(true, pawn:IsDead(), "Pawn changed into non-Massive using SetMassive() did not die in water")
	end,
	cleanup = function()
		Board:SetTerrainVanilla(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

testsuite.test_SetMech_ShouldDisableCurrentMechsAndEnableNewMech = buildPawnTest({
	-- In order to test this function, we must use it both in preparation as well as cleanup.
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("PunchMech"))
		
		-- Only 3 mechs are allowed at the same time, so we must strip old mechs of their status.
		mechs = {}
		for _, pawnId in ipairs(extract_table(Board:GetPawns(TEAM_ANY))) do
			local mech = Board:GetPawn(pawnId)
			if mech:IsMech() then
				mechs[#mechs+1] = mech
			end
			mech:SetMech(false)
		end
		
		expectedIsMech = true
	end,
	execute = function()
		pawn:SetMech(true)
		
		actualIsMech = pawn:IsMech()
	end,
	check = function()
		assertEquals(expectedIsMech, actualIsMech, "Pawn incorrectly did not become a mech")
	end,
	cleanup = function()
		Board:RemovePawn(pawn)
		
		for _, mech in ipairs(mechs) do
			mech:SetMech(true)
		end
	end
})

testsuite.test_IsMovementAvailable_ShouldReturnFalse_AfterMoving = buildPawnTest({
	prepare = function()
		pawn = Board:GetPawn(Board:AddPawn("Scorpion1"))

		expectedLoc = getRandomTarget(Move, pawn)

		assertEquals(true, pawn:IsMovementAvailable(), "Assumed pawn would be able to move after creation")
	end,
	execute = function()
		orderPawnToMoveTo(pawn, expectedLoc)
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
		orderPawnToMoveTo(pawn, expectedLoc)

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

		Board:SetTerrainVanilla(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(true, pawn:IsFlying(), "SetFlying() did not change pawn Flying status")
		assertEquals(false, pawn:IsDead(), "Pawn changed into Flying using SetFlying() died in water")
	end,
	cleanup = function()
		Board:SetTerrainVanilla(loc, terrain)
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

		Board:SetTerrainVanilla(loc, TERRAIN_WATER)
	end,
	check = function()
		assertEquals(false, pawn:IsFlying(), "SetFlying() did not change pawn Flying status")
		assertEquals(true, pawn:IsDead(), "Pawn changed into non-Flying using SetFlying() did not die in water")
	end,
	cleanup = function()
		Board:SetTerrainVanilla(loc, terrain)
		Board:RemovePawn(pawn)
	end
})

return testsuite
