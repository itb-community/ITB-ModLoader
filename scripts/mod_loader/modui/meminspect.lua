
-- TODO: fetch object size from memedit saved data
-- start with object size 0 if none is set.

local path = GetParentPath(...)

deco.surfaces.arrowLeftOn   = sdlext.getSurface{ path = "img/ui/upgrade/arrow2_on.png" }
deco.surfaces.arrowLeftHl   = sdlext.getSurface{ path = "img/ui/upgrade/arrow2_select.png" }
deco.surfaces.arrowLeftOff  = sdlext.getSurface{ path = "img/ui/upgrade/arrow2_off.png" }
deco.surfaces.arrowRightOn  = sdlext.getSurface{ path = "img/ui/upgrade/arrow_on.png" }
deco.surfaces.arrowRightHl  = sdlext.getSurface{ path = "img/ui/upgrade/arrow_select.png" }
deco.surfaces.arrowRightOff = sdlext.getSurface{ path = "img/ui/upgrade/arrow_off.png" }

local BUTTON = {MAIN = {}}
BUTTON.MAIN.WIDTH = 210
BUTTON.MAIN.HEIGHT = 60
BUTTON.MAIN.OFFSET = 329
BUTTON.WIDTH = 150
BUTTON.HEIGHT = 41
BUTTON.GAP = 7

local objectSize = 0x71A8
local resetContent = function() end
local setNodePos = function() end
local backgroundpane
local mainFrame
local frameReleaseSnap
local frameSnapLeft
local frameSnapRight
local scrollableUi
local hierarchyView

local function getObjAddr(obj)
	local result = 0

	try(function()
		Assert.Equals('userdata', type(obj))
		result = modApi.memedit.dll.debug.getObjAddr(obj)
	end)
	:catch(function()
		error("Failed call to debug.getObjAddr")
	end)

	return result
end

local function isAddrNotPtr(addr, size)
	local result = false

	try(function()
		Assert.Equals('number', type(addr))
		Assert.Equals('number', type(size))
		result = modApi.memedit.dll.debug.isAddrNotPointer(addr, size)
	end)
	:catch(function()
		error("Failed call to debug.isAddrNotPointer")
	end)

	return result
end

local function getAddrInt(addr)
	local result = 0

	try(function()
	Assert.Equals('number', type(addr))
		result = modApi.memedit.dll.debug.getAddrInt(addr)
	end)
	:catch(function()
		error("Failed call to debug.getAddrInt")
	end)

	return result
end

local function getAddrValue(addr)
	local result = 0

	try(function()
	Assert.Equals('number', type(addr))
		result = modApi.memedit.dll.debug.getAddrValue(addr)
	end)
	:catch(function()
		error("Failed call to debug.getAddrValue")
	end)

	return result
end

local function getTopVisibleNode()
	return math.ceil(scrollableUi.parent.dyTarget / (41 + 5))
end

local Address = {}
CreateClass(Address)

Address.base = 0x0
Address.delta = 0x0
Address.value = "pending..."

function Address:GetAddr()
	return self.base + self.delta
end

function Address:GetValue()
	return self.value
end

local RootNode = nil
local Node = {}
CreateClass(Node)

Node.ui = nil
Node.addr = nil
Node.prev = nil
Node.next = nil

function Node:Add(node)
	Assert.False(node == self)
	Assert.False(node == nil)
	Assert.False(RootNode.uiContainer == nil)

	if node.ui then
		RootNode.uiContainer:add(node.ui)
	end

	self.next = node
	node.prev = self
end

function Node:Detach()
	local node = self:GetLeaf()

	repeat
		node.ui:detach()
		node = node.prev
	until self == node.next

	if self.prev then
		self.prev.next = nil
		self.prev = nil
	end
end

function Node:GetNext()
	return self.next
end

function Node:GetPrev()
	return self.prev
end

function Node:GetRoot()
	local node = self

	while node.prev do
		node = node.prev
	end

	return node
end

function Node:GetLeaf()
	local node = self

	while node.next do
		node = node.next
	end

	return node
end

local function node_clicked(self, button)
	if button == 1 then
		local node = self.node
		local newScrollPos = 0

		if node.next then
			node.next:Detach()
			resetContent()
			newScrollPos = math.floor((node.pos / 0x4) * (41 + 5))
		end

		setNodePos(node, newScrollPos)

		return true
	end

	return false
end

function Node:BuildUi()
	local text
	local delta = self.addr.delta

	if self.name then
		text = self.name .." >"
	elseif type(delta) == 'number' then
		text = string.format("0x%X >", delta)
	else
		text = string.format("%s >", tostring(delta))
	end

	local deco_text = DecoText(text)
	local ui = Ui()
		:widthpx(deco_text.surface:w()):heightpx(40)
		:decorate{
			DecoSolidHoverable(deco.colors.transparent, deco.colors.button),
			deco_text
		}

	ui.deco_text = deco_text
	ui.onclicked = node_clicked
	ui.node = self
	self.ui = ui

	return ui
end

local scanning = false
local updateAddr = {}
local scanhead = 0x0
local rangePerFrame = 0xFF
local updatedThisFrame = false

local function updateAddrValues()
	if not updatedThisFrame and #updateAddr > 0 then
		local from = scanhead
		scanhead = scanhead + math.min(rangePerFrame, #updateAddr - 1)
		local to = scanhead

		for i = from, to do
			local i = (i-1) % #updateAddr + 1
			local v = updateAddr[i]

			if isAddrNotPtr(v.base, v.delta + 0x4) then
				v.value = "out of bounds"
			else
				v.value = getAddrValue(v:GetAddr())
			end
			v.updated = true
		end

		-- cycle around
		scanhead = scanhead % #updateAddr + 1
		updatedThisFrame = true
	end
end

modApi.events.onFrameDrawStart:subscribe(function()
	if scanning and not updatedThisFrame then
		updateAddrValues()
	end

	updatedThisFrame = false
end)

function searchForValue(value)
	local number = tonumber(value)
	local node = RootNode:GetLeaf()
	local base = node.addr:GetAddr()
	local step = 0x4

	if number ~= nil then
		value = number
	end

	local function isMatch(addr, value)
		if type(value) == 'number' then
			return getAddrInt(addr) == value
		elseif type(value) == 'string' then
			local addrValue = getAddrValue(addr)
			if type(addrValue) == 'string' then
				return addrValue:find(value)
			end
			return false
		else
			return getAddrValue(addr) == value
		end
	end

	for delta = (getTopVisibleNode() + 1) * 0x4, objectSize - step, step do
		local addr = base + delta
		if isAddrNotPtr(addr, 0x4) then
			break
		end
		if isMatch(addr, value) then
			newScrollPos = math.floor((delta / 0x4) * (41 + 5))
			setNodePos(node, newScrollPos)
			return true
		end
	end

	return false
end

local function setObjectSize(size)
	objectSize = size
	scrollableUi
		:heightpx((objectSize / 0x4) * (41 + 5))
end

local function setRootNode(inspect_object)
	if hierarchyView then
		hierarchyView.children = {}
	end

	resetContent()

	local addr = Address:new()
	addr.delta = getObjAddr(inspect_object.obj)
	addr.value = getAddrInt(addr.delta)

	local node = Node:new()
	node.name = inspect_object.name
	node.pos = 0x0
	node.addr = addr
	node:BuildUi()
		:addTo(hierarchyView)

	RootNode = node
	RootNode.uiContainer = hierarchyView
end

local function buildTopbarUi()
	local topbar = Ui()
		:width(1):heightpx(100)
		:padding(10)

	hierarchyView = UiFlowLayout()
		:width(1):height(1)
		:addTo(topbar)

	local inspect_object = { obj = Board, name = "Board" }
	local selected_pawn = Board:GetSelectedPawn()
	if selected_pawn then
		inspect_object = { obj = selected_pawn, name = "Pawn" }
	end

	setRootNode(inspect_object)
	setNodePos(RootNode, 0)
	
	return topbar
end

local function buildScrollableUi()

	scanhead = 0x0
	scanning = true

	local content = Ui()
		:heightpx((objectSize / 0x4) * (41 + 5))
		:width(1)
	content.freeElements = {}
	content.elements = {}
	scrollableUi = content

	function setNodePos(self, pos)
		content.parent.dyTarget = pos
	end

	function resetContent()
		for i, element in pairs(content.elements) do
			table.insert(content.freeElements, element)
			content.elements[i] = nil
		end

		content.pendingUpdate = true
	end

	local function element_relayout(self)
		if self.address.updated then
			self.address.updated = false

			local delta = self.address.delta
			local value = self.address.value
			local text

			if type(value) == 'string' then
				text = string.format("[0x%X] = %s", delta, value)
				self.isButton = false
			elseif type(value) == 'number' then
				if math.abs(value) > 0xFFFFFF then
					text = string.format("[0x%X] = 0x%X", delta, value)
				else
					text = string.format("[0x%X] = %s", delta, value)
				end
				self.isButton = not isAddrNotPtr(value, 0x4)
			else
				text = string.format("[0x%X] = Pending...", delta)
				self.isButton = false
			end

			self.deco_text:setsurface(text)
		end
		Ui.relayout(self)
	end

	local function element_clicked(self, button)
		if self.isButton and button == 1 then

			Assert.Equals('number', type(self.address.delta))

			local node = Node:new()
			node.name = string.format("0x%X", self.address.delta)
			node.addr = Address:new{ base = self.address.value }
			node:BuildUi()

			RootNode:GetLeaf():Add(node)

			node.prev.pos = self.address.delta

			resetContent()
			setNodePos(node, 0)

			return true
		end

		return false
	end

	local function deco_button_draw(self, screen, widget)
		if widget.isButton then
			self.bordercolor = deco.colors.buttonborder
			DecoButton.draw(self, screen, widget)
		else
			self.bordercolor = deco.colors.buttonborderdisabled
			DecoFrame.draw(self, screen, widget)
		end
	end

	function content:relayout()

		local scroll = self.parent
		if scroll then
			local visibleElementFirst = math.floor(scroll.dy / (41 + 5))
			local visibleElementLast = math.floor((scroll.h + scroll.dy) / (41 + 5))

			if self.pendingUpdate or self.scrollY ~= scroll.dy then
				self.pendingUpdate = false
				for i, element in pairs(self.elements) do
					if element.index < visibleElementFirst or element.index > visibleElementLast then
						table.insert(self.freeElements, element)
						self.elements[i] = nil
					end
				end

				for elementIndex = visibleElementFirst, visibleElementLast do
					if not self.elements[elementIndex] then

						local element
						if #self.freeElements > 0 then
							element = self.freeElements[#self.freeElements]
							table.remove(self.freeElements, #self.freeElements)
						else
							local addr = Address:new{}
							local deco_button = DecoButton()
							local deco_text = DecoText()

							deco_button.bordersize = 2
							deco_button.draw = deco_button_draw

							table.insert(updateAddr, addr)

							element = Ui()
								:width(1):heightpx(41)
								:decorate{
									deco_button,
									DecoAnchor(),
									DecoAlign(5, 0),
									deco_text
								}
								:addTo(self)
							element.address = addr
							element.deco_text = deco_text
							element.relayout = element_relayout
							element.onclicked = element_clicked
						end

						element.y = elementIndex * (41 + 5)
						element.index = elementIndex
						element.address.base = RootNode:GetLeaf().addr:GetAddr()
						element.address.delta = elementIndex * 0x4
						element.address.value = "pending..."
						element.address.updated = true

						self.elements[elementIndex] = element
					end
				end

				self.scrollY = scroll.dy

				updateAddrValues()
			end
		end

		Ui.relayout(self)
	end

	return content
end

local function cleanup()
	scanhead = 0x0
	scanning = false
end

local function buildContent(scroll)
	local owner = scroll.parent

	local container = Ui()
		:width(1):height(1)

	local content = UiWeightLayout()
		:width(1):height(1)
		:vgap(0):hgap(0)
		:orientation(false)
		:addTo(container)

	buildTopbarUi()
		:addTo(content)

	local scroll = UiScrollArea()
		:width(1):height(1)
		:padding(10)
		:addTo(content)
	scroll.scrollOvershoot = 0

	buildScrollableUi()
		:addTo(scroll)

	function container:relayout()
		if Board then
			local selected_pawn = Board:GetSelectedPawn()
			if selected_pawn ~= nil then
				local text = string.format(
					GetText("MemInspect_Pawn_Text"),
					selected_pawn:GetMechName()
				)
				if owner.captiontext ~= text then
					owner:caption(text)
				end
			else
				local text = GetText("MemInspect_Board_Text")
				if owner.captiontext ~= text then
					owner:caption(text)
				end
			end
		end
		Ui.relayout(self)
	end

	return container
end

local function buildButtons(buttonLayout)
	buttonLayout
		:width(1):hgap(0)

	local btnContainer = UiWeightLayout()
		:width(1):height(1)
		:addTo(buttonLayout)

	local arrowLeft = Ui()
		:widthpx(22):heightpx(42)
		:decorate{
			DecoSurfaceButton(
				deco.surfaces.arrowLeftOn,
				deco.surfaces.arrowLeftHl,
				deco.surfaces.arrowLeftOff
			)
		}
		:addTo(btnContainer)

	local centerContainer = UiWeightLayout()
		:width(1):height(1)
		:addTo(btnContainer)

	local arrowRight = Ui()
		:widthpx(22):heightpx(42)
		:decorate{
			DecoSurfaceButton(
				deco.surfaces.arrowRightOn,
				deco.surfaces.arrowRightHl,
				deco.surfaces.arrowRightOff
			)
		}
		:addTo(btnContainer)

	-- local inspectObject = UiTextBox()
		-- :width(1):heightpx(BUTTON.HEIGHT)
		-- :clip()
		-- :decorate{
			-- DecoTextBox{
				-- alignH = "center",
				-- alignV = "center"
			-- },
			-- DecoBorder(),
			-- DecoInvertedLabel("obj"),
		-- }
		-- :addTo(centerContainer)
	-- inspectObject.onEnter = function(self)
		-- local text = self.textfield:get(1, self.textfield:size())
		-- local obj = _G[text]
		-- if type(obj) == 'userdata' then
			-- setRootNode{obj = obj, name = text}
		-- end
		-- self.textfield:delete(0, self.textfield:size())
	-- end

	-- local searchObject = UiTextBox()
		-- :width(1):heightpx(BUTTON.HEIGHT)
		-- :clip()
		-- :decorate{
			-- DecoTextBox{
				-- alignH = "center",
				-- alignV = "center"
			-- },
			-- DecoBorder(),
			-- DecoInvertedLabel("search"),
		-- }
		-- :addTo(centerContainer)
	-- searchObject.onEnter = function(self)
		-- local text = self.textfield:get(1, self.textfield:size())
		-- if not searchForValue(text) then
			-- self.textfield:delete(0, self.textfield:size())
		-- end
	-- end

	-- local objectSize = UiTextBox(string.format("0x%X", objectSize))
		-- :width(1):heightpx(BUTTON.HEIGHT)
		-- :clip()
		-- :decorate{
			-- DecoTextBox(),
			-- DecoBorder(),
			-- DecoInvertedLabel("size"),
		-- }
		-- :addTo(centerContainer)
	-- objectSize.onEnter = function(self)
		-- local text = self.textfield:get(1, self.textfield:size())
		-- local size = tonumber(text)
		-- if size == nil or size <= 0 then
			-- self.textfield:delete(0, self.textfield:size())
			-- return
		-- end
		-- setObjectSize(size)
	-- end

	function arrowLeft:onclicked(button)
		if button ~= 1 then
			return
		end

		if mainFrame.snap == "left" then
		elseif mainFrame.snap == "right" then
			frameReleaseSnap()
		else
			frameSnapLeft()
		end

		return true
	end

	function arrowRight:onclicked(button)
		if button ~= 1 then
			return
		end

		if mainFrame.snap == "left" then
			frameReleaseSnap()
		elseif mainFrame.snap == "right" then
		else
			frameSnapRight()
		end

		return true
	end
end

local function showWindow()
	Assert.False(Board == nil)

	if backgroundpane then
		frameReleaseSnap()
		return
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = function()
			cleanup()
			backgroundpane = nil
		end

		local snapSideWidth = 300
		local morphspeed = 0.7
		backgroundpane = ui
		backgroundpane.wheel = Ui.wheel
		backgroundpane.mousedown = Ui.mousedown
		backgroundpane.mouseup = Ui.mouseup
		backgroundpane.mousemove = Ui.mousemove
		backgroundpane.keydown = Ui.keydown
		backgroundpane.keyup = Ui.keyup

		local frame = sdlext.buildButtonDialog(
			GetText("MemInspect_General_Text"),
			buildContent,
			buildButtons,
			{
				maxW = 0.6 * ScreenSizeX(),
				maxH = 0.95 * ScreenSizeY(),
				compactH = false
			}
		)

		mainFrame = frame
		frame:addTo(ui)
		function frame:relayout()
			UiWeightLayout.relayout(self)
			self.h = math.floor(0.95 * ScreenSizeY())
			self.y = math.floor((ScreenSizeY() - self.h) / 2)
			if self.snap == "left" then
				self.targetw = self.targetw or math.floor(0.6 * ScreenSizeX())
				self.targetx = 0
			elseif self.snap == "right" then
				self.targetw = self.targetw or math.floor(0.6 * ScreenSizeX())
				self.targetx = ScreenSizeX() - self.targetw
			else
				self.targetw = math.floor(0.6 * ScreenSizeX())
				self.targetx = math.floor((ScreenSizeX() - self.targetw) / 2)
			end
			if math.abs(self.targetx - self.x) > 1 then
				self.x = self.targetx * (1 - morphspeed)  + self.x * morphspeed
			else
				self.x = self.targetx
			end
			if math.abs(self.targetw - self.w) > 1 then
				self.w = self.targetw * (1 - morphspeed)  + self.w * morphspeed
			else
				self.w = self.targetw
			end
		end

		function frameReleaseSnap()
			frame.snap = nil
			backgroundpane.decorations[1].color = deco.colors.dialogbg
			backgroundpane.dismissible = true
			backgroundpane.translucent = false
		end

		function frameSnapLeft()
			frame.snap = "left"
			frame.targetw = snapSideWidth
			backgroundpane.decorations[1].color = deco.colors.transparent
			backgroundpane.dismissible = false
			backgroundpane.translucent = true
		end

		function frameSnapRight()
			frameSnapLeft()
			frame.snap = "right"
		end
	end)
end

local function calculateOpenButtonPosition()
	-- Use the Buttons element maintained by the game itself.
	-- This way we don't have to worry about calculating locations
	-- for our UI, we can just offset based on the game's own UI
	-- whenever the screen is resized.
	local btnEndTurn = Buttons["action_end"]
	return btnEndTurn.pos.x + BUTTON.MAIN.OFFSET, btnEndTurn.pos.y
end

local function createOpenButton(root)

	local button = sdlext.buildButton(
		GetText("MemInspect_Board_Title"),
		GetText("MemInspect_Board_Tooltip"),
		function()
			showWindow()
		end
	)
	:widthpx(BUTTON.MAIN.WIDTH):heightpx(BUTTON.MAIN.HEIGHT)
	:pospx(calculateOpenButtonPosition())
	:addTo(root)

	button.deco_text = button.decorations[3]

	function button:draw(screen)
		self.visible = true
			and mod_loader:hasExtension("memedit")
			and modApi.memedit:isDebug()
			and sdlext.isConsoleOpen() ~= true
			and Board ~= nil

		Ui.draw(self, screen)
	end

	function button:setText(title, tooltip)
		if button.deco_text.text ~= title then
			button.deco_text:setsurface(title)
			button.tooltip = tooltip
		end

		return self
	end

	function button:relayout()
		if Board then
			local selected_pawn = Board:GetSelectedPawn()
			if selected_pawn ~= nil then
				button:setText(
					GetText("MemInspect_Pawn_Title"),
					GetText("MemInspect_Pawn_Tooltip")
				)
			else
				button:setText(
					GetText("MemInspect_Board_Title"),
					GetText("MemInspect_Board_Tooltip")
				)
			end
		end
		Ui.relayout(self)
	end

	modApi.events.onSettingsChanged:subscribe(function()
		button:pospx(calculateOpenButtonPosition())
	end)

	modApi.events.onGameWindowResized:subscribe(function()
		button:pospx(calculateOpenButtonPosition())
	end)
end

modApi.events.onUiRootCreated:subscribe(function(screen, root)
	createOpenButton(root)
end)
