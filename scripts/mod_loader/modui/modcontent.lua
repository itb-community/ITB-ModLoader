--[[
	Adds a "Mod Content" button to the main menu, as well as
	an API for adding items to the menu it opens.
--]]

local modContentList = {}
function sdlext.addModContent(text, func, tip)
	local obj = {
		caption = text,
		func = func,
		tip = tip
	}
	
	table.insert(modContentList, obj)
	
	return obj
end

local function buildContent(scroll)
	local holder = UiBoxLayout()
		:vgap(12)
		:width(1)
		:addTo(scroll)

	local buttonHeight = 42
	for i = 1,#modContentList do
		local modContent = modContentList[i]

		local entryBtn = Ui()
			:width(1)
			:heightpx(buttonHeight)
			:caption(modContent.caption)
			:settooltip(modContent.tip)
			:decorate({ DecoButton(), DecoAlign(0, 2), DecoCaption() })
			:addTo(holder)

		if modContent.disabled then entryBtn.disabled = true end

		entryBtn.onclicked = function(self, button)
			if button == 1 then
				modContent.func()

				return true
			end

			return false
		end
	end
end

local function showModContentDialog()
	sdlext.showDialog(function(ui, quit)
		local frame = sdlext.buildScrollDialog(
			GetText("ModContent_FrameTitle"),
			buildContent,
			{
				maxW = ScreenSizeX() * 0.4,
				maxH = ScreenSizeY() * 0.8,
				compactH = false
			}
		);

		frame:addTo(ui)
			 :pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

local function buildModContentButton()
	local btn  = MainMenuButton("short")
			:pospx(0, ScreenSizeY() - 186)
			:caption(GetText("MainMenu_Button_ModContent"))
	btn.visible = false

	modApi.events.onGameWindowResized:subscribe(function(screen, oldSize)
		btn:pospx(0, ScreenSizeY() - 186)
	end)

	btn.onclicked = function(self, button)
		if button == 1 then
			showModContentDialog()
		end

		return true
	end

	return btn
end

local buttonModContent
modApi.events.onUiRootCreated:subscribe(function(screen, uiRoot)
	if buttonModContent then return end

	buttonModContent = buildModContentButton()
	buttonModContent:addTo(uiRoot);
end)

modApi.events.onMainMenuEntered:subscribe(function(screen, wasHangar, wasGame)
	if not buttonModContent.visible or wasGame then
		buttonModContent.visible = true
		buttonModContent.animations.slideIn:start()
	end
end)

modApi.events.onMainMenuExited:subscribe(function(screen)
	buttonModContent.visible = false
end)
