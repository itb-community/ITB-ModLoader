--[[
	Adds a warning dialog informing the player that the mod loader
	does not support gamepads.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showGamepadWarning = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function showGamepadWarning()
	sdlext.showButtonDialog(
		modApi:getText("GamepadWarning_FrameTitle"),
		modApi:getText("GamepadWarning_FrameText"),
		responseFn, nil, nil,
		{ modApi:getText("Button_Ok"), modApi:getText("Button_DisablePopup") },
		{ "", modApi:getText("ButtonTooltip_DisablePopup") }
	)
end

-- Only show the warning once, to prevent having to switch back to mouse all the time
-- just to dismiss the warning
local warningShown = false
sdlext.addFrameDrawnHook(function(screen)
	if type(IsGamepad) == "function" and IsGamepad() and not warningShown and modApi.showGamepadWarning then
		warningShown = true

		modApi:scheduleHook(50, function()
			showGamepadWarning()
		end)
	end
end)
