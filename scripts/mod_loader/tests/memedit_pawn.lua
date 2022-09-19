local testsuite = Tests.Testsuite()
testsuite.name = "Memedit-generated-pawn-functions tests"


testsuite.test_pawn_acid = function()
	Tests.RequireMemedit()
	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")

	pawn:SetAcid(true)
	Assert.Equals(true, modApi.memedit.dll.pawn.isAcid(pawn))

	return true
end

testsuite.test_pawn_active = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetActive(false)
	Assert.Equals(false, modApi.memedit.dll.pawn.isActive(pawn))

	return true
end

testsuite.test_pawn_baseMaxHealth = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Health, modApi.memedit.dll.pawn.getBaseMaxHealth(pawn))

	return true
end

testsuite.test_pawn_boosted = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(false, modApi.memedit.dll.pawn.isBoosted(pawn))

	return true
end

testsuite.test_pawn_class = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Class, modApi.memedit.dll.pawn.getClass(pawn))

	return true
end

testsuite.test_pawn_corpse = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Corpse, modApi.memedit.dll.pawn.isCorpse(pawn))

	return true
end

testsuite.test_pawn_customAnim = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetCustomAnim("testAnim")
	Assert.Equals("testAnim", modApi.memedit.dll.pawn.getCustomAnim(pawn))

	return true
end

testsuite.test_pawn_defaultFaction = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("Snowtank1")
	Assert.Equals(Snowtank1.DefaultFaction, modApi.memedit.dll.pawn.getDefaultFaction(pawn))

	return true
end

testsuite.test_pawn_fire = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(false, modApi.memedit.dll.pawn.isFire(pawn))

	return true
end

testsuite.test_pawn_flying = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Flying, modApi.memedit.dll.pawn.isFlying(pawn))

	return true
end

testsuite.test_pawn_frozen = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetFrozen(true)
	Assert.Equals(true, modApi.memedit.dll.pawn.isFrozen(pawn))

	return true
end

testsuite.test_pawn_imageOffset = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("JudoMech")
	Assert.Equals(JudoMech.ImageOffset, modApi.memedit.dll.pawn.getImageOffset(pawn))

	return true
end

testsuite.test_pawn_impactMaterial = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("Firefly1")
	Assert.Equals(Firefly1.ImpactMaterial, modApi.memedit.dll.pawn.getImpactMaterial(pawn))

	return true
end

testsuite.test_pawn_invisible = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetInvisible(true)
	Assert.Equals(true, modApi.memedit.dll.pawn.isInvisible(pawn))

	return true
end

testsuite.test_pawn_jumper = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Jumper, modApi.memedit.dll.pawn.isJumper(pawn))

	return true
end

testsuite.test_pawn_leader = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("Jelly_Health1")
	Assert.Equals(Jelly_Health1.Leader, modApi.memedit.dll.pawn.getLeader(pawn))

	return true
end

testsuite.test_pawn_neutral = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("RockThrown")
	Assert.Equals(RockThrown.Neutral, modApi.memedit.dll.pawn.isNeutral(pawn))

	return true
end

testsuite.test_pawn_massive = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Massive, modApi.memedit.dll.pawn.isMassive(pawn))

	return true
end

testsuite.test_pawn_maxhealth = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Health, modApi.memedit.dll.pawn.getMaxHealth(pawn))

	return true
end

testsuite.test_pawn_mech = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("Firefly1")
	Assert.Equals(false, modApi.memedit.dll.pawn.isMech(pawn))

	return true
end

testsuite.test_pawn_minor = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("Spiderling1")
	Assert.Equals(Spiderling1.Minor, modApi.memedit.dll.pawn.isMinor(pawn))

	return true
end

testsuite.test_pawn_missionCritical = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(false, modApi.memedit.dll.pawn.isMissionCritical(pawn))

	return true
end

testsuite.test_pawn_moveSpeed = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.MoveSpeed, modApi.memedit.dll.pawn.getMoveSpeed(pawn))

	return true
end

testsuite.test_pawn_mutation = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(LEADER_NONE, modApi.memedit.dll.pawn.getMutation(pawn))

	return true
end

testsuite.test_pawn_owner = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(-1, modApi.memedit.dll.pawn.getOwner(pawn))

	return true
end

testsuite.test_pawn_powered = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(true, modApi.memedit.dll.pawn.isPowered(pawn))

	return true
end

testsuite.test_pawn_pushable = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Pushable, modApi.memedit.dll.pawn.isPushable(pawn))

	return true
end

testsuite.test_pawn_queuedTargetX = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(-1, modApi.memedit.dll.pawn.getQueuedTargetX(pawn))

	return true
end

testsuite.test_pawn_queuedTargetY = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(-1, modApi.memedit.dll.pawn.getQueuedTargetY(pawn))

	return true
end

testsuite.test_pawn_shield = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetShield(true)
	Assert.Equals(true, modApi.memedit.dll.pawn.isShield(pawn))

	return true
end

testsuite.test_pawn_spaceColor = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.SpaceColor, modApi.memedit.dll.pawn.isSpaceColor(pawn))

	return true
end

testsuite.test_pawn_team = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	pawn:SetTeam(TEAM_ENEMY)
	Assert.Equals(TEAM_ENEMY, modApi.memedit.dll.pawn.getTeam(pawn))

	return true
end

testsuite.test_pawn_teleporter = function()
	Tests.RequireMemedit()

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	Assert.Equals(PunchMech.Teleporter, modApi.memedit.dll.pawn.isTeleporter(pawn))

	return true
end

return testsuite
