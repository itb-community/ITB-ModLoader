--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if an error occurred while loading mods.
--]]
local showScriptError

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showErrorFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	elseif btnIndex == 3 then
		showScriptError()
	end
end

local function showDialog(text, friendly)
	local frameTitle
	local buttonTexts
	local buttonTooltips

	if friendly then
		frameTitle = GetText("ScriptError_Friendly_FrameTitle")
		buttonTexts = {
			GetText("Button_Ok"),
			GetText("Button_DisablePopup"),
			GetText("Button_ShowScriptError")
		}
		buttonTooltips = {
			"",
			GetText("ButtonTooltip_DisablePopup"),
			GetText("ButtonTooltip_ShowScriptsError")
		}
	else
		frameTitle = GetText("ScriptError_FrameTitle")
		buttonTexts = {
			GetText("Button_Ok"),
			GetText("Button_DisablePopup")
		}
		buttonTooltips = {
			"",
			GetText("ButtonTooltip_DisablePopup")
		}
	end

	sdlext.showButtonDialog(
		frameTitle, text, responseFn,
		buttonTexts, buttonTooltips,
		{
			minW = 600,
			minH = 400,
			maxW = ScreenSizeX() * 0.6,
			maxH = ScreenSizeY() * 0.8,
		}
	)
end

local function showFriendlyDialog(text)
	showDialog(text, true)
end

function showScriptError()
	-- could show all errors one after another, but let's not...
	for dir, err in pairs(mod_loader.unmountedMods) do
		showDialog(string.format(GetText("ScriptError_FrameText_Mount"), dir, err))
		break
	end

	if mod_loader.firsterror then
		showDialog(mod_loader.firsterror)
	end
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
				if modApi.friendlyModFailPopup then
					local isError = false
					local texts = {}

					for dir, err in pairs(mod_loader.unmountedMods) do
						isError = true

						texts[#texts+1] = string.format(
							GetText("ScriptError_Friendly_ListEntryMount"),
							dir
						)
					end

					for id, mod in pairs(mod_loader.mods) do
						if mod.error then
							isError = true
							-- Mods requring to have a version is not enforced.
							local version = mod.version and " v"..mod.version or ""

							texts[#texts+1] = string.format(
								GetText("ScriptError_Friendly_ListEntryError"),
								mod.name, version, mod.id
							)
						end
					end

					if isError then
						showFriendlyDialog(string.format(
							GetText("ScriptError_Friendly_FrameText"),
							table.concat(texts, "\n")
						))
					end
				else
					showScriptError()
				end

				mod_loader.unmountedMods = {}
			end)
		end
	end
end)
