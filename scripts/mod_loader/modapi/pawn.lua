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

		oldSetNeutral(self, neutral)

		if not Board or GetCurrentMission() == nil then
			return
		end

		setSavefileFieldsForPawn(self, { bNeutral = neutral })
	end

	BoardPawn.IsNeutral = function(self)
		if not Board or GetCurrentMission() == nil then
			return
		end

		local region = GetCurrentRegion(RegionData)
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

		oldSetPowered(self, powered)

		if not Board or GetCurrentMission() == nil then
			return
		end

		setSavefileFieldsForPawn(self, { bPowered = powered })
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

	local damageableTerrain = {
		[TERRAIN_ICE] = true,
		[TERRAIN_MOUNTAIN] = true,
		[TERRAIN_SAND] = true,
		[TERRAIN_FOREST] = true
	}
	BoardPawn.ApplyDamage = function(self, spaceDamage)
		if not Board or GetCurrentMission() == nil then
			return
		end

		-- Appropriated from Tarmean's Kinematics Squad

		local originalLoc = spaceDamage.loc
		spaceDamage.loc = self:GetSpace()

		local terrain = Board:GetTerrain(spaceDamage.loc)
		if terrain == TERRAIN_BUILDING then
			-- buildings don't reset health when re-setting iterrain 
			-- but they shouldn't overlap with units anyway
			return
		end

		local fx = SkillEffect()
	
		local isDamaged = Board:IsDamaged(spaceDamage.loc)
		if isDamaged then
			-- damaged ice/mountains are healed BEFORE we attack
			-- then our damage triggers and brings them back down to 1 health
			local dmg = SpaceDamage(spaceDamage.loc)
			dmg.iTerrain = Board:GetTerrain(spaceDamage.loc)

			fx:AddDamage(dmg)
		elseif damageableTerrain[terrain] then
			local dmg = SpaceDamage(spaceDamage.loc)
			dmg.iTerrain = TERRAIN_ROAD

			fx:AddDamage(dmg)
		end

		-- iTerrain doesn't remove the cloud
		if not Board:IsSmoke(spaceDamage.loc) and spaceDamage.iSmoke ~= EFFECT_CREATE then
			spaceDamage.iSmoke = EFFECT_REMOVE
		end
		-- If a pawn stands on a forest we have to extinguish them as well
		if not Board:IsFire(spaceDamage.loc) and spaceDamage.iFire ~= EFFECT_CREATE then
			spaceDamage.iFire = EFFECT_REMOVE
		end
		if (not isDamaged) and damageableTerrain[terrain] then
			-- this heals damageable terrain back up. This includes sand
			spaceDamage.iTerrain = terrain
		end

		fx:AddDamage(spaceDamage)

		Board:AddEffect(fx)

		spaceDamage.loc = originalLoc
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

	pawn = nil
	InitializeBoardPawn = nil
end

InitializeBoardPawn = initializeBoardPawn
