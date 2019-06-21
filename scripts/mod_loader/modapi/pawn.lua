PawnTable = Pawn

local function setSavefileFieldsForPawn(pawn, keyValuesTable)
	UpdateSaveData(function(save)
		local region = GetCurrentRegion(save.RegionData)
		local ptable = GetPawnTable(pawn:GetId(), region.player.map_data)

		for k, v in pairs(keyValuesTable) do
			ptable[k] = v
		end
	end)
end

BoardPawn.ClearUndoMove = function(self)
	if not Board or GetCurrentMission() == nil then
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

local function initializeBoardPawn()
	local pawn = PAWN_FACTORY:CreatePawn("PunchMech")
	local oldSetNeutral = pawn.SetNeutral

	BoardPawn.SetNeutral = function(self, neutral)
		assert(type(neutral) == "boolean", "Expected boolean, got: "..type(neutral))

		if not Board or GetCurrentMission() == nil then
			return
		end

		oldSetNeutral(self, neutral)

		setSavefileFieldsForPawn(self, { bNeutral = neutral })
	end

	BoardPawn.IsNeutral = function(self)
		if not Board or GetCurrentMission() == nil then
			return
		end

		local save = ReadSaveData()
		local region = GetCurrentRegion(save.RegionData)
		local ptable = GetPawnTable(self:GetId(), region.player.map_data)
		
		local neutral = ptable.bNeutral

		if neutral == nil then
			neutral = _G[self:GetType()].Neutral
		end
		if neutral == nil then
			neutral = false
		end

		return neutral
	end

	local oldSetPowered = pawn.SetPowered
	BoardPawn.SetPowered = function(self, powered)
		assert(type(powered) == "boolean", "Expected boolean, got: "..type(powered))
		if not Board or GetCurrentMission() == nil then
			return
		end

		oldSetPowered(self, powered)

		setSavefileFieldsForPawn(self, { bPowered = powered })
	end

	BoardPawn.IsPowered = function(self)
		if not Board or GetCurrentMission() == nil then
			return
		end

		local save = ReadSaveData()
		local region = GetCurrentRegion(save.RegionData)
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
		
		local save = ReadSaveData()
		local region = GetCurrentRegion(save.RegionData)
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
		
		return pilot or mech or mutation
	end
	
	BoardPawn.GetQueued = function(self)
		if not Board or GetCurrentMission() == nil then
			return
		end
		
		local save = ReadSaveData()
		local region = GetCurrentRegion(save.RegionData)
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

	pawn = nil
	InitializeBoardPawn = nil
end
InitializeBoardPawn = initializeBoardPawn
