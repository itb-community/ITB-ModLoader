--[[
	Adds a version string in bottom right corner of the screen when in main menu.
--]]

sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	local versionText = Ui()
		:pospx(screen:w() - 200, screen:h() - 50)
		:widthpx(200):heightpx(20)
		:decorate({ DecoRAlignedText(GetText("VersionString") .. modApi.version) })
		:addTo(uiRoot)
	versionText.decorations[1].rSpace = 8
	versionText.visible = false

	versionText.draw = function(self, screen)
		self.visible = sdlext.isMainMenu()
		Ui.draw(self, screen)
	end

	local relayout = function(screen, ...)
		versionText:pospx(screen:w() - 200, screen:h() - 50)
		versionText:widthpx(200):heightpx(20)
		versionText.decorations[1].rSpace = 16
		versionText.decorations[1].rSpace = 8
	end

	sdlext.addGameWindowResizedHook(relayout)
end)
