
local mechedit = {}

Region = Region or {}
Region.MechEdit = mechedit

modApi:AddHook("RegionMechHovered")
modApi:AddHook("RegionMechUnhovered")
modApi:AddHook("RegionMechDeselected")
modApi:AddHook("RegionMechSelected")
modApi:AddHook("RegionPilotExitMech")
modApi:AddHook("RegionPilotEnterMech")

PILOT_SKILL_HP = 0
PILOT_SKILL_MOVE = 1
PILOT_SKILL_DEF = 2
PILOT_SKILL_CORE = 3

local MECH_NONE = -1
local PILOT_NONE = nil

local selected_mech_prev = MECH_NONE
local hovered_mech_prev = MECH_NONE
local pilot_prev = PILOT_NONE

local function update_mechedit()
	CUtils.SetMechEditTestHighlightable(true)
	CUtils.SetMechEditClassHighlightable(true)
	CUtils.SetMechEditHealthIconHighlightable(true)
	CUtils.SetMechEditMoveHighlightable(true)
	CUtils.SetMechEditMoveIconHighlightable(true)
end


function mechedit.GetItemOnCursor()
	if not Game then
		return nil
	end
	
	return CUtils.GetMechEditItemOnCursor()
end

function mechedit.IsTipImage()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditTipImage()
end

-- Highlightable
function mechedit.IsTestHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditTestHighlightable()
end

function mechedit.IsClassHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditClassHighlightable()
end

function mechedit.IsNameHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditNameHighlightable()
end

function mechedit.IsPilotNameHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditPilotNameHighlightable()
end

function mechedit.IsInstallHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditInstallCoreHighlightable()
end

function mechedit.IsUndoHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditUndoHighlightable()
end

function mechedit.IsHealthHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditHealthHighlightable()
end

function mechedit.IsHealthIconHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditHealthIconHighlightable()
end

function mechedit.IsMoveHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditMoveHighlightable()
end

function mechedit.IsMoveIconHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditMoveIconHighlightable()
end

function mechedit.IsInventoryHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditInventoryHighlightable()
end

function mechedit.IsInventoryUpHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditInventoryUpHighlightable()
end

function mechedit.IsInventoryDownHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditInventoryDownHighlightable()
end

function mechedit.IsSkill1Highlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditSkill1Highlightable()
end

function mechedit.IsSkill2Highlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditSkill2Highlightable()
end

function mechedit.IsAbilityHighlightable()
	if not Game then
		return nil
	end
	
	return CUtils.IsMechEditAbilityHighlightable()
end

-- Hovered
function mechedit.IsTestHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditTestHovered()
end

function mechedit.IsClassHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditClassHovered()
end

function mechedit.IsNameHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditNameHovered()
end

function mechedit.IsPilotNameHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditPilotNameHovered()
end

function mechedit.IsInstallHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditInstallCoreHovered()
end

function mechedit.IsReactorHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditCoresHovered()
end

function mechedit.IsUndoHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditUndoHovered()
end

function mechedit.IsHealthHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditHealthHovered()
end

function mechedit.IsHealthIconHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditHealthIconHovered()
end

function mechedit.IsMoveHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditMoveHovered()
end

function mechedit.IsMoveIconHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditMoveIconHovered()
end

function mechedit.IsInventoryHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditInventoryHovered()
end

function mechedit.IsInventoryUpHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditInventoryUpHovered()
end

function mechedit.IsInventoryDownHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditInventoryDownHovered()
end

function mechedit.IsSkill1Hovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditSkill1Hovered()
end

function mechedit.IsSkill2Hovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditSkill2Hovered()
end

function mechedit.IsAbilityHovered()
	if not Game then
		return false
	end
	
	return CUtils.IsMechEditAbilityHovered()
end

function mechedit.SetTestHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetTestHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditTestHighlightable(highlightable)
end

function mechedit.SetClassHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetClassHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditClassHighlightable(highlightable)
end

function mechedit.SetHealthIconHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetHealthIconHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditHealthIconHighlightable(highlightable)
end

function mechedit.SetMoveHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMoveHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditMoveHighlightable(highlightable)
end

function mechedit.SetMoveIconHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetMoveIconHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditMoveIconHighlightable(highlightable)
end

function mechedit.SetNameHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetNameHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditNameHighlightable(highlightable)
end

function mechedit.SetPilotNameHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetPilotNameHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditPilotNameHighlightable(highlightable)
end

function mechedit.SetInstallHighlightable(highlightable)
	Tests.AssertSignature{
		ret = "void",
		func = "SetInstallHighlightable",
		params = { highlightable },
		{ "boolean|bool" }
	}
	
	if not Game then
		return
	end
	
	CUtils.SetMechEditInstallCoreHighlightable(highlightable)
end


function Region.GetSelectedMech()
	if not Game then
		return nil
	end
	
	return Game:GetPawn((CUtils.GetRegionMechSelected()))
end

function Region.GetHoveredMech()
	if not Game then
		return nil
	end
	
	return Game:GetPawn((CUtils.GetRegionMechHovered()))
end

sdlext.addFrameDrawnHook(function(screen)
	if not Game then
		return
	end
	
	local selected_mech = CUtils.GetRegionMechSelected()
	
	if selected_mech ~= selected_mech_prev then
		if selected_mech_prev ~= MECH_NONE then
			modApi:fireRegionMechDeselectedHooks(Game:GetPawn(selected_mech_prev))
		end
		
		if selected_mech ~= MECH_NONE then
			update_mechedit()
			pilot_prev = Game:GetPawn(selected_mech):GetPilot()
			
			modApi:fireRegionMechSelectedHooks(Game:GetPawn(selected_mech))
		end
		
		selected_mech_prev = selected_mech
	else
		if selected_mech_prev ~= MECH_NONE then
			local pilot = Game:GetPawn(selected_mech_prev):GetPilot()
			
			if pilot_prev ~= pilot then
				if pilot or pilot_prev ~= PILOT_NONE then
					update_mechedit()
				end
				
				if pilot_prev ~= PILOT_NONE then
					modApi:fireRegionPilotExitMechHooks(pilot_prev)
				end
				
				if pilot then
					modApi:fireRegionPilotEnterMechHooks(pilot)
				end
			end
			
			pilot_prev = pilot
		end
	end
	
	local hovered_mech = CUtils.GetRegionMechHovered()
	
	if hovered_mech ~= hovered_mech_prev then
		if hovered_mech_prev ~= MECH_NONE then
			modApi:fireRegionMechUnhoveredHooks(Game:GetPawn(hovered_mech_prev))
		end
		
		if hovered_mech ~= MECH_NONE then
			modApi:fireRegionMechHoveredHooks(Game:GetPawn(hovered_mech))
		end
		
		hovered_mech_prev = hovered_mech
	end
end)
