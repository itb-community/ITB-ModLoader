--[[
	Adds a "Mod Content" button to the main menu, as well as
	an API for adding items to the menu it opens.
--]]

local modContent = {}
function sdlext.addModContent(text, func, tip)
	local obj = {caption = text, func = func, tip = tip}
	
	modContent[#modContent+1] = obj
	
	return obj
end

local buttonModContent
sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	if buttonModContent then return end
	
	buttonModContent = MainMenuButton("short")
		:pospx(0, screen:h() - 186)
		:caption("Mod Content")
		:addTo(uiRoot)
	buttonModContent.visible = false

	buttonModContent.draw = function(self, screen)
		self:pospx(0, screen:h() - 186)

		Ui.draw(self, screen)
	end

	buttonModContent.onclicked = function(self, button)
		if button == 1 then
			sdlext.showDialog(function(ui, quit)
				ui.onclicked = function(self, button)
					quit()
					return true
				end

				local frame = Ui()
					:width(0.4):height(0.8)
					:pos(0.3, 0.1)
					:caption("Mod content")
					:decorate({ DecoFrameHeader(), DecoFrame() })
					:addTo(ui)

				local scrollarea = UiScrollArea()
					:width(1):height(1)
					:padding(16)
					:addTo(frame)

				local holder = UiBoxLayout()
					:vgap(12)
					:width(1)
					:addTo(scrollarea)
				
				local buttonHeight = 42
				for i = 1,#modContent do
					local obj = modContent[i]
					local entryBtn = Ui()
						:width(1)
						:heightpx(buttonHeight)
						:caption(obj.caption)
						:settooltip(obj.tip)
						:decorate({ DecoButton(),DecoCaption() })
						:addTo(holder)

					if obj.disabled then entryBtn.disabled = true end
					
					entryBtn.onclicked = function(self, button)
						if button == 1 then
							obj.func()

							return true
						end

						return false
					end
				end
			end)

			return true
		end

		return false
	end
end)

sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if not buttonModContent.visible or wasGame then
		buttonModContent.visible = true
		buttonModContent.animations.slideIn:start()
	end
end)

sdlext.addMainMenuExitedHook(function(screen)
	buttonModContent.visible = false
end)
