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
		GetText("Version_FrameTitle"), text,
		responseFn,
		{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
		{ "", GetText("ButtonTooltip_DisablePopup") },
		{
			maxW = ScreenSizeX() * 0.6,
			maxH = ScreenSizeY() * 0.8,
		}
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
				local modsOutdated = false
				local texts_mods = {""}

				for id, mod in pairs(mod_loader.mods) do
					local modOutdated = false
					local texts = {""}

					if mod.modLoaderVersionOutOfDate then
						modOutdated = true

						texts[#texts+1] = GetText("Version_Outdated_ModLoader")
						texts[#texts+1] = mod.modApiVersion

					elseif mod.modLoaderVersionMismatch then
						modOutdated = true

						texts[#texts+1] = GetText("Version_Mismatch_ModLoader")
						texts[#texts+1] = mod.modApiVersion
					end

					if modOutdated and (mod.gameVersionOutOfDate or mod.gameVersionMismatch) then
						texts[#texts+1] = GetText("Version_And")
					end

					if mod.gameVersionOutOfDate then
						modOutdated = true

						texts[#texts+1] = GetText("Version_Outdated_Game")
						texts[#texts+1] = mod.gameVersion

					elseif mod.gameVersionMismatch then
						modOutdated = true

						texts[#texts+1] = GetText("Version_Mismatch_Game")
						texts[#texts+1] = mod.gameVersion
					end

					if modOutdated then
						modsOutdated = true

						texts[1] = string.format(
							GetText("Version_ListEntry"),
							mod.name
						)

						texts_mods[#texts_mods+1] = table.concat(texts, "")
					end
				end

				if modsOutdated then
					showVersionDialog(string.format(
						GetText("Version_FrameText"),
						modApi.version,
						modApi.gameVersion,
						table.concat(texts_mods, "\n")
					))
				end
			end)
		end
	end
end)
