--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if an error occurred while loading mods.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showErrorFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function showErrorDialog(text)
	local maxW = math.max(600, math.min(1000, 0.5 * ScreenSizeX()))
	local maxH = math.max(400, math.min(800, 0.8 * ScreenSizeY()))

	sdlext.showButtonDialog(
		GetText("ScriptError_FrameTitle"), text,
		responseFn, maxW, maxH,
		{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
		{ "", GetText("ButtonTooltip_DisablePopup") }
	)
end

local errorFrameShown = false
modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
	if modApi.showErrorFrame then
		if not errorFrameShown then
			errorFrameShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(50, function()
				-- could show all errors one after another, but let's not...
				for dir, err in pairs(mod_loader.unmountedMods) do
					showErrorDialog(string.format(GetText("ScriptError_FrameText_Mount"), dir, err))
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
