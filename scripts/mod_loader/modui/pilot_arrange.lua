--[[
	Adds a new entry to the "Mod Content" menu, allowing to arrange
	pilots in a specific order, changing which ones become available
	for selection in the hangar.
--]]

local MAX_PILOTS = 13
local hangarBackdrop = nil
local pilotLock = nil
local updateImmediately = true
-- copy of the list before we make any changes to it
local PilotListDefault = shallow_copy(PilotList)
local BLACK_MASK = sdl.rgb(0, 0, 0)

--[[--
	Checks if the advanced AI pilot was unlocked
	@return True if the advanced AI was unlocked, false otherwise
]]
local function isPilotUnlocked(id)
	return type(Profile) == "table" and type(Profile.pilots) == "table" and list_contains(Profile.pilots, id)
end

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

local function savePilotsOrder(pilots)
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		obj.pilotOrder = pilots
	end)
end

-- gets a pilot surface, or if not unlocked a black surface
local function getOrCreatePilotSurface(pilotId)
	-- unlocked calls directly
	local unlocked = isPilotUnlocked(pilotId)
	if unlocked then
		return sdlext.getSurface({
			path = "img/portraits/pilots/"..pilotId..".png",
			scale = 2
		})
	else
		return sdlext.getSurface({
			path = "img/portraits/pilots/"..pilotId..".png",
			transformations = {
				{ scale = 2 },
				{ multiply = BLACK_MASK }
			}
		})
	end
end

local hangarDecorations = nil
local portraitSize = 122 + 8
local function buildHangarBackdrop()
	if not hangarDecorations then
		-- Build and cache hangar decorations
		hangarDecorations = {}
		table.insert(hangarDecorations, DecoAlign(0, -4))
		table.insert(hangarDecorations, DecoSurface(hangarBackdrop))
	end

	local backdrop = Ui()
		:widthpx(portraitSize):heightpx(portraitSize)
		:decorate(hangarDecorations)

	return backdrop
end

local pilotsLayout = nil
local function buildPilotButton(pilotId, placeholder)
	local pilot = _G[pilotId]
	local unlocked = isPilotUnlocked(pilotId)
	local surface = getOrCreatePilotSurface(pilotId)

	local decorations = {}
	table.insert(decorations, DecoButton())
	table.insert(decorations, DecoAlign(-4))
	table.insert(decorations, DecoSurface(surface))

	-- locked pilots add a lock icon
	if not unlocked then
		table.insert(decorations, DecoAlign(-(pilotLock:w()+surface:w())/2))
		table.insert(decorations, DecoSurface(pilotLock))
	end

	local button = Ui()
		:widthpx(portraitSize):heightpx(portraitSize)
		:decorate(decorations)
	button.pilotId = pilotId

	-- only show tooltip text if the pilot is unlocked
	if unlocked then
		-- if the pilot lacks a skill, state "No Special Ability"
		local desc = GetSkillInfo(pilot.Skill).desc
		if not desc or desc == "" then
			desc = "Hangar_NoAbility"
		end
		button:settooltip(string.format("%s\n\n%s", GetText(pilot.Name), GetText(desc)))
	end

	button:registerDragMove()

	-- Called each time we hover over an element that's been registered as valid drop target
	button.onDraggableEntered = function(self, draggable, target)
		-- The target elements get shifted around when dragged over, so they quickly flash
		-- on and off due to being hovered. Prevent that.
		target.hovered = false

		if self == draggable then
			local targetIndex = list_indexof(pilotsLayout.children, target)
			placeholder:detach()
			pilotsLayout:add(placeholder, targetIndex)

			pilotsLayout:relayout()
		end
	end

	button.startDrag = function(self, mx, my, btn)
		if btn ~= 1 then
			return
		end

		UiDraggable.startDrag(self, mx, my, btn)

		-- Put the dragged pilot button in the root UI element, so that we can move it freely
		-- without affecting the other buttons' layout.
		-- Correct position, since when moving an element between parents, its position is not
		-- automatically translated.
		local index = list_indexof(pilotsLayout.children, self)
		self:detach()
		pilotsLayout:add(placeholder, index)

		self:addTo(sdlext.getUiRoot())
		self.x = self.screenx
		self.y = self.screeny
		self:bringToTop()

		for _, child in ipairs(pilotsLayout.children) do
			button:registerDropTarget(child)
		end

		pilotsLayout:relayout()
	end

	button.stopDrag = function(self, mx, my, btn)
		if btn ~= 1 or not self.dragMoving then
			return
		end

		UiDraggable.stopDrag(self, mx, my, btn)

		-- Put the dragged pilot back into the layout. No need to correct position here,
		-- since the layout's logic will do that automatically
		local index = list_indexof(pilotsLayout.children, placeholder)
		self:detach()
		placeholder:detach()
		pilotsLayout:add(self, index)

		self:clearDropTargets()

		pilotsLayout:relayout()
	end

	button.dragWheel = function(self, mx, my, y)
		local offset = pilotsLayout.parent:computeOffset(y)

		pilotsLayout.parent:wheel(mx, my, y)

		self:processDropTargets(mx, my + offset)

		-- Scrollarea's wheel() function calls back to children's mousemove(), which
		-- updates hovered states. We need to correct that here.
		if self.root.hoveredchild ~= nil then
			self.root.hoveredchild.hovered = false
		end

		self.root.hoveredchild = self
		self.hovered = true
	end

	return button
end

local function buildPilotArrangeContent(scroll)
	local gap = 16

	pilotsLayout = UiFlowLayout()
		:width(1)
		:vgap(gap):hgap(gap)
		:padding(8)
		:addTo(scroll)
	-- Prevent the element from correcting children's sizes when inserting them,
	-- and their position is outside of the element's bounds.
	pilotsLayout.nofitx = true
	pilotsLayout.nofity = true

	local placeholder = Ui()
			:widthpx(portraitSize):heightpx(portraitSize)
			:decorate({})

	local pilotSeen = {}
	for i = 1, #PilotListExtended do
		local pilotId = PilotListExtended[i]
		if not pilotSeen[pilotId] then
			pilotSeen[pilotId] = true

			local button = buildPilotButton(pilotId, placeholder)
			pilotsLayout:add(button)
		end
	end

	-- Scrollarea has no layout logic, so to show hangar backdrops, we can just another
	-- overlapping layout elements that will be drawn on top of the other (children are
	-- drawn in reverse order)
	local hangarLayout = UiFlowLayout()
			:width(1)
			:vgap(gap):hgap(gap)
			:padding(8)
			:addTo(scroll)
	hangarLayout.ignoreMouse = true

	for i = 1, MAX_PILOTS do
		local button = buildHangarBackdrop()
		hangarLayout:add(button)
	end
end

local function btnDefaultHandlerFn()
	table.sort(pilotsLayout.children, function(a, b)
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

	pilotsLayout:relayout()

	return true
end

local function btnRandomHandlerFn()
	local order = {}
	for _, child in ipairs(pilotsLayout.children) do
		order[child] = math.random()
	end

	table.sort(pilotsLayout.children, function(a, b)
		return order[a] < order[b]
	end)

	pilotsLayout:relayout()

	return true
end

local function buildPilotArrangeButtons(buttonLayout)
	local btnDefault = sdlext.buildButton(
		GetText("PilotArrange_Default_Text"),
		GetText("PilotArrange_Default_Tooltip"),
		btnDefaultHandlerFn
 	)
	btnDefault:addTo(buttonLayout)

	local btnRandomize = sdlext.buildButton(
		GetText("PilotArrange_Random_Text"),
		GetText("PilotArrange_Random_Tooltip"),
		btnRandomHandlerFn
	)
	btnRandomize:addTo(buttonLayout)
end

--- function called to confirm when the UI is opened after the hangar
local function restartReminderDialogResponseFn(btnIndex)
	if btnIndex == 2 then
		modApi.showPilotRestartReminder = false
		SaveModLoaderConfig(CurrentModLoaderConfig())
	end
end

local function onExit()
	-- update a local variable into config
	local pilots = {}
	for i = 1, MAX_PILOTS do
		pilots[i] = pilotsLayout.children[i].pilotId
	end
	pilotsLayout = nil

	savePilotsOrder(pilots)

	-- update the global if we have not entered the hangar
	if updateImmediately then
		PilotList = pilots
	elseif modApi.showPilotRestartReminder then
		-- alert the user to restart the game
		modApi:scheduleHook(50, function()
			sdlext.showButtonDialog(
					GetText("OpenGL_FrameTitle"),
					GetText("PilotArrange_RestartWarning_Text"),
					restartReminderDialogResponseFn,
					{ GetText("Button_Ok"), GetText("Button_DisablePopup") },
					{ "", GetText("ButtonTooltip_DisablePopup") }
			)
		end)
	end
end

local function createUi()
	hangarBackdrop = sdlext.getSurface({ path = "resources/mods/ui/pilot-arrange-hangar.png" })
	pilotLock = sdlext.getSurface({ path = "img/main_menus/lock.png" })

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local frame = sdlext.buildButtonDialog(
				GetText("PilotArrange_FrameTitle"),
				buildPilotArrangeContent,
				buildPilotArrangeButtons,
				{
					maxW = 0.8 * ScreenSizeX(),
					maxH = 0.8 * ScreenSizeY(),
					compact = false
				}
		)

		frame:addTo(ui)
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
	end)
end

function ArrangePilots()
	loadPilotsOrder()

	createUi()
end

modApi.events.onHangarEntered:subscribe(function(screen)
	if updateImmediately then
		updateImmediately = false
		arrangePilotsButton.tip = GetText("PilotArrange_ButtonTooltip_Off")
	end
end)
