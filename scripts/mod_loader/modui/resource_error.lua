--[[
	Adds a warning dialog informing the player when the modloader
	fails to load the game's resources, causing modded UI to bug out.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showResourceWarning = false
		saveModLoaderConfig()
	end
end

local srf = nil
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if not srf and modApi.showResourceWarning then
		srf = sdlext.surface("img/nullResource.png")
		srf:wasDrawn()

		modApi:scheduleHook(30, function()
			if srf:w() == 0 then
				sdlext.showAlertDialog(
					"Resource Error",
					"The mod loader failed to load game resources. "..
					"This will cause some elements of modded UI to be invisible or incorrectly positioned. "..
					"This happens sometimes, but so far the cause is not known.\n\n"..
					"Restarting the game should fix this.",
					responseFn, nil, nil,
					"OK", "GOT IT, DON'T TELL ME AGAIN"
				)
			end
		end)
	end
end)
