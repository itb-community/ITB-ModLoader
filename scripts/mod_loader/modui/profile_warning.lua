--[[
	Adds a dialog which appears when profile-specific config is enabled, and
	the player switches profiles.
--]]

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showProfileSettingsFrame = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

sdlext.addSettingsChangedHook(function(old, new)
	if
		modApi.showProfileSettingsFrame and modApi.profileConfig
	then
		modApi:scheduleHook(50, function()
			sdlext.showButtonDialog(
				modApi:getText("FrameTitle_ProfileSettings"),
				modApi:getText("FrameText_ProfileSettings"),
				responseFn, nil, nil,
				{ modApi:getText("Button_Ok"), modApi:getText("Button_DisablePopup") },
				{ "", modApi:getText("ButtonTooltip_DisablePopup") }
			)
		end)
	end
end)
