--[[
	Adds a warning dialog informing the player when the modloader
	fails to load the game's resources, causing modded UI to bug out.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showResourceWarning = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local srf = nil
modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
	if not srf and modApi.showResourceWarning then
		srf = sdlext.getSurface({ path = "img/nullResource.png" })
		srf:wasDrawn()

		modApi:scheduleHook(50, function()
			if srf:w() == 0 then
				sdlext.showButtonDialog(
					GetText("ResourceError_FrameTitle"),
					GetText("ResourceError_FrameText"),
					responseFn, nil, nil,
					{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
					{ "", GetText("ButtonTooltip_DisablePopup") }
				)
			end
		end)
	end
end)
