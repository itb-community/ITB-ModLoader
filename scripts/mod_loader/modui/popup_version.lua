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
		GetText("OldVersion_FrameTitle"), text,
		responseFn, nil, nil,
		{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
		{ "", GetText("ButtonTooltip_DisablePopup") }
	)
end

local versionFrameShown = false
modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
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
							GetText("OldVersion_ListEntry"),
							mod.name, mod.modApiVersion
						) .. "\n"
					end
				end

				if isOutOfDate then
					text = string.format(
						GetText("OldVersion_FrameText"),
						text, modApi.version
					)

					showVersionDialog(text)
				end
			end)
		end
	end
end)
