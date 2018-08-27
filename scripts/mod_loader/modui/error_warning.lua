--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if an error occurred while loading mods.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showErrorFrame = false
		SaveModLoaderConfig()
	end
end

local function showErrorDialog(text)
	sdlext.showButtonDialog(
		"Script Error", text,
		responseFn, nil, nil,
		{ "OK", "GOT IT, DON'T TELL ME AGAIN" },
		{ "", "This dialog will not be shown anymore. You can re-enable it in Configure Mod Loader." }
	)
end

local errorFrameShown = false
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if modApi.showErrorFrame then
		if not errorFrameShown then
			errorFrameShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(20, function()
				-- could show all errors one after another, but let's not...
				for dir, err in pairs(mod_loader.unmountedMods) do
					showErrorDialog(string.format("Unable to mount mod at [%s]:\n%s", dir, err))
					break
				end
				mod_loader.unmountedMods = {}

				if mod_loader.firsterror then
					showErrorDialog(mod_loader.firsterror)
				end
			end)
		end
	end
end)
