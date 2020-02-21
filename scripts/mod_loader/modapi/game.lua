
local GameClass = {}

GameClass.GetRep = function()
	return CUtils.GetRep()
end

GameClass.GetPow = function()
	return CUtils.GetPower()
end

GameClass.GetMaxPow = function()
	return CUtils.GetMaxPower()
end

GameClass.GetCores = function()
	return CUtils.GetCores()
end

GameClass.GetGridDef = function()
	return CUtils.GetGridDef()
end


GameClass.SetRep = function(reputation)
	Tests.AssertSignature{
		ret = "void",
		func = "SetRep",
		params = { reputation },
		{ "number|int" }
	}
	
	CUtils.SetRep(reputation)
end

GameClass.SetPow = function(power)
	Tests.AssertSignature{
		ret = "void",
		func = "SetPow",
		params = { power },
		{ "number|int" }
	}
	
	CUtils.SetPower(power)
end

GameClass.SetMaxPow = function(power_max)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMaxPow",
		params = { power_max },
		{ "number|int" }
	}
	
	CUtils.SetMaxPower(power_max)
end

GameClass.SetCores = function(cores)
	Tests.AssertSignature{
		ret = "void",
		func = "SetCores",
		params = { cores },
		{ "number|int" }
	}
	
	CUtils.SetCores(cores)
end

GameClass.SetGridDef = function(grid_def)
	Tests.AssertSignature{
		ret = "void",
		func = "SetGridDef",
		params = { grid_def },
		{ "number|int" }
	}
	
	CUtils.SetGridDef(grid_def)
end

GameClass.GridBlink = function()
	CUtils.DoGridBlink()
end


GameClass.IsCogHovered = function()
	return CUtils.IsCogHovered()
end

GameClass.IsRepHovered = function()
	return CUtils.IsRepHovered()
end

GameClass.IsCoreHovered = function()
	return CUtils.IsCoreHovered()
end

GameClass.IsPowerHovered = function()
	return CUtils.IsPowerHovered()
end

GameClass.IsGridDefHovered = function()
	return CUtils.IsGridDefHovered()
end

GameClass.IsPeopleHovered = function()
	return CUtils.IsPeopleHovered()
end


GameClass.GetRegionMechHovered = function()
	return CUtils.GetRegionMechHovered()
end

GameClass.GetRegionMechSelected = function()
	return CUtils.GetRegionMechSelected()
end

GameClass.GetMechshopItemOnCursor = function()
	return CUtils.GetMechshopItemOnCursor()
end


GameClass.IsMechshopTipImage = function()
	return CUtils.IsMechshopTipImage()
end


GameClass.IsMechshopTestHighlightable = function()
	return CUtils.IsMechshopTestHighlightable()
end

GameClass.IsMechshopNameHighlightable = function()
	return CUtils.IsMechshopNameHighlightable()
end

GameClass.IsMechshopPilotNameHighlightable = function()
	return CUtils.IsMechshopPilotNameHighlightable()
end

GameClass.IsMechshopClassHighlightable = function()
	return CUtils.IsMechshopClassHighlightable()
end

GameClass.IsMechshopInstallCoreHighlightable = function()
	return CUtils.IsMechshopInstallCoreHighlightable()
end

GameClass.IsMechshopUndoHighlightable = function()
	return CUtils.IsMechshopUndoHighlightable()
end

GameClass.IsMechshopHealthHighlightable = function()
	return CUtils.IsMechshopHealthHighlightable()
end

GameClass.IsMechshopHealthIconHighlightable = function()
	return CUtils.IsMechshopHealthIconHighlightable()
end

GameClass.IsMechshopMoveHighlightable = function()
	return CUtils.IsMechshopMoveHighlightable()
end

GameClass.IsMechshopMoveIconHighlightable = function()
	return CUtils.IsMechshopMoveIconHighlightable()
end

GameClass.IsMechshopInventoryHighlightable = function()
	return CUtils.IsMechshopInventoryHighlightable()
end

GameClass.IsMechshopInventoryUpHighlightable = function()
	return CUtils.IsMechshopInventoryUpHighlightable()
end

GameClass.IsMechshopInventoryDownHighlightable = function()
	return CUtils.IsMechshopInventoryDownHighlightable()
end

GameClass.IsMechshopSkill1Highlightable = function()
	return CUtils.IsMechshopSkill1Highlightable()
end

GameClass.IsMechshopSkill2Highlightable = function()
	return CUtils.IsMechshopSkill2Highlightable()
end

GameClass.IsMechshopAbilityHighlightable = function()
	return CUtils.IsMechshopAbilityHighlightable()
end


GameClass.IsMechshopTestHovered = function()
	return CUtils.IsMechshopTestHovered()
end

GameClass.IsMechshopNameHovered = function()
	return CUtils.IsMechshopNameHovered()
end

GameClass.IsMechshopPilotNameHovered = function()
	return CUtils.IsMechshopPilotNameHovered()
end

GameClass.IsMechshopClassHovered = function()
	return CUtils.IsMechshopClassHovered()
end

GameClass.IsMechshopInstallCoreHovered = function()
	return CUtils.IsMechshopInstallCoreHovered()
end

GameClass.IsMechshopCoresHovered = function()
	return CUtils.IsMechshopCoresHovered()
end

GameClass.IsMechshopUndoHovered = function()
	return CUtils.IsMechshopUndoHovered()
end

GameClass.IsMechshopHealthHovered = function()
	return CUtils.IsMechshopHealthHovered()
end

GameClass.IsMechshopHealthIconHovered = function()
	return CUtils.IsMechshopHealthIconHovered()
end

GameClass.IsMechshopMoveHovered = function()
	return CUtils.IsMechshopMoveHovered()
end

GameClass.IsMechshopMoveIconHovered = function()
	return CUtils.IsMechshopMoveIconHovered()
end

GameClass.IsMechshopInventoryHovered = function()
	return CUtils.IsMechshopInventoryHovered()
end

GameClass.IsMechshopInventoryUpHovered = function()
	return CUtils.IsMechshopInventoryUpHovered()
end

GameClass.IsMechshopInventoryDownHovered = function()
	return CUtils.IsMechshopInventoryDownHovered()
end

GameClass.IsMechshopSkill1Hovered = function()
	return CUtils.IsMechshopSkill1Hovered()
end

GameClass.IsMechshopSkill2Hovered = function()
	return CUtils.IsMechshopSkill2Hovered()
end

GameClass.IsMechshopAbilityHovered = function()
	return CUtils.IsMechshopAbilityHovered()
end


GameClass.SetMechshopTestHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopTestHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopTestHighlightable(flag)
end

GameClass.SetMechshopNameHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopNameHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopNameHighlightable(flag)
end

GameClass.SetMechshopPilotNameHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopPilotNameHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopPilotNameHighlightable(flag)
end

GameClass.SetMechshopClassHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopClassHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopClassHighlightable(flag)
end

GameClass.SetMechshopInstallCoreHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopInstallCoreHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopInstallCoreHighlightable(flag)
end

GameClass.SetMechshopUndoHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopUndoHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopUndoHighlightable(flag)
end

GameClass.SetMechshopHealthHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopHealthHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopHealthHighlightable(flag)
end

GameClass.SetMechshopHealthIconHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopHealthIconHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopHealthIconHighlightable(flag)
end

GameClass.SetMechshopMoveHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopMoveHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopMoveHighlightable(flag)
end

GameClass.SetMechshopMoveIconHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopMoveIconHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopMoveIconHighlightable(flag)
end

GameClass.SetMechshopInventoryHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopInventoryHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopInventoryHighlightable(flag)
end

GameClass.SetMechshopInventoryUpHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopInventoryUpHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopInventoryUpHighlightable(flag)
end

GameClass.SetMechshopInventoryDownHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopInventoryDownHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopInventoryDownHighlightable(flag)
end

GameClass.SetMechshopSkill1Highlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopSkill1Highlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopSkill1Highlightable(flag)
end

GameClass.SetMechshopSkill2Highlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopSkill2Highlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopSkill2Highlightable(flag)
end

GameClass.SetMechshopAbilityHighlightable = function(flag)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMechshopAbilityHighlightable",
		params = { flag },
		{ "boolean|bool" }
	}
	
	CUtils.SetMechshopAbilityHighlightable(flag)
end


function InitializeGameClass()
	-- modify existing game functions here
end

local game_metatable
local doInit = true
local oldSetGame = SetGame
function SetGame(game)
	if game ~= nil then
		
		if doInit then
			doInit = nil
			
			InitializeGameClass(game)
			
			local old_metatable = getmetatable(game)
			game_metatable = copy_table(old_metatable)
			
			game_metatable.__index = function(self, key)
				local value = GameClass[key]
				if value then
					return value
				end
				
				return old_metatable.__index(self, key)
			end
		end
		
		CUtils.SetUserdataMetatable(game, game_metatable)
	end
	
	oldSetGame(game)
end
