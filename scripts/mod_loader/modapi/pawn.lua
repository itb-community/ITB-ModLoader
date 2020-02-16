
PawnTable = Pawn

local function setSavefileFieldsForPawn(pawn, keyValuesTable)
	UpdateSaveData(function(save)
		local region = GetCurrentRegion(save.RegionData)
		local ptable = GetPawnTable(pawn:GetId(), save.SquadData)
		if not ptable and region then
			ptable = GetPawnTable(pawn:GetId(), region.player.map_data)
		end

		if ptable then
			for k, v in pairs(keyValuesTable) do
				ptable[k] = v
			end
		end
	end)
end

BoardPawn.GetPawnTable = function(self)
	local region = GetCurrentRegion(RegionData)
	
	if region == nil then
		return {}
	end
	
	return GetPawnTable(self:GetId(), region.player.map_data) or {}
end

BoardPawn.ClearUndoMove = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	CUtils.PawnClearUndoMove(self)
end

BoardPawn.SetUndoLoc = function(self, loc)
	Tests.AssertSignature{
		ret = "void",
		func = "SetUndoLoc",
		params = { self, loc },
		{ "userdata|BoardPawn&", "userdata|Point" },
	}
	
	CUtils.SetPawnUndoLoc(self, loc)
end

BoardPawn.GetUndoLoc = function(self)
	Tests.AssertSignature{
		ret = "Point",
		func = "GetUndoLoc",
		params = { self },
		{ "userdata|BoardPawn&" },
	}
	
	return CUtils.GetPawnUndoLoc(self)
end

BoardPawn.IsNeutral = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local ptable = self:GetPawnTable()
	local neutral = ptable.bNeutral

	if neutral == nil then
		neutral = _G[self:GetType()]:GetNeutral()
	end
	if neutral == nil then
		neutral = false
	end

	return neutral
end

BoardPawn.IsPowered = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local ptable = self:GetPawnTable()
	local powered = ptable.bPowered

	if powered == nil then
		powered = true
	end

	return powered
end
	
BoardPawn.GetMutation = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local ptable = self:GetPawnTable()
	
	return ptable.iMutation
end

BoardPawn.IsMutation = function(self, mutation)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertEquals("number", type(mutation), "Argument #1")

	return self:GetMutation() == mutation
end

BoardPawn.IsArmor = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	local pilot = self:IsAbility("Armored")
	local mech = _G[self:GetType()]:GetArmor()
	local mutation = self:IsMutation(LEADER_ARMOR)
	-- TODO: Bug: killing an armor psion then respawning it via Board:AddPawn() causes this function to return false
	-- Need to update the savefile after a new pawn appears on the board
	
	return pilot or mech or mutation
end

BoardPawn.IsIgnoreWeb = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	return self:IsAbility("Disable_Immunity")
end

BoardPawn.IsIgnoreSmoke = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	local pilot = self:IsAbility("Disable_Immunity")
	local unit = _G[self:GetType()].IgnoreSmoke
	
	return pilot or unit
end

BoardPawn.IsIgnoreFire = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	
	local passive = self:IsMech() and IsPassiveSkill("Flame_Immune")
	local pilot = self:IsAbility("Rock_Skill")
	local unit = _G[self:GetType()].IgnoreFire
	
	return passive or pilot or unit
end

BoardPawn.GetQueued = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local ptable = self:GetPawnTable()
	
	if ptable.iQueuedSkill == -1 then
		return
	end
	
	return {
		piOrigin = ptable.piOrigin,
		piTarget = ptable.piTarget,
		piQueuedShot = ptable.piQueuedShot,
		iQueuedSkill = ptable.iQueuedSkill,
	}
end

BoardPawn.IsQueued = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")

	local queued = self:GetQueued()
	
	if queued == nil or queued.piQueuedShot == nil then
		return false
	end
	
	return Board:IsValid(queued.piQueuedShot)
end

BoardPawn.GetOwner = function(self)
	Tests.AssertSignature{
		ret = "int",
		func = "GetOwner",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.GetPawnOwner(self)
end

BoardPawn.SetOwner = function(self, iOwner)
	Tests.AssertSignature{
		ret = "void",
		func = "SetOwner",
		params = { self, iOwner },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	if self:IsMech() or self:GetId() == iOwner then
		return
	end
	
	local pawn = Board:GetPawn(iOwner)
	
	if not pawn then
		return
	end
	
	-- TODO: find out how this interacts with enemy pawns, etc.
	
	return CUtils.SetPawnOwner(self, iOwner)
end

BoardPawn.ApplyDamage = function(self, spaceDamage)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertEquals("userdata", type(spaceDamage), "Argument #1")
	
	if not Board or GetCurrentMission() == nil then
		return
	end

	local loc = spaceDamage.loc
	spaceDamage.loc = self:GetSpace()

	local fx = SkillEffect()
	fx:AddSafeDamage(spaceDamage)
	Board:AddEffect(fx)

	spaceDamage.loc = loc
end

BoardPawn.SetFire = function(self, fire)
	Tests.AssertSignature{
		ret = "void",
		func = "SetFire",
		params = { self, fire },
		{ "userdata|BoardPawn&", "boolean|bool" }
	}
	
	if fire == nil then
		fire = true
	end
	
	CUtils.SetPawnFire(self, fire)
end

BoardPawn.IsHighlighted = function(self)
	Tests.AssertSignature{
		ret = "Point",
		func = "IsHighlighted",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return Board:IsHighlighted(self:GetSpace())
end

BoardPawn.GetImpactMaterial = function(self)
	Tests.AssertSignature{
		ret = "int",
		func = "GetImpactMaterial",
		params = { self, impactMaterial },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.GetPawnImpactMaterial(self)
end

BoardPawn.SetImpactMaterial = function(self, impactMaterial)
	Tests.AssertSignature{
		ret = "void",
		func = "SetImpactMaterial",
		params = { self, impactMaterial },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	CUtils.SetPawnImpactMaterial(self, impactMaterial)
end

BoardPawn.GetColor = function(self)
	Tests.AssertSignature{
		ret = "int",
		func = "GetColor",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.GetPawnColor(self)
end

BoardPawn.SetColor = function(self, iColor)
	Tests.AssertSignature{
		ret = "void",
		func = "SetColor",
		params = { self, iColor },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	iColor = math.max(0, math.min(iColor, GetColorCount() - 1))
	
	CUtils.SetPawnColor(self, iColor)
end

BoardPawn.IsPlayerControlled = function(self)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsPlayerControlled",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.IsPawnPlayerControlled(self)
end

BoardPawn.IsMassive = function(self)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsMassive",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.IsPawnMassive(self)
end

BoardPawn.SetMassive = function(self, massive)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMassive",
		params = { self, massive },
		{ "userdata|BoardPawn&", "boolean|bool" },
		{ "userdata|BoardPawn&" }
	}
	
	if massive == nil then
		massive = true
	end
	
	CUtils.SetPawnMassive(self, massive)
end

BoardPawn.IsMovementAvailable = function(self)
	Tests.AssertSignature{
		ret = "bool",
		func = "IsMovementAvailable",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return not CUtils.SetPawnMovementSpent(self)
end

BoardPawn.SetMovementAvailable = function(self, movementAvailable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMovementAvailable",
		params = { self, movementAvailable },
		{ "userdata|BoardPawn&", "boolean|bool" },
		{ "userdata|BoardPawn&" }
	}
	
	if movementAvailable == nil then
		movementAvailable = true
	end
	
	CUtils.SetPawnMovementSpent(self, not movementAvailable)
end

BoardPawn.SetFlying = function(self, flying)
	Tests.AssertSignature{
		ret = "void",
		func = "SetFlying",
		params = { self, flying },
		{ "userdata|BoardPawn&", "boolean|bool" },
		{ "userdata|BoardPawn&" }
	}
	
	if flag == nil then
		flag = true
	end
	
	CUtils.SetPawnFlying(self, flying)
end

BoardPawn.SetTeleporter = function(self, teleporter)
	Tests.AssertSignature{
		ret = "void",
		func = "SetTeleporter",
		params = { self, teleporter },
		{ "userdata|BoardPawn&", "boolean|bool" },
		{ "userdata|BoardPawn&" }
	}
	
	if teleporter == nil then
		teleporter = true
	end
	
	CUtils.SetPawnTeleporter(self, teleporter)
end

BoardPawn.SetJumper = function(self, jumper)
	Tests.AssertSignature{
		ret = "void",
		func = "SetJumper",
		params = { self, jumper },
		{ "userdata|BoardPawn&", "boolean|bool" },
		{ "userdata|BoardPawn&" }
	}
	
	if jumper == nil then
		jumper = true
	end
	
	CUtils.SetPawnJumper(self, jumper)
end

BoardPawn.GetMaxHealth = function(self)
	Tests.AssertSignature{
		ret = "int",
		func = "GetMaxHealth",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.GetPawnMaxHealth(self)
end

BoardPawn.GetBaseMaxHealth = function(self)
	Tests.AssertSignature{
		ret = "int",
		func = "GetBaseMaxHealth",
		params = { self },
		{ "userdata|BoardPawn&" }
	}
	
	return CUtils.GetPawnBaseMaxHealth(self)
end

BoardPawn.SetHealth = function(self, hp)
	Tests.AssertSignature{
		ret = "void",
		func = "SetHealth",
		params = { self, hp },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	local hp_max = self:GetMaxHealth()
	hp = math.max(0, math.min(hp, hp_max))
	
	CUtils.SetPawnHealth(self, hp)
end

BoardPawn.SetMaxHealth = function(self, hp_max)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMaxHealth",
		params = { self, hp_max },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	CUtils.SetPawnMaxHealth(self, hp_max)
end

BoardPawn.SetBaseMaxHealth = function(self, hp_max_base)
	Tests.AssertSignature{
		ret = "void",
		func = "SetBaseMaxHealth",
		params = { self, hp_max_base },
		{ "userdata|BoardPawn&", "number|int" }
	}
	
	CUtils.SetPawnBaseMaxHealth(self, hp_max_base)
end


BoardPawn.MarkHpLoss = function(self, hp_loss)
	CUtils.PawnMarkHpLoss(self, hp_loss)
end


BoardPawn.GetWeaponCount = function(self)
	return CUtils.PawnGetWeaponCount(self)
end

BoardPawn.GetWeaponName = function(self, index)
	return CUtils.PawnGetWeaponName(self, index)
end

BoardPawn.GetWeaponType = function(self, index)
	return CUtils.PawnGetWeaponType(self, index)
end

BoardPawn.GetWeaponClass = function(self, index)
	return CUtils.PawnGetWeaponClass(self, index)
end

BoardPawn.GetMoveSkill = function(self)
	return CUtils.PawnGetMoveSkill(self)
end

--[[BoardPawn.GetRepairSkill = function(self)
	return CUtils.PawnGetRepairSkill(self)
end]]


BoardPawn.RemoveWeapon = function(self, index)
	return CUtils.PawnRemoveWeapon(self, index)
end

BoardPawn.SetMoveSkill = function(self, skill)
	CUtils.PawnSetMoveSkill(self, skill)
end

BoardPawn.SetRepairSkill = function(self, skill)
	CUtils.PawnSetRepairSkill(self, skill)
end


BoardPawn.GetPilotId = function(self)
	return CUtils.GetPilotId(self)
end

BoardPawn.GetAbility = function(self)
	return CUtils.GetPilotAbility(self)
end

BoardPawn.GetVoice = function(self)
	return CUtils.GetPilotVoice(self)
end

-- TODO: Add guards for all Pilot functions to avoid crashing when there are no pilot table.

BoardPawn.SetPilotId = function(self, id)
	-- TODO: check if pilot id exists?
	return CUtils.SetPilotId(self, id)
end

BoardPawn.SetPilotName = function(self, name)
	return CUtils.SetPilotName(self, name)
end

BoardPawn.SetPersonality = function(self, personality)
	-- TODO: check if personality exists?
	return CUtils.SetPilotPersonality(self, personality)
end

BoardPawn.SetAbility = function(self, ability)
	return CUtils.SetPilotAbility(self, ability)
end

BoardPawn.SetVoice = function(self, voice)
	return CUtils.SetPilotVoice(self, voice)
end


BoardPawn.GetLevel = function(self)
	return CUtils.GetPilotLevel(self)
end

BoardPawn.GetXp = function(self)
	return CUtils.GetPilotXp(self)
end

BoardPawn.GetLevelupXp = function(self)
	return CUtils.GetPilotLevelupXp(self)
end


BoardPawn.SetLevel = function(self, level)
	return CUtils.SetPilotLevel(self, level)
end

BoardPawn.SetXp = function(self, xp)
	return CUtils.SetPilotXp(self, xp)
end

BoardPawn.SetLevelupXp = function(self, xp)
	return CUtils.SetPilotLevelupXp(self, xp)
end


BoardPawn.GetPilotAbilityCost = function(self)
	return CUtils.GetPilotAbilityCost(self)
end

BoardPawn.GetPilotDamagedState = function(self)
	return CUtils.GetPilotDamagedState(self)
end

BoardPawn.GetPilotPreviousTimelines = function(self)
	return CUtils.GetPilotPreviousTimelines(self)
end

BoardPawn.GetPilotFinalBattles = function(self)
	return CUtils.GetPilotFinalBattles(self)
end

BoardPawn.IsPilotAIUnit = function(self)
	return CUtils.IsPilotAIUnit(self)
end


BoardPawn.SetPilotAbilityCost = function(self, cost)
	CUtils.SetPilotAbilityCost(self, cost)
end

-- this worked in testing, but there must be more to it, because the change does not stick.
--[[BoardPawn.SetPilotDamagedState = function(self, damaged)
	CUtils.SetPilotDamagedState(self, damaged)
end]]

BoardPawn.SetPilotPreviousTimelines = function(self, timelines)
	CUtils.SetPilotPreviousTimelines(self, timelines)
end

BoardPawn.SetPilotFinalBattles = function(self, battles)
	CUtils.SetPilotFinalBattles(self, battles)
end

BoardPawn.SetPilotAIUnit = function(self, ai)
	CUtils.SetPilotAIUnit(self, ai)
end


BoardPawn.GetLuaString = function(self)
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	return string.format("BoardPawn [id = %s, space = %s, name = %s]", self:GetId(), self:GetSpace():GetLuaString(), self:GetMechName())
end
BoardPawn.GetString = BoardPawn.GetLuaString


local function initializeBoardPawn()
	-- Overrides of existing functions need to be added at later time, since in
	-- order to grab a reference to original functions, we require a pawn instance.

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	
	local oldSetNeutral = pawn.SetNeutral
	BoardPawn.SetNeutral = function(self, neutral)
		Tests.AssertEquals("userdata", type(self), "Argument #0")
		Tests.AssertEquals("boolean", type(neutral), "Argument #1")

		oldSetNeutral(self, neutral)

		if not Board or GetCurrentMission() == nil then
			return
		end

		setSavefileFieldsForPawn(self, { bNeutral = neutral })
	end

	local oldSetPowered = pawn.SetPowered
	BoardPawn.SetPowered = function(self, powered)
		Tests.AssertEquals("userdata", type(self), "Argument #0")
		Tests.AssertEquals("boolean", type(powered), "Argument #1")

		oldSetPowered(self, powered)

		if not Board or GetCurrentMission() == nil then
			return
		end

		setSavefileFieldsForPawn(self, { bPowered = powered })
	end
	
	local function getMechCount()
		if not Board then
			-- TODO: return mechs in 'Game' object?
			return 0
		end
		
		local pawns = Board:GetPawns(TEAM_ANY)
		local count = 0
		
		for i = 1, pawns:size() do
			if Board:GetPawn(pawns:index(i)):IsMech() then
				count = count + 1
			end
		end
		
		return count
	end
	
	-- this is a very dangerous function to work with.
	-- loading a game with less than 3 mechs will crash the game.
	-- having more than 3 mechs at any point will crash the game.
	-- not sure if it is possible to use this in any safe way,
	-- but leaving it here because the ability to swap out mechs
	-- could potentially lead to some very cool mods.
	local oldSetMech = pawn.SetMech
	BoardPawn.SetMech = function(self, isMech)
		Tests.AssertSignature{
			ret = "void",
			func = "SetMech",
			params = { self, isMech },
			{ "userdata|BoardPawn&", "boolean|bool" },
			{ "userdata|BoardPawn&" }
		}
		
		if isMech == false then
			CUtils.SetPawnMech(self, isMech)
		elseif getMechCount() < 3 then
			oldSetMech(self)
		end
	end
	
	-- vanilla function only looks in pawn type table.
	BoardPawn.IsTeleporter = function(self)
		Tests.AssertSignature{
			ret = "bool",
			func = "IsTeleporter",
			params = { self },
			{ "userdata|BoardPawn&" }
		}
		
		return CUtils.IsPawnTeleporter(self)
	end
	
	-- vanilla function only looks in pawn type table.
	BoardPawn.IsJumper = function(self)
		Tests.AssertSignature{
			ret = "bool",
			func = "IsJumper",
			params = { self },
			{ "userdata|BoardPawn&" }
		}
		
		return CUtils.IsPawnJumper(self)
	end
	
	-- extend vanilla function to apply status without animation
	local oldSetFrozen = pawn.SetFrozen
	BoardPawn.SetFrozen = function(self, frozen, no_animation)
		if no_animation then
			return CUtils.SetPawnFrozen(self, frozen)
		end
		
		return oldSetFrozen(self, frozen)
	end
	
	-- extend vanilla function to apply status without animation
	local oldSetShield = pawn.SetShield
	BoardPawn.SetShield = function(self, shield, no_animation)
		if no_animation then
			return CUtils.SetPawnShield(self, shield)
		end
		
		return oldSetShield(self, shield)
	end
	
	-- extend vanilla function to apply status without animation
	local oldSetAcid = pawn.SetAcid
	BoardPawn.SetAcid = function(self, acid, no_animation)
		if no_animation then
			return CUtils.SetPawnAcid(self, acid)
		end
		
		return oldSetAcid(self, acid)
	end
	
	-- vanilla AddWeapon was lacking. call improved version
	BoardPawn.AddWeaponOriginal = pawn.AddWeapon
	BoardPawn.AddWeapon = function(self, weapon)
		CUtils.PawnAddWeapon(self, weapon)
	end
	
	pawn = nil
	InitializeBoardPawn = nil
end

InitializeBoardPawn = initializeBoardPawn
