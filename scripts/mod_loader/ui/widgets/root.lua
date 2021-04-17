UiRoot = Class.inherit(Ui)

local function PriorityUi()
	local ui = Ui()
		:width(1):height(1)
		:setTranslucent()
	ui.nofitx = true
	ui.nofity = true

	return ui
end

function UiRoot:new()
	Ui.new(self)
	
	self.hoveredchild = nil
	self.pressedchild = nil
	self.focuschild = self
	self.translucent = true
	self.priorityUi = PriorityUi():addTo(self)
	self.tooltipUi = UiTooltip():addTo(self.priorityUi)
	self.dropdownUi = PriorityUi():addTo(self.priorityUi)
	self.draggableUi = PriorityUi():addTo(self.priorityUi)
end

function UiRoot:draw(screen)
	-- priorityUi is relayed out last, but drawn first
	self.priorityUi.visible = false
	self:relayout()

	self.priorityUi.visible = true
	self.priorityUi:bringToTop()
	self.dropdownUi:relayout()
	self.draggableUi:relayout()

	self:updateStates()

	-- update tooltip after everything else has been updated
	self.tooltipUi:relayout()

	Ui.draw(self, screen)
end

function UiRoot:setfocus(newfocus)
	assert(
		-- we permit the focus to be set to nil, ui elements with a parent,
		-- or to the root itself
		newfocus == nil or (newfocus.parent or newfocus.root == newfocus),
		"Unable to set focus, because the UI element has no parent"
	)

	-- clear old focus
	local p = self.focuschild
	while p do
		p.focused = false
		p = p.parent
	end

	self.focuschild = newfocus
	
	p = self.focuschild
	while p do
		p.focused = true
		p = p.parent
	end

	return true
end

function UiRoot:cleanupDropdown()
	for i = #self.dropdownUi.children, 1, -1 do
		local dropdown = self.dropdownUi.children[i]

		local parent = dropdown.owner
		while parent.parent do
			-- fetch root of dropDown
			parent = parent.parent
		end

		-- if owner is not attached to root, remove dropDown
		if parent ~= self then
			table.remove(self.dropdownUi.children, i)
		end
	end
end

function UiRoot:updateHoveredState()
	if self.hoveredchild ~= nil then
		self.hoveredchild.hovered = false
	end
	self.hoveredchild = nil

	-- if there is a pressed element, keep it hovered.
	if self.pressedchild ~= nil then
		self.hoveredchild = self.pressedchild
		self.hoveredchild.hovered = true
		return false
	end

	Ui.updateHoveredState(self)
	return false
end

function UiRoot:updateTooltipState()
	self.tooltip_static = false
	self.tooltip_title = false
	self.tooltip = ""

	if self.hoveredchild ~= nil and self.hoveredchild.hovered then
		self.hoveredchild:updateTooltipState()
	end
end

function UiRoot:updateDraggedState()
	if self.pressedchild ~= nil then
		if self.pressedchild.dragged then
			local mx, my = sdl.mouse.x(), sdl.mouse.y()
			self.pressedchild:dragMove(mx, my)
		end
	end
end

function UiRoot:updateStates()
	local mx, my = sdl.mouse.x(), sdl.mouse.y()
	self:updateContainsMouse(mx, my)
	self:updateHoveredState()
	self:updateDraggedState()
	self:updateTooltipState()
	self:update()
end

function UiRoot:pressHoveredchild(mx, my, button)
	local pressedchild = self.hoveredchild
	if pressedchild == nil then return end

	self.pressedchild = pressedchild
	pressedchild.pressed = true

	if pressedchild.draggable then
		self.draggedchild = pressedchild
		pressedchild.dragged = true
		pressedchild:startDrag(mx, my, button)
	end

	return pressedchild:mousedown(mx, my, button)
end

function UiRoot:releasePressedchild(mx, my, button)
	local draggedchild = self.draggedchild
	local pressedchild = self.pressedchild

	if draggedchild ~= nil then
		self.draggedchild.dragged = false
		self.draggedchild = nil

		-- Hack: always call stopDrag with argument button = 1
		draggedchild:stopDrag(mx, my, 1)
	end

	if pressedchild ~= nil then
		self.pressedchild.pressed = false
		self.pressedchild = nil

		if button == 1 then
			local consumeEvent = pressedchild:mouseup(mx, my, button)

			if pressedchild.containsMouse and pressedchild:clicked(button) then
				consumeEvent = true
			end

			return consumeEvent
		end
	end

	return false
end

function UiRoot:event(eventloop)
	if not self.visible then return false end
	
	local type = eventloop:type()
	local mx = sdl.mouse.x()
	local my = sdl.mouse.y()
	
	if type == sdl.events.mousewheel then
		local pressedchild = self.pressedchild
		local wheel = eventloop:wheel()

		if pressedchild ~= nil then
			local consumeEvent = pressedchild:wheel(mx, my, wheel)

			if pressedchild.dragged and pressedchild:dragWheel(mx, my, wheel) then
				consumeEvent = true
			end

			if consumeEvent then
				return true
			end
		end

		return self:wheel(mx, my, wheel)
	end

	if type == sdl.events.mousebuttondown then
		local button = eventloop:mousebutton()
		local consumeEvent = false

		self:releasePressedchild(mx, my, button)
		self:setfocus(self.hoveredchild)

		if button == 1 then
			consumeEvent = self:pressHoveredchild(mx, my, button)
		end

		-- inform open dropDownUi's of mouse down event,
		-- even if the mouse click was outside of its area,
		-- in order to allow them to close
		for _, dropdown in ipairs(self.dropdownUi.children) do
			if not dropdown.containsMouse then
				dropdown:mousedown(mx, my, button)
			end
		end

		self:cleanupDropdown()

		return consumeEvent
	end
	
	if type == sdl.events.mousebuttonup then
		local button = eventloop:mousebutton()

		if button == 1 and self.pressedchild ~= nil then
			return self:releasePressedchild(mx, my, button)
		elseif button == 3 and self.hoveredchild ~= nil then
			return self.hoveredchild:mouseup(mx, my, button)
		end

		return self:mouseup(mx, my, button)
	end
	
	if type == sdl.events.mousemotion then
		local pressedchild = self.pressedchild

		if pressedchild ~= nil then
			local consumeEvent = pressedchild:mousemove(mx, my)

			if pressedchild.dragged and pressedchild:dragMove(mx, my) then
				consumeEvent = true
			end

			if consumeEvent then
				return true
			end
		end

		return self:mousemove(mx, my)
	end

	if type == sdl.events.keydown then
		if self.focuschild then
			return self.focuschild:keydown(eventloop:keycode())
		else
			return false
		end
	end

	if type == sdl.events.keyup then
		if self.focuschild then
			return self.focuschild:keyup(eventloop:keycode())
		else
			return false
		end
	end

	return false
end

