PawnTable = Pawn

local function isPawnTable(v)
	return v and type(v) == "table" and v.type and v.name and v.id and (v.undo_ready or v.undoReady)
end

local function clearUndoMoveInSavefile(pawn)
	UpdateSaveData(function(save)
		local id = pawn:GetId()

		local region = GetCurrentRegion(save.RegionData)

		for k, v in pairs(region.player.map_data) do
			if isPawnTable(v) and v.id == id then
				v.undo_ready = false
				v.undoReady = false
			end
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
					clearUndoMoveInSavefile(self)
				end)
			end)
		end
	)
end
