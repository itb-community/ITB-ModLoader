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

BoardPawn.ClearUndoMove = function(self)
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
	if not Board or GetCurrentMission() == nil then
		return
	end

	local region = GetCurrentRegion(RegionData)
	local ptable = GetPawnTable(self:GetId(), region.player.map_data)
	
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
	if not Board or GetCurrentMission() == nil then
		return
	end

	local region = GetCurrentRegion(RegionData)
	local ptable = GetPawnTable(self:GetId(), region.player.map_data)

	local powered = ptable.bPowered

	if powered == nil then
		powered = true
	end

	return powered
end
	
BoardPawn.GetMutation = function(self)
	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local region = GetCurrentRegion(RegionData)
	local ptable = GetPawnTable(self:GetId(), region.player.map_data)
	
	return ptable.iMutation
end

BoardPawn.IsMutation = function(self, mutation)
	return self:GetMutation() == mutation
end

BoardPawn.IsArmor = function(self)
	local pilot = self:IsAbility("Armored")
	local mech = _G[self:GetType()]:GetArmor()
	local mutation = self:IsMutation(LEADER_ARMOR)
	-- TODO: Bug: killing an armor psion then respawning it via Board:AddPawn() causes this function to return false
	-- Need to update the savefile after a new pawn appears on the board
	
	return pilot or mech or mutation
end

BoardPawn.GetQueued = function(self)
	if not Board or GetCurrentMission() == nil then
		return
	end
	
	local region = GetCurrentRegion(RegionData)
	local ptable = GetPawnTable(self:GetId(), region.player.map_data)
	
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
	local queued = self:GetQueued()
	
	if queued == nil then
		return false
	end
	
	return Board:IsValid(queued.piQueuedShot)
end

BoardPawn.ApplyDamage = function(self, spaceDamage)
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
	if not Board or GetCurrentMission() == nil then
		return
	end

	local p = Board:GetPawn(mouseTile())
	if p then
		return p:GetId() == self:GetId()
	end

	return false
end

local function initializeBoardPawn()
	-- Overrides of existing functions need to be added at later time, since in
	-- order to grab a reference to original functions, we require a pawn instance.

	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	
	local oldSetNeutral = pawn.SetNeutral
	BoardPawn.SetNeutral = function(self, neutral)
		assert(type(neutral) == "boolean", "Expected boolean, got: "..type(neutral))

		oldSetNeutral(self, neutral)

		if not Board or GetCurrentMission() == nil then
			return
		end

		setSavefileFieldsForPawn(self, { bNeutral = neutral })
	end

	local oldSetPowered = pawn.SetPowered
	BoardPawn.SetPowered = function(self, powered)
		assert(type(powered) == "boolean", "Expected boolean, got: "..type(powered))

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
