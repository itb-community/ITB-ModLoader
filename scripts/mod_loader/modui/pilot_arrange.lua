--[[
	Adds a new entry to the "Mod Content" menu, allowing to arrange
	pilots in a specific order, changing which ones become available
	for selection in the hangar.
--]]

local MAX_PILOTS = modApi.constants.MAX_PILOTS
local hangarBackdrop = nil
local pilotLock = nil
local updateImmediately = true
-- copy of the list before we make any changes to it
local PilotListDefault = shallow_copy(PilotList)
local BLACK_MASK = sdl.rgb(0, 0, 0)
-- TODO: is there a proper way to check if their portrait is in the new folder?
local ADVANCED_PILOTS = {"Pilot_Arrogant", "Pilot_Caretaker", "Pilot_Chemical", "Pilot_Delusional"}

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
		-- put any pilots that are hidden at the end, to keep this order consistent with the hangar
			local pilot = _G[v]
		if pilot.IsEnabled ~= nil and not pilot:IsEnabled() then
			order[v] = 100000 + k
		elseif order[v] == nil then
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
	local advanced = list_contains(ADVANCED_PILOTS, pilotId)
	local prefix = advanced and "img/advanced/portraits/pilots/" or "img/portraits/pilots/"
	local path = prefix .. pilotId .. ".png"
	if unlocked then
		return sdlext.getSurface({
			path = path,
			scale = 2
		})
	else
		return sdlext.getSurface({
			path = path,
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
	-- if the pilot is a secret (not yet available in time pods/perfect island rewards), skip the button
	if pilot.IsEnabled ~= nil and not pilot:IsEnabled() then
		return nil
	end

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
		local descText = GetText(desc)
		-- show power requirement
		if pilot.PowerCost > 0 then
			descText = GetText("Pilot_PowerReq", pilot.PowerCost) .. "\n" .. descText
		end
		button:settooltip(descText, GetText(pilot.Name))
	end

	button:registerDragDropList(placeholder)

	-- Called each time we hover over an element that's been registered as valid drop target
	button.onDraggableEntered = function(self, draggable, target)
		if self == draggable then
			local targetIndex = list_indexof(pilotsLayout.children, target)
			placeholder:detach()
			pilotsLayout:add(placeholder, targetIndex)
		end
	end

	button.getDropTargets = function(self)
		if self.dropTargets == nil then
			self.dropTargets = {}
			for _, target in ipairs(pilotsLayout.children) do
				table.insert(self.dropTargets, target)
			end
		end
		return self.dropTargets
	end

	return button
end

local function buildPilotArrangeContent(scroll)
	local gap = 16

	pilotsLayout = UiFlowLayout()
		:width(1)
		:compact(true)
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
			if button ~= nil then
				pilotsLayout:add(button)
			end
		end
	end

	-- Scrollarea has no layout logic, so to show hangar backdrops, we can just another
	-- overlapping layout elements that will be drawn on top of the other (children are
	-- drawn in reverse order)
	local hangarLayout = UiFlowLayout()
			:width(1)
			:compact(true)
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
		if pilotsLayout.children[i] then
			pilots[i] = pilotsLayout.children[i].pilotId
		end
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
