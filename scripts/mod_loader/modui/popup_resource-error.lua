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
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if not srf and modApi.showResourceWarning then
		srf = sdlext.surface("img/nullResource.png")
		srf:wasDrawn()

		modApi:scheduleHook(50, function()
			if srf:w() == 0 then
				sdlext.showButtonDialog(
					modApi:getText("ResourceError_FrameTitle"),
					modApi:getText("ResourceError_FrameText"),
					responseFn, nil, nil,
					{ modApi:getText("Button_Ok"), modApi:getText("Button_DisablePopup") },
					{ "", modApi:getText("ButtonTooltip_DisablePopup") }
				)
			end
		end)
	end
end)
