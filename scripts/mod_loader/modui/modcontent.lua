-- adds a "Mod Content" button to the main menu as wee as API for
-- adding items to the menu it opens

modContent = {}
function sdlext.addModContent(text, func, tip)
	local obj = {caption = text, func = func, tip = tip}
	
	modContent[#modContent+1] = obj
	
	return obj
end

local buttonModContent
local versionText
sdlext.addUiRootCreatedHook(function(screen, uiRoot)
	if buttonModContent then return end
	
	buttonModContent = MainMenuButton("short")
		:pospx(0, screen:h() - 186)
		:caption("Mod Content")
		:addTo(uiRoot)
	buttonModContent.visible = false

	versionText = Ui()
		:pospx(screen:w() - 200, screen:h() - 50)
		:widthpx(200):heightpx(20)
		:decorate({ DecoRAlignedText("Mod loader version: " .. modApi.version) })
		:addTo(uiRoot)
	versionText.decorations[1].rSpace = 8

	buttonModContent.onclicked = function()
		sdlext.uiEventLoop(function(ui,quit)
			ui.onclicked = function()
				quit()
				return true
			end

			local frame = Ui()
				:width(0.4):height(0.8)
				:pos(0.3, 0.1)
				:caption("Mod content")
				:decorate({ DecoFrame(), DecoFrameCaption() })
				:addTo(ui)

			local scrollarea = UiScrollArea()
				:width(1):height(1)
				:padding(16)
				:decorate({ DecoSolid(deco.colors.buttoncolor) })
				:addTo(frame)

			local holder = UiBoxLayout()
				:vgap(12)
				:width(1)
				:addTo(scrollarea)
			
			local buttonHeight = 42
			for i = 1,#modContent do
				local obj = modContent[i]
				local buttongo = Ui()
					:width(1)
					:heightpx(buttonHeight)
					:caption(obj.caption)
					:settooltip(obj.tip)
					:decorate({ DecoButton(),DecoCaption() })
					:addTo(holder)

				if obj.disabled then buttongo.disabled = true end
				
				buttongo.onclicked = function()
					quit()
					obj.func()

					return true
				end
			end
		end)

		return true
	end
end)

local errorFrameShown = false

sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	createUi(screen)

	if not buttonModContent.visible or wasGame then
		buttonModContent.visible = true
		buttonModContent.animations.slideIn:start()
	end

	-- update position of the version text in case the window is resized
	versionText
		:pospx(screen:w() - 200, screen:h() - 50)

	if modApi.showErrorFrame then
		if not errorFrameShown then
			errorFrameShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(20, function()
				-- could show all errors one after another, but let's not...
				for dir, err in pairs(mod_loader.unmountedMods) do
					showErrorFrame(string.format("Unable to mount mod at [%s]:\n%s",dir,err))
					break
				end
				mod_loader.unmountedMods = {}

				if mod_loader.firsterror then
					showErrorFrame(mod_loader.firsterror)
				end
			end)
		end
	end
end)

sdlext.addMainMenuExitedHook(function(screen)
	buttonModContent.visible = false
end)
