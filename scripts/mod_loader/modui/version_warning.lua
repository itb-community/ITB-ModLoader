--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if a mod could not be loaded due to its version requirement not being satisfied.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showVersionFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function showVersionDialog(text)
	sdlext.showButtonDialog(
		"Mod Loader Outdated", text,
		responseFn, nil, nil,
		{ "OK", "GOT IT, DON'T TELL ME AGAIN" },
		{ "", "This dialog will not be shown anymore. You can re-enable it in Configure Mod Loader." }
	)
end

local versionFrameShown = false
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if modApi.showVersionFrame then
		if not versionFrameShown then
			versionFrameShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(50, function()
				local text = ""
				local isOutOfDate = false

				for id, mod in pairs(mod_loader.mods) do
					if mod.outOfDate then
						isOutOfDate = true
						text = text .. string.format(
							"- [%s] requires at least version %s.",
							mod.name, mod.modApiVersion
						) .. "\n"
					end
				end

				if isOutOfDate then
					text = "The following mods could not be loaded, because they require a newer version of the mod loader:\n\n"..
						text..
						"\nYour installed version: ".. modApi.version

					showVersionDialog(text)
				end
			end)
		end
	end
end)
