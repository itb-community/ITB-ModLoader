--[[
	Adds a version string in bottom right corner of the screen when in main menu.
--]]

sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	local font = sdlext.font("fonts/NunitoSans_Regular.ttf", 12)
	local uiScale = GetUiScale()

	local versionText = Ui()
		:pospx(screen:w() - 200 * uiScale, screen:h() - 50 * uiScale)
		:widthpx(200 * uiScale):heightpx(20 * uiScale)
		:decorate({ DecoRAlignedText("Mod loader version: " .. modApi.version, font) })
		:addTo(uiRoot)
	versionText.decorations[1].rSpace = 16 * uiScale
	versionText.visible = false

	versionText.draw = function(self, screen)
		self.visible = sdlext.isMainMenu()
		Ui.draw(self, screen)
	end

	local relayout = function(screen, ...)
		local uiScale = GetUiScale()
		versionText:pospx(screen:w() - 200 * uiScale, screen:h() - 50 * uiScale)
		versionText:widthpx(200 * uiScale):heightpx(20 * uiScale)
		versionText.decorations[1]:setfont(sdlext.font("fonts/NunitoSans_Regular.ttf", 12 * uiScale))
		versionText.decorations[1].rSpace = 16 * uiScale
	end

	sdlext.addGameWindowResizedHook(relayout)
	sdlext.addSettingsStretchChangedHook(relayout)
end)
