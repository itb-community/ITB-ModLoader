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
		GetText("GamepadWarning_FrameTitle"),
		GetText("GamepadWarning_FrameText"),
		responseFn, nil, nil,
		{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
		{ "", GetText("ButtonTooltip_DisablePopup") }
	)
end

-- Only show the warning once, to prevent having to switch back to mouse all the time
-- just to dismiss the warning
local warningShown = false
modApi.events.onFrameDrawn:subscribe(function(screen)
	if type(IsGamepad) == "function" and IsGamepad() and not warningShown and modApi.showGamepadWarning then
		warningShown = true

		modApi:scheduleHook(50, function()
			showGamepadWarning()
		end)
	end
end)
