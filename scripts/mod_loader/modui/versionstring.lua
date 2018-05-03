--[[
	Adds a version string in bottom right corner of the screen when in main menu.
--]]

sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	local versionText = Ui()
		:pospx(screen:w() - 200, screen:h() - 50)
		:widthpx(200):heightpx(20)
		:decorate({ DecoRAlignedText("Mod loader version: " .. modApi.version) })
		:addTo(uiRoot)
	versionText.decorations[1].rSpace = 8

	-- override the versionText element's draw() function to also
	-- update its position
	versionText.draw = function(self, screen)
		self:pospx(screen:w() - 200, screen:h() - 50)
		Ui.draw(self, screen)
	end
end)
