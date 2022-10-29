
local finalIslandWasHighlighted = false
local finalIslandIsHighlighted = false
local finalIslandIsSelected = false

modApi.final = {}

function modApi.final:isAvailable()
	return Game and Game:GetSector() > 2
end

function modApi.final:isHighlighted()
	return finalIslandIsHighlighted
end

function modApi.final:isSelected()
	return finalIslandIsSelected
end

local old_Mission_Final_GetDiffMod = Mission_Final.GetDiffMod
function Mission_Final.GetDiffMod(...)
	if modApi:getGameState() == GAME_STATE.MAP then
		finalIslandWasHighlighted = true
	end
	return old_Mission_Final_GetDiffMod(...)
end

modApi.events.onFrameDrawn:subscribe(function()
	if modApi:getGameState() ~= GAME_STATE.MAP then
		finalIslandIsHighlighted = false
		finalIslandWasHighlighted = false
		finalIslandIsSelected = false
		return
	end

	if finalIslandIsHighlighted ~= finalIslandWasHighlighted then
		finalIslandIsHighlighted = finalIslandWasHighlighted

		if finalIslandWasHighlighted then
			modApi.events.onFinalIslandHighlighted:dispatch()
		else
			modApi.events.onFinalIslandUnhighlighted:dispatch()
		end
	end

	if finalIslandIsSelected and not finalIslandIsHighlighted then
		finalIslandIsSelected = false
		modApi.events.onFinalIslandDeselected:dispatch()
	end

	finalIslandWasHighlighted = false
end)

modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
	local finalIslandClickDetector = Ui()
		:size(1,1)
		:addTo(uiRoot)

	finalIslandClickDetector.translucent = true

	function finalIslandClickDetector:mousedown(mx, my, button)
		if false
			or button ~= 1
			or modApi:getGameState() ~= GAME_STATE.MAP
		then
			return false
		end

		if not finalIslandIsSelected and finalIslandIsHighlighted then
			finalIslandIsSelected = true
			modApi.events.onFinalIslandSelected:dispatch()
		end

		return false
	end
end)
