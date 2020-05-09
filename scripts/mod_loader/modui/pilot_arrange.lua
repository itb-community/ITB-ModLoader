--[[
	Adds a new entry to the "Mod Content" menu, allowing to arrange
	pilots in a specific order, changing which ones become available
	for selection in the hangar.
--]]

local MAX_PILOTS = 13
local hangarBackdrop = sdlext.getSurface({ path = "resources/mods/ui/pilot-arrange-hangar.png" })
local pilotSurfaces = {}
local updateImmediately = true
-- copy of the list before we make any changes to it
local PilotListDefault = shallow_copy(PilotList)

function loadPilotsOrder()
	local order = {}

	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		for k, v in ipairs(obj.pilotOrder or {}) do
			order[v] = k
		end
	end)
	for k, v in ipairs(PilotListExtended) do
		if order[v] == nil then
			order[v] = 10000 + k
		end
	end
	table.sort(PilotListExtended,function(a,b)
		return order[a] < order[b]
	end)
end

function savePilotsOrder(pilots)
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		obj.pilotOrder = pilots
	end)
end

local function getOrCreatePilotSurface(pilotId)
	local surface = pilotSurfaces[pilotId]
	if not surface then
		surface = sdlext.getSurface({
			path = "img/portraits/pilots/"..pilotId..".png",
			scale = 2
		})
		pilotSurfaces[pilotId] = surface
	end

	return surface
end

local function createUi()
	local pilotButtons = {}

	local onExit = function(self)
		-- update a local variable into config
		local pilots = {}
		for i = 1, MAX_PILOTS do
			pilots[i] = pilotButtons[i].pilotId
		end
		savePilotsOrder(pilots)
		-- update the global if we have not entered the hangar
		if updateImmediately then
			PilotList = pilots
		end
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local portraitW = 122 + 8
		local portraitH = 122 + 8
		local gap = 16
		local cellW = portraitW + gap
		local cellH = portraitH + gap

		local frametop = Ui()
			:width(0.8):height(0.8)
			:posCentered()
			:caption(GetText("PilotArrange_FrameTitle"))
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(24)
			:addTo(frametop)

		local placeholder = Ui()
			:pospx(-cellW, -cellH)
			:widthpx(portraitW):heightpx(portraitH)
			:decorate({ })
			:addTo(scrollarea)

		local portraitsPerRow = math.floor(ui.w * frametop.wPercent / cellW)
		frametop
			:width((portraitsPerRow * cellW + scrollarea.padl + scrollarea.padr) / ui.w)
			:posCentered()

		ui:relayout()

		local function refreshPilotButtons()
			for i = 1, #pilotButtons do
				local col = (i - 1) % portraitsPerRow
				local row = math.floor((i - 1) / portraitsPerRow)
				local button = pilotButtons[i]

				button:pospx(cellW * col, cellH * row)
			end
		end

		local line = Ui()
				:width(1):heightpx(frametop.decorations[1].bordersize)
				:decorate({ DecoSolid(frametop.decorations[1].bordercolor) })
				:addTo(frametop)

		local buttonHeight = 40
		local buttonLayout = UiBoxLayout()
				:hgap(20)
				:padding(24)
				:width(1)
				:addTo(frametop)
		buttonLayout:heightpx(buttonHeight + buttonLayout.padt + buttonLayout.padb)

		ui:relayout()
		scrollarea:heightpx(scrollarea.h - (buttonLayout.h + line.h))

		line:pospx(0, scrollarea.y + scrollarea.h)
		buttonLayout:pospx(0, line.y + line.h)

		local defaultButton = Ui()
			:widthpx(portraitW * 2):heightpx(buttonHeight)
			:settooltip("Restore default pilot order")
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText("Default"),
			})
			:addTo(buttonLayout)

		defaultButton.onclicked = function()
			table.sort(pilotButtons, function(a, b)
				-- get index in default order, nil otherwise
				local indexA = list_indexof(PilotListDefault, a.pilotId)
				local indexB = list_indexof(PilotListDefault, b.pilotId)
				if indexA == -1 then
					indexA = INT_MAX
				end
				if indexB == -1 then
					indexB = INT_MAX
				end

				-- equal means they are non-vanilla, so sort by ID
				if indexA == indexB then
					return a.pilotId < b.pilotId
				end
				-- unequal means one is vanilla, order vanilla
				return indexA < indexB
			end)

			refreshPilotButtons()
			return true
		end

		local randomizeButton = Ui()
			:widthpx(portraitW * 2):heightpx(buttonHeight)
			:settooltip("Randomize pilot order")
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText("Randomize"),
			})
			:addTo(buttonLayout)

		randomizeButton.onclicked = function()
			for i = #pilotButtons, 2, -1 do
				local j = math.random(i)
				pilotButtons[i], pilotButtons[j] = pilotButtons[j], pilotButtons[i]
			end

			refreshPilotButtons()
			return true
		end

		local draggedElement
		local function rearrange()
			local index = list_indexof(pilotButtons, placeholder)
			if index ~= nil and draggedElement ~= nil then
				local col = math.floor(draggedElement.x / cellW + 0.5)
				local row = math.floor(draggedElement.y / cellH + 0.5)
				local desiredIndex = 1 + col + row * portraitsPerRow
				if desiredIndex < 1 then desiredIndex = 1 end
				if desiredIndex > #pilotButtons then desiredIndex = #pilotButtons end

				if desiredIndex ~= index then
					table.remove(pilotButtons, index)
					table.insert(pilotButtons, desiredIndex, placeholder)
				end
			end

			for i = 1, #pilotButtons do
				local col = (i - 1) % portraitsPerRow
				local row = math.floor((i - 1) / portraitsPerRow)
				local button = pilotButtons[i]

				button:pospx(cellW * col, cellH * row)
				if button == placeholder then
					placeholderIndex = i
				end
			end
		end

		local function addHangarBackdrop(i)
			local col = (i - 1) % portraitsPerRow
			local row = math.floor((i - 1) / portraitsPerRow)

			local backdrop = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:decorate({
					DecoAlign(0,-4),
					DecoSurface(hangarBackdrop)
				})
				:addTo(scrollarea)
		end

		local function addPilotButton(i, pilotId)
			local pilot = _G[pilotId]
			local col = (i - 1) % portraitsPerRow
			local row = math.floor((i - 1) / portraitsPerRow)

			local surface = getOrCreatePilotSurface(pilotId)
			local button = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:settooltip(GetText(pilot.Name))
				:decorate({
					DecoButton(),
					DecoAlign(-4),
					DecoSurface(surface)
				})
				:addTo(scrollarea)

			button:registerDragMove()
			button.pilotId = pilotId

			pilotButtons[i] = button

			button.startDrag = function(self, mx, my, btn)
				UiDraggable.startDrag(self, mx, my, btn)

				draggedElement = self
				placeholder.x = self.x
				placeholder.y = self.y

				local index = list_indexof(pilotButtons, self)
				if index ~= nil then
					pilotButtons[index] = placeholder
				end

				self:bringToTop()
				rearrange()
			end

			button.stopDrag = function(self, mx, my, btn)
				UiDraggable.stopDrag(self, mx, my, btn)

				local index = list_indexof(pilotButtons, placeholder)
				if index ~= nil and draggedElement ~= nil then
					pilotButtons[index] = draggedElement
				end

				placeholder:pospx(-2 * cellW, -2 * cellH)

				draggedElement = nil

				rearrange()
			end

			button.dragMove = function(self, mx, my)
				UiDraggable.dragMove(self, mx, my)

				rearrange()
			end
		end

		local dupes = {}
		for i = 1, #PilotListExtended do
			local pilotId = PilotListExtended[i]
			if not dupes[pilotId] then
				dupes[pilotId] = 1
				addPilotButton(#pilotButtons + 1, pilotId)
			end
		end
		for i = 1, MAX_PILOTS do
			addHangarBackdrop(i)
		end
	end)
end

function ArrangePilots()
	loadPilotsOrder()

	createUi()
end

sdlext.addHangarEnteredHook(function(screen)
	if updateImmediately then
		updateImmediately = false
		arrangePilotsButton.tip = GetText("PilotArrange_ButtonTooltip_Off")
	end
end)