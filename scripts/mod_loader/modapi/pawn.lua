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
	if region then
		return GetPawnTable(self:GetId(), region.player.map_data) or {}
	end

	-- the base logic for GetPawnTable will fallback to the region data if the squad data is missing
  -- but we prioritize region data here instead, we don't need the fallback as we already checked
	-- hence why we specifically pass and check SquadData
	if SquadData then
		return GetPawnTable(self:GetId(), SquadData) or {}
	end

	-- neither region nor squad data? got nothing then
	return {}
end

BoardPawn.ClearUndoMove = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end

	if self:IsNeutral() or self:GetTeam() ~= TEAM_PLAYER then
		return
	end

	-- Defer until after the pawn and Board are not busy anymore,
	-- since otherwise it doesn't always work
	modApi:conditionalHook(
		function()
			return self and not self:IsBusy() and not Board:IsBusy()
		end,
		function()
			self:SetNeutral(true)
			
			-- Pawn needs to stay neutral for two game update steps, apparently
			modApi:runLater(function()
				modApi:runLater(function()
					self:SetNeutral(false)
					setSavefileFieldsForPawn(self, {
						undo_ready = false,
						undoReady = false
					})
				end)
			end)
		end
	)
end

BoardPawn.IsNeutral = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals(true, mod_loader:hasExtension("memedit"), "memedit not available")

	local result = false

	try(function()
		result = modApi.memedit.dll.pawn.isNeutral(self)
	end)
	:catch(function(err)
		error(string.format(
				"memedit.dll: %s",
				tostring(err)
		))
	end)

	return result
end

-- checks if the pawn receives psion effects
BoardPawn.CanMutate = function(self, targetPlayer)
	Assert.Equals("userdata", type(self), "Argument #0")
	if targetPlayer == nil then
		targetPlayer = false
	end
	Assert.Equals("boolean", type(targetPlayer), "Argument #1")

	if self:IsEnemy()  then
		-- final island psion has inverted targeting
		if targetPlayer and not IsPassiveSkill("Psion_Leech") then
			return false
		end

		-- enemies support mutations if not minor, bots, or leaders
  	local pawnType = _G[self:GetType()]
		return not pawnType:GetMinor() and pawnType:GetLeader() == LEADER_NONE and pawnType:GetDefaultFaction() ~= FACTION_BOTS
	end

		-- mechs support mutations if the passive is active or the final island psion
	if self:IsPlayer() then
		return targetPlayer or (self:IsMech() and IsPassiveSkill("Psion_Leech"))
	end

	return false
end

BoardPawn.GetMutation = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	if Board then
		local mutation = Board:GetMutation()
		if self:CanMutate(mutation == LEADER_TENTACLE) then
			return mutation
		end
	end
	return nil
end

BoardPawn.IsMutation = function(self, predicate)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("number", type(predicate), "Argument #1")

	if Board then
		-- need to invert mutation if its LEADER_TENTACLE
		-- if LEADER_BOSS, accept a predicate of any of the three that BOSS is made of
		local mutation = Board:GetMutation()
		return self:CanMutate(mutation == LEADER_TENTACLE)
		  and (mutation == predicate or (mutation == LEADER_BOSS and (predicate == LEADER_HEALTH or predicate == LEADER_REGEN or predicate == LEADER_EXPLODE)))
	end
	return false
end

BoardPawn.IsArmor = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local pawnType = _G[self:GetType()]
	return self:IsAbility("Armored")            -- pilot ability
			or pawnType:GetArmor()                  -- pawn ability
			-- psion ability, but not on the psion itself
			or (pawnType:GetLeader() == LEADER_NONE and self:IsMutation(LEADER_ARMOR))
end

BoardPawn.IsIgnoreWeb = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	return self:IsAbility("Disable_Immunity")
end

BoardPawn.IsIgnoreSmoke = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local pilot = self:IsAbility("Disable_Immunity")
	local unit = _G[self:GetType()].IgnoreSmoke
	
	return pilot or unit
end

BoardPawn.IsIgnoreFire = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	
	local passive = self:IsMech() and IsPassiveSkill("Flame_Immune")
	local pilot = self:IsAbility("Rock_Skill")
	local unit = _G[self:GetType()].IgnoreFire
	
	return passive or pilot or unit
end

BoardPawn.GetQueued = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

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
	Assert.Equals("userdata", type(self), "Argument #0")

	local queued = self:GetQueued()
	
	if queued == nil or queued.piQueuedShot == nil then
		return false
	end
	
	return Board:IsValid(queued.piQueuedShot)
end

BoardPawn.ApplyDamage = function(self, spaceDamage)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("userdata", type(spaceDamage), "Argument #1")
	
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
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("boolean", type(fire), "Argument #1")

	if not Board or GetCurrentMission() == nil then
		return
	end

	local d = SpaceDamage()
	if fire then
		d.iFire = EFFECT_CREATE
	else
		d.iFire = EFFECT_REMOVE
	end

	self:ApplyDamage(d)
end

BoardPawn.IsHighlighted = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	if not Board or GetCurrentMission() == nil then
		return
	end

	local loc = mouseTile()
	local p = loc and Board:GetPawn(loc)
	if p then
		return p:GetId() == self:GetId()
	end

	return false
end

BoardPawn.GetAbility = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()

	if ptable.pilot == nil then
		return ""
	end

	local pilot = _G[ptable.pilot.id]
	return pilot.Skill
end


local function isPowered(powerTable)
	if powerTable == nil then
		return false
	end

	return powerTable[1] ~= 0
end

local function getPoweredWeapon(ptable, weapon)
	if not isPowered(ptable[weapon.."_power"] or {1}) then
		return nil
	end

	local result = ptable[weapon]

	if result == nil then
		return nil
	end

	local upgrade = ""
	if isPowered(ptable[weapon.."_mod1"]) then
		upgrade = upgrade.."A"
	end
	if isPowered(ptable[weapon.."_mod2"]) then
		upgrade = upgrade.."B"
	end
	if upgrade:len() > 0 then
		result = result.."_"..upgrade
	end

	return result
end

local function weaponBase(weapon)
	return weapon:match("^(.-)_?A?B?$")
end

local function weaponSuffix(weapon)
	return weapon:match("_(A?B?)$")
end

-- returns true if `weapon` is the same
-- or a lower version of `compareWeapon`
local function isDescendantOfWeapon(weapon, compareWeapon)
	if compareWeapon == nil then
		return false
	end

	local baseWeapon = weaponBase(weapon)
	local baseCompare = weaponBase(compareWeapon)

	if baseWeapon ~= baseCompare then
		return false
	end

	local suffixWeapon = weaponSuffix(weapon)
	local suffixCompare = weaponSuffix(compareWeapon)

	if suffixWeapon == nil then
		return true
	elseif suffixCompare == nil then
		return false
	end

	return suffixCompare:find(suffixWeapon) and true or false
end

BoardPawn.GetEquippedWeapons = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()

	return {
		ptable.primary,
		ptable.secondary
	}
end

BoardPawn.GetPoweredWeapons = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()

	return {
		getPoweredWeapon(ptable, "primary"),
		getPoweredWeapon(ptable, "secondary")
	}
end

BoardPawn.IsWeaponEquipped = function(self, baseWeapon)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("string", type(baseWeapon), "Argument #1")

	local ptable = self:GetPawnTable()

	return
		baseWeapon == ptable.primary or
		baseWeapon == ptable.secondary
end

BoardPawn.IsWeaponPowered = function(self, weapon)
	Assert.Equals("userdata", type(self), "Argument #0")
	Assert.Equals("string", type(weapon), "Argument #1")

	local ptable = self:GetPawnTable()
	local poweredWeapons = self:GetPoweredWeapons()

	return
		isDescendantOfWeapon(weapon, poweredWeapons[1]) or
		isDescendantOfWeapon(weapon, poweredWeapons[2])
end

BoardPawn.GetArmedWeapon = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()
	local armedWeaponId = self:GetArmedWeaponId()

	if armedWeaponId == 0 then
		return "Move"
	elseif armedWeaponId == 1 then
		return getPoweredWeapon(ptable, "primary")
	elseif armedWeaponId == 2 then
		return getPoweredWeapon(ptable, "secondary")
	elseif armedWeaponId == 50 then
		return "Skill_Repair"
	end

	return nil
end

BoardPawn.GetQueuedWeaponId = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()
	local queued = self:GetQueued()

	return queued and queued.iQueuedSkill or -1
end

BoardPawn.GetQueuedWeapon = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")

	local ptable = self:GetPawnTable()
	local queuedWeaponId = self:GetQueuedWeaponId()

	if queuedWeaponId == 0 then
		return "Move"
	elseif queuedWeaponId == 1 then
		return getPoweredWeapon(ptable, "primary")
	elseif queuedWeaponId == 2 then
		return getPoweredWeapon(ptable, "secondary")
	elseif queuedWeaponId == 50 then
		return "Skill_Repair"
	end

	return nil
end

BoardPawn.GetLuaString = function(self)
	Assert.Equals("userdata", type(self), "Argument #0")
	return string.format("BoardPawn [id = %s, space = %s, name = %s]", self:GetId(), self:GetSpace():GetLuaString(), self:GetMechName())
end
BoardPawn.GetString = BoardPawn.GetLuaString


local function initializeBoardPawn()
	-- Overrides of existing functions need to be added at later time, since in
	-- order to grab a reference to original functions, we require a pawn instance.

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")

	BoardPawn.IsPilotSkill = pawn.IsAbility
	BoardPawn.GetPilotSkill = pawn.GetAbility


	modApi.events.onPawnClassInitialized:dispatch(BoardPawn, pawn)
	modApi.events.onPawnClassInitialized:unsubscribeAll()

	pawn = nil
	InitializeBoardPawn = nil
end

InitializeBoardPawn = initializeBoardPawn
