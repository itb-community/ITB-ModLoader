--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if a mod could not be loaded due to its version requirement not being satisfied.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showVersionFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	elseif btnIndex == 3 then
		for id, mod in ipairs(mod_loader.mods) do
			if false
				or mod.modLoaderVersionOutOfDate
				or mod.gameVersionOutOfDate
				or mod.modLoaderVersionBelowThreshold
				or mod.gameVersionBelowThreshold
			then
				-- unimplemented
				-- disableModAndItsSubmods(mod)
			end
		end
	end
end

local function showVersionDialog(text)
	sdlext.showButtonDialog(
		GetText("Version_FrameTitle"), text,
		responseFn,
		{
			GetText("Button_Ok"),
			GetText("Button_DisablePopup"),
			GetText("Button_DisableMods")
		},
		{
			"",
			GetText("ButtonTooltip_DisablePopup"),
			GetText("ButtonTooltip_DisableMods")
		},
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
				local showDialog = false
				local texts_outdated = {}
				local texts_threshold = {}

				for id, mod in pairs(mod_loader.mods) do
					local outdated = false
					local belowThreshold = false
					local texts = {""}

					if mod.modLoaderVersionOutOfDate then
						outdated = true

						texts[#texts+1] = GetText("Version_AtLeast")
						texts[#texts+1] = GetText("Version_ModLoaderV")
						texts[#texts+1] = mod.modApiVersion
					end

					if mod.gameVersionOutOfDate then
						if outdated then
							texts[#texts+1] = GetText("Version_And")
						else
							texts[#texts+1] = GetText("Version_AtLeast")
							outdated = true
						end

						texts[#texts+1] = GetText("Version_GameV")
						texts[#texts+1] = mod.gameVersion
					end

					if outdated then
						showDialog = true

						texts[1] = string.format(
							GetText("Version_ListEntry_Requires"),
							mod.name, mod.id
						)

						texts_outdated[#texts_outdated+1] = table.concat(texts, "")
					end

					-- Clear and reuse table.
					texts = {""}

					if mod.modLoaderVersionBelowThreshold then
						belowThreshold = true

						texts[#texts+1] = GetText("Version_ModLoaderV")
						texts[#texts+1] = mod.modApiVersion
					end

					if mod.gameVersionBelowThreshold then
						if belowThreshold then
							texts[#texts+1] = GetText("Version_And")
						else
							belowThreshold = true
						end

						texts[#texts+1] = GetText("Version_GameV")
						texts[#texts+1] = mod.gameVersion
					end

					if belowThreshold then
						showDialog = true

						texts[1] = string.format(
							GetText("Version_ListEntry_BuiltFor"),
							mod.name, mod.id
						)

						texts_threshold[#texts_threshold+1] = table.concat(texts, "")
					end
				end

				if showDialog then
					local texts = {}

					if #texts_outdated > 0 then
						texts[#texts+1] = string.format(
							GetText("Version_ModList_Outdated"),
							table.concat(texts_outdated, "\n")
						)
					end

					if #texts_threshold > 0 then
						texts[#texts+1] = string.format(
							GetText("Version_ModList_Threshold"),
							table.concat(texts_threshold, "\n"),
							modApi.mlVersionThreshold,
							modApi.gameVersionThreshold
						)
					end

					showVersionDialog(string.format(
						GetText("Version_FrameText"),
						modApi.version,
						modApi.gameVersion,
						table.concat(texts)
					))
				end
			end)
		end
	end
end)
