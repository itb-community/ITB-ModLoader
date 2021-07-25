
local PALETTE_INDEX_BASE = 1
local PALETTE_INDEX_FIRST_MOVABLE = 2
local PALETTE_COUNT_HANGAR_MAX = 11
local IMAGE_PUNCH_MECH = "img/units/player/mech_punch_ns.png"
local FADE_RECT = sdl.rect(0,0,50,50)
local SURFACE_LOCK = sdlext.getSurface({
						path = "img/main_menus/lock.png",
						transformations = {{ scale = 2 }}
					})
local BUTTON_WIDTH = 134 + 8 + 5*2
local BUTTON_HEIGHT = 66 + 8 + 5*2

local currentPaletteOrder
local colorMapBase
local unlockedSquads

local scrollarea
local content
local placeholder

local function getUnlockedSquads()
	local profile = modApi:loadProfile() or {}
	local unlockedSquads = shallow_copy(profile.squads or {})

	-- squad 9 and 10 are Random and Custom, while squad 11 is Secret Squad.
	-- palette 9 is unlocked if Secret Squad is unlocked.
	-- palette 10 is unlocked if any squad beyond Rift Walkers is unlocked.
	-- one palette is hidden while Secret Squad is locked,
	-- so we keep palette 11 locked until it is unlocked.
	unlockedSquads[9] = unlockedSquads[11]

	return unlockedSquads
end

local function savePaletteOrder()
	local modcontent = modApi:getCurrentModcontentPath()

	currentPaletteOrder = {}
	for _, button in ipairs(content.children) do
		if button.paletteId ~= nil then
			table.insert(currentPaletteOrder, button.paletteId)
		end
	end

	local new_paletteOrder = {}
	for i = PALETTE_INDEX_FIRST_MOVABLE, PALETTE_COUNT_HANGAR_MAX do
		new_paletteOrder[i] = currentPaletteOrder[i]
	end

	sdlext.config(modcontent, function(obj)
		obj.paletteOrder = new_paletteOrder
	end)
end

local function buildSdlColorMapBase()
	colorMapBase = {}

	local basePalette = GetColorMap(PALETTE_INDEX_BASE)
	for i, gl_color in ipairs(basePalette) do
		local rgb = sdl.rgb(gl_color.r, gl_color.g, gl_color.b)
		colorMapBase[i*2-1] = rgb
		colorMapBase[i*2] = rgb
	end

	return colorMapBase
end

local function buildSdlColorMap(palette)
	local res = shallow_copy(colorMapBase)

	for i = 1, 8 do
		local gl_color = palette[i]
		if gl_color ~= nil then
			res[i*2] = sdl.rgb(gl_color.r, gl_color.g, gl_color.b)
		end
	end

	return res
end

local function buildPaletteName(id)
	return GetText("Palette_Name_"..id:gsub("%s", "_"))
end

local new_rect = sdl.rect(0,0,0,0)
local function buildContractedDeco(marginx, marginy, uiDeco, ...)
	local deco = uiDeco(...)
	deco.marginx = marginx
	deco.marginy = marginy

	deco.draw = function(self, screen, widget)
		local old_rect = widget.rect

		new_rect.x = old_rect.x + self.marginx
		new_rect.y = old_rect.y + self.marginy
		new_rect.w = old_rect.w - self.marginx * 2
		new_rect.h = old_rect.h - self.marginy * 2

		widget.rect = new_rect
		uiDeco.draw(self, screen, widget)
		widget.rect = old_rect
	end

	return deco
end

local function uiSetDraggable(ui)
	ui:registerDragDropList(placeholder)

	-- Called each time we hover over an element that's been registered as valid drop target
	ui.onDraggableEntered = function(self, draggable, target)
		if self == draggable then
			local placeholderIndex = list_indexof(content.children, placeholder)
			local targetIndex = list_indexof(content.children, target)
			placeholder:detach()
			content:add(placeholder, targetIndex)

			local firstIndex = math.min(placeholderIndex, targetIndex)

			for i = firstIndex, #content.children do
				local lock = not unlockedSquads[i]
				content.children[i]:displayPaletteLocked(lock)
			end

			local lock = not unlockedSquads[targetIndex]
			self:displayPaletteLocked(lock)
		end
	end

	ui.getDropTargets = function(self)
		if self.dropTargets == nil then
			self.dropTargets = {}
			for i = PALETTE_INDEX_FIRST_MOVABLE, #content.children do
				local target = content.children[i]
				table.insert(self.dropTargets, target)
			end
		end
		return self.dropTargets
	end
end

local function displayPaletteLocked(self, displayLocked)
	if self.deco_lock == nil then return end

	if displayLocked == false then
		self.deco_fade.color = deco.colors.transparent
		self.deco_lock.surface = nil
	else
		self.deco_fade.color = deco.colors.halfblack
		self.deco_lock.surface = SURFACE_LOCK
	end
end

local function buildPaletteFrameContent(scroll)
	if currentPaletteOrder == nil then
		currentPaletteOrder = modApi:getCurrentPaletteOrder()
		buildSdlColorMapBase()
	end

	unlockedSquads = getUnlockedSquads()

	scrollarea = scroll

	placeholder = Ui()
		:widthpx(BUTTON_WIDTH)
		:heightpx(BUTTON_HEIGHT)
		:decorate({ })
		:hide()

	content = UiFlowLayout()
		:vgap(-1)
		:hgap(-1)
		:width(1)
		:height(1)
		:compact(true)
		:addTo(scroll)
	-- Prevent the element from correcting children's sizes when inserting them,
	-- and their position is outside of the element's bounds.
	content.nofitx = true
	content.nofity = true

	for i, paletteId in ipairs(currentPaletteOrder) do
		local palette = modApi:getPalette(paletteId)
		local image = palette.images[1] or IMAGE_PUNCH_MECH
		local name = palette.name or buildPaletteName(palette.id)
		local colormap = buildSdlColorMap(palette.colorMap)
		local surface_mech = sdlext.getSurface({
								path = image,
								transformations = {
									{ colormap = colormap },
									{ scale = 2 },
									{ outline = { border = 2, color = deco.colors.buttonborder }, }
								}
							})
		local surface_icon = sdlext.getSurface({
								path = "img/units/player/color_boxes.png",
								transformations = {
									{ colormap = colormap },
									{ scale = 2 },
								}
							})

		local deco_button = buildContractedDeco(5,5, DecoButton)
		local deco_fade = DecoDraw(screen.drawrect, deco.colors.transparent, FADE_RECT)
		local deco_lock = DecoSurfaceAligned(nil, "right", "center")
		local button = Ui()
			:widthpx(BUTTON_WIDTH)
			:heightpx(BUTTON_HEIGHT)
			:settooltip(nil, name)
			:decorate({
				deco_button,
				DecoAlign(3,0),
				DecoSurfaceAligned(surface_icon, "right", "center"),
				DecoAnchor(),
				DecoAlign(-35,0),
				DecoSurfaceAligned(surface_mech, "center", "center"),
				DecoAnchor("right"),
				DecoAlign(-67,17),
				deco_fade,
				DecoAnchor(),
				DecoAlign(25,0),
				deco_lock,
			})
			:addTo(content)

		button.paletteId = paletteId
		button.deco_fade = deco_fade
		button.deco_lock = deco_lock
		button.displayPaletteLocked = displayPaletteLocked

		if not unlockedSquads[i] then
			button:displayPaletteLocked(true)
		end

		if i < PALETTE_INDEX_FIRST_MOVABLE then
			button.tooltip = GetText("PaletteArrange_RiftWalkers_Tooltip_Extra")
			button.disabled = true
			deco_button.hlcolor = deco_button.color
			deco_button.borderhlcolor = deco_button.bordercolor
		else
			uiSetDraggable(button)
		end
	end

	placeholder.displayPaletteLocked = displayPaletteLocked
	content:add(placeholder)
	scrollarea:relayout()
end

local function buildPaletteFrameButtons(buttonLayout)
	local function reorderPalettes(paletteOrder)
		local uis = {}
		for i = #content.children, 1, -1 do
			local ui = content.children[i]
			if ui.paletteId ~= nil then
				uis[ui.paletteId] = ui
			end

			table.remove(content.children, i)
		end

		for i, paletteId in ipairs(paletteOrder) do
			local ui = uis[paletteId]
			table.insert(content.children, ui)

			local lock = not unlockedSquads[i]
			ui:displayPaletteLocked(lock)
		end

		table.insert(content.children, placeholder)
	end

	sdlext.buildButton(
		GetText("PaletteArrange_Current_Title"),
		GetText("PaletteArrange_Current_Tooltip"),
		function()
			reorderPalettes(modApi:getCurrentPaletteOrder())
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)

	sdlext.buildButton(
		GetText("PaletteArrange_Default_Title"),
		GetText("PaletteArrange_Default_Tooltip"),
		function()
			reorderPalettes(modApi:getDefaultPaletteOrder())
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)

	sdlext.buildButton(
		GetText("PaletteArrange_Random_Title"),
		GetText("PaletteArrange_Random_Tooltip"),
		function()
			local paletteOrder = modApi:getCurrentPaletteOrder()

			local fixedPalettes = {}
			for i = PALETTE_INDEX_FIRST_MOVABLE - 1, 1, -1 do
				table.insert(fixedPalettes, paletteOrder[i])
				table.remove(paletteOrder, i)
			end

			paletteOrder = randomize(paletteOrder)

			for _, fixedPalette in ipairs(fixedPalettes) do
				table.insert(paletteOrder, 1, fixedPalette)
			end

			reorderPalettes(paletteOrder)
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)
end

local function responseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showPaletteRestartReminder = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function onExit()
	local oldPaletteOrder = modApi:getCurrentPaletteOrder()

	savePaletteOrder()

	unlockedSquads = nil
	scrollarea = nil
	content = nil
	placeholder = nil

	if modApi.showPaletteRestartReminder and not compare_tables(oldPaletteOrder, currentPaletteOrder) then
		sdlext.showButtonDialog(
			GetText("PaletteRestartRequired_FrameTitle"),
			GetText("PaletteRestartRequired_FrameText"),
			responseFn,
			{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
			{ "", GetText("ButtonTooltip_DisablePopup") }
		)
	end
end

local function showArrangePaletteUi()
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText("PaletteArrange_FrameTitle"),
			buildPaletteFrameContent,
			buildPaletteFrameButtons,
			{
				maxW = 0.6 * ScreenSizeX(),
				minH = 350,
				maxH = 0.8 * ScreenSizeY(),
				compactW = true,
				compactH = true
			}
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function ArrangePalettes()
	showArrangePaletteUi()
end
