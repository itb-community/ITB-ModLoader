--[[
	Adds a "Mod Content" button to the main menu, as well as
	an API for adding items to the menu it opens.
--]]

local modContent = {}
function sdlext.addModContent(text, func, tip)
	local obj = {
		caption = text,
		func = func,
		tip = tip
	}
	
	table.insert(modContent, obj)
	
	return obj
end

local buttonModContent
sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	if buttonModContent then return end
	
	buttonModContent = MainMenuButton("short")
		:pospx(0, screen:h() - 186)
		:caption(GetText("MainMenu_Button_ModContent"))
		:addTo(uiRoot)
	buttonModContent.visible = false

	sdlext.addGameWindowResizedHook(function(screen, oldSize)
		buttonModContent:pospx(0, screen:h() - 186)
	end)

	buttonModContent.onclicked = function(self, button)
		if button == 1 then
			sdlext.showDialog(function(ui, quit)
				local frame = Ui()
					:width(0.4):height(0.8)
					:posCentered()
					:caption(GetText("ModContent_FrameTitle"))
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
						:decorate({ DecoButton(), DecoAlign(0, 2), DecoCaption() })
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
