--[[
	Adds a new entry to the "Mod Content" menu, allowing to arrange
	pilots in a specific order, changing which ones become available
	for selection in the hangar.
--]]

function loadPilotsOrder()
	local order = {}
	sdlext.config("modcontent.lua", function(obj)
		for k, v in ipairs(obj.pilotOrder or {}) do
			order[v] = k
		end
	end)
	for k, v in ipairs(PilotList) do
		if order[v] == nil then
			order[v] = 10000 + k
		end
	end
	table.sort(PilotList,function(a,b)
		return order[a] < order[b]
	end)
end

function savePilotsOrder()
	sdlext.config("modcontent.lua", function(obj)
		obj.pilotOrder = PilotList
	end)
end

local function createUi()
	local pilotButtons = {}

	local onExit = function(self)
		PilotList = {}

		for i = 1, #pilotButtons do
			PilotList[i] = pilotButtons[i].pilotId
		end
		
		savePilotsOrder()
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit
		
		local portraitW = 122 + 8
		local portraitH = 122 + 8
		local gap = 10
		local cellW = portraitW + gap
		local cellH = portraitH + gap

		local frametop = Ui()
			:width(0.8):height(0.8)
			:posCentered()
			:caption("Rearrange Pilots")
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

		local draggedElement
		local function stopDrag()
			local index = list_indexof(pilotButtons, placeholder)
			if index ~= nil and draggedElement ~= nil then
				pilotButtons[index] = draggedElement
			end
			
			placeholder:pospx(-2 * cellW, -2 * cellH)
			
			draggedElement = nil
		end
		local function startDrag(button)
			stopDrag()
			draggedElement = button
			
			placeholder.x = button.x
			placeholder.y = button.y
		
			local index = list_indexof(pilotButtons,button)
			if index ~= nil then
				pilotButtons[index] = placeholder
			end
		end
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
			
			if placeholderIndex ~= nil and draggedElement ~= nil then
			
			end
		end
		
		local function addPilotButton(i, pilotId)
			local pilot = _G[pilotId]
			local col = (i - 1) % portraitsPerRow
			local row = math.floor((i - 1) / portraitsPerRow)
			
			local surface = sdl.scaled(2, sdlext.surface("img/portraits/pilots/"..pilotId..".png"))
			local button = Ui()
				:widthpx(portraitW):heightpx(portraitH)
				:pospx(cellW * col, cellH * row)
				:decorate({
					DecoButton(),
					DecoAlign(-4),
					DecoSurface(surface)
				})
				:addTo(scrollarea)
			
			button.pilotId = pilotId
			
			pilotButtons[i] = button
			
			button.mousedown = function(self, mx, my)
				startDrag(self)
				
				self.dragged = true
				self.dragX = mx
				self.dragY = my
				
				self:bringToTop()
				
				Ui.mousedown(self, mx, my)
				rearrange()
				
				return true
			end
			
			button.mousemove = function(self, mx, my)
				if self.dragged then
					self.x = self.x + mx - self.dragX
					self.y = self.y + my - self.dragY
					self.dragX = mx
					self.dragY = my
				end
				
				rearrange()
				
				return Ui.mousemove(self, mx, my)
			end
			
			button.mouseup = function(self, mx, my)
				self.dragged = false
				
				stopDrag()
				rearrange()
				
				return Ui.mouseup(self, mx, my)
			end
		end
		
		local dupes = {}
		for i = 1, #PilotList do
			local pilotId = PilotList[i]
			if not dupes[pilotId] then 
				dupes[pilotId] = 1
				addPilotButton(#pilotButtons + 1, pilotId)
			end
		end
	end)
end

function showArrangePilotsUi()
	loadPilotsOrder()

	createUi()
end

sdlext.addHangarEnteredHook(function(screen)
	if not arrangePilotsButton.disabled then
		arrangePilotsButton.disabled = true
		arrangePilotsButton.tip = 
			"Pilots can only be arranged before the New Game button is pressed.\n\n"
			.."Restart the game to be able to arrange pilots."
	end
end)
