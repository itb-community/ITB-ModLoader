--[[
	Adds a dialog option with particular important news about the current mod loader version.
	These news should be removed and updated between mod loader releases.
--]]

local news = {
}

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showNewsAboveVersion = modApi.version
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function showNewOptionDialog(text)
	sdlext.showButtonDialog(
		GetText("ModLoaderNews_FrameTitle"), text,
		responseFn,
		{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
		{ "", GetText("ButtonTooltip_DisablePopup") }
	)
end

local newsShown = false
modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
	if modApi:isVersionBelow(modApi.showNewsAboveVersion, modApi.version) then
		if not newsShown then
			newsShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(50, function()
				showNewOptionDialog(table.concat(news,"\n\n"))
			end)
		end
	end
end)
