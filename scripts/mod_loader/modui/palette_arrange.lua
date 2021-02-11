
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

local scrollarea
local content
local placeholder

local function savePaletteOrder()
	local modcontent = modApi:getCurrentModcontentPath()

	currentPaletteOrder = {}
	for _, button in ipairs(content.children) do
		if button.paletteId ~= nil then
			table.insert(currentPaletteOrder, button.paletteId)
		end
	end

	local new_paletteOrder = {}
	for i = 2, 11 do
		new_paletteOrder[i] = currentPaletteOrder[i]
	end

	sdlext.config(modcontent, function(obj)
		obj.paletteOrder = new_paletteOrder
	end)
end

local function buildColorMapBase()
	colorMapBase = {}

	local basePalette = GetColorMap(1)
	
	for i, gl_color in ipairs(basePalette) do
		local rgb = sdl.rgb(gl_color.r, gl_color.g, gl_color.b)
		colorMapBase[i*2-1] = rgb
		colorMapBase[i*2] = rgb
	end
	
	return colorMapBase
end

local function buildColorMap(palette)
	local res = shallow_copy(colorMapBase)
	
	for i = 1, 8 do
		local gl_color = palette[i]
		if gl_color ~= nil then
			res[i*2] = sdl.rgb(gl_color.r, gl_color.g, gl_color.b)
		end
	end
	
	return res
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
	ui:registerDragMove()

	ui.startDrag = function(self, mx, my, btn)
		UiDraggable.startDrag(self, mx, my, btn)
		if self.parent ~= content then return end

		local draggableIndex = list_indexof(content.children, self)
		self:detach()
		self:addTo(scrollarea, 1)

		table.remove(content.children, list_indexof(content.children, placeholder))
		table.insert(content.children, draggableIndex, placeholder)

		placeholder:show()
		content:relayout()
	end

	ui.stopDrag = function(self, mx, my, btn)
		UiDraggable.stopDrag(self, mx, my, btn)
		if self.parent ~= scrollarea then return end

		local placeholderIndex = list_indexof(content.children, placeholder)
		table.remove(content.children, placeholderIndex)

		self:detach()
		self:addTo(content, placeholderIndex)

		table.insert(content.children, placeholder)

		placeholder:hide()
	end

	ui.dragMove = function(self, mx, my)
		UiDraggable.dragMove(self, mx, my)
		if self.parent ~= scrollarea then return end

		for i = 2, #content.children do
			local ui = content.children[i]
			if rect_contains(ui.rect, mx, my) then
				if ui ~= placeholder then
					table.remove(content.children, list_indexof(content.children, placeholder))
					table.insert(content.children, i, placeholder)
				end

				if #content.children > 11 then
					content.children[11]:displayPaletteLocked(false)
					content.children[12]:displayPaletteLocked(true)

					if i > 11 then
						self:displayPaletteLocked(true)
					else
						self:displayPaletteLocked(false)
					end
				end

				return
			end
		end

		-- if we get this far, we are not hovering any of the buttons
		if content.children[#content.children] ~= placeholder then
			table.remove(content.children, list_indexof(content.children, placeholder))
			table.insert(content.children, placeholder)

			if #content.children > 11 then
				content.children[11]:displayPaletteLocked(false)
				self:displayPaletteLocked(true)
			end
		end
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
	local screen = sdl.screen()

	if currentPaletteOrder == nil then
		currentPaletteOrder = modApi:getPaletteIds()
		buildColorMapBase()
	end

	scrollarea = scroll

	placeholder = Ui()
		:widthpx(BUTTON_WIDTH)
		:heightpx(BUTTON_HEIGHT)
		:decorate({ })
		:hide()

	content = UiWeightLayout()
		:vgap(-1)
		:hgap(-1)
		:width(1)
		:height(1)
		:addTo(scroll)

	for i, paletteId in ipairs(currentPaletteOrder) do
		local image = modApi:getPalettePawnImage(paletteId) or IMAGE_PUNCH_MECH
		local palette = modApi:getPalette(paletteId)
		local colormap = buildColorMap(palette)
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

		if i > 11 then
			button:displayPaletteLocked(true)
		end

		if i == 1 then
			button.tooltip = GetText("PaletteArrange_RiftWalkers_Tooltip")
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
			
			if i > 11 then
				ui:displayPaletteLocked(true)
			else
				ui:displayPaletteLocked(false)
			end
		end
		
		table.insert(content.children, placeholder)
	end
	
	sdlext.buildButton(
		GetText("PaletteArrange_Current_Title"),
		GetText("PaletteArrange_Current_Tooltip"),
		function()
			reorderPalettes(modApi:getPaletteIds())
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)
	
	sdlext.buildButton(
		GetText("PaletteArrange_Default_Title"),
		GetText("PaletteArrange_Default_Tooltip"),
		function()
			reorderPalettes(modApi:getDefaultPaletteIds())
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)
	
	sdlext.buildButton(
		GetText("PaletteArrange_Random_Title"),
		GetText("PaletteArrange_Random_Tooltip"),
		function()
			local paletteOrder = modApi:getPaletteIds()
			local firstPalette = paletteOrder[1]
			table.remove(paletteOrder, 1)
			
			paletteOrder = randomize(paletteOrder)
			table.insert(paletteOrder, 1, firstPalette)
			
			reorderPalettes(paletteOrder)
		end
	)
	:heightpx(40)
	:addTo(buttonLayout)
end

local function onExit()
	savePaletteOrder()

	scrollarea = nil
	content = nil
	placeholder = nil
end

local function showArrangePaletteUi()
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
			GetText("PaletteArrange_FrameTitle"),
			0.6 * ScreenSizeX(), 0.8 * ScreenSizeY(),
			buildPaletteFrameContent,
			buildPaletteFrameButtons
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function ArrangePalettes()
	showArrangePaletteUi()
end
