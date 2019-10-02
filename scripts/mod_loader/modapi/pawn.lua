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
	Tests.AssertEquals("userdata", type(self), "Argument #0")
	Tests.AssertEquals("boolean", type(fire), "Argument #1")

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
	Tests.AssertEquals("userdata", type(self), "Argument #0")

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

	pawn = nil
	InitializeBoardPawn = nil
end

InitializeBoardPawn = initializeBoardPawn
