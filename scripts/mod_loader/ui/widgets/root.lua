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
	self.dropdownUi = PriorityUi():addTo(self.priorityUi)
	self.draggableUi = PriorityUi():addTo(self.priorityUi)
	self.tooltipUi = UiTooltip():addTo(self.priorityUi)
end

function UiRoot:draw(screen)
	-- priorityUi is relayed out last, but drawn first
	self.priorityUi.visible = false
	self:relayout()

	self.priorityUi.visible = true
	self.priorityUi:bringToTop()
	self:relayoutDragDropPriorityUi()

	self:updateStates()

	-- update tooltip after everything else has been updated
	self:relayoutTooltipUi()

	Ui.draw(self, screen)
end

function UiRoot:relayoutDragDropPriorityUi()
	self.tooltipUi.visible = false
	self.priorityUi:relayout()
	self.tooltipUi.visible = true
end

function UiRoot:relayoutTooltipUi()
	self.dropdownUi.visible = false
	self.draggableUi.visible = false
	self.priorityUi:relayout()
	self.dropdownUi.visible = true
	self.draggableUi.visible = true
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

function UiRoot:setHoveredChild(child)
	if self.hoveredchild then
		self.hoveredchild.hovered = false
	end

	self.hoveredchild = child

	if child then
		child.hovered = true
	end
end

function UiRoot:setPressedChild(child)
	if self.pressedchild then
		self.pressedchild.pressed = false
	end

	self.pressedchild = child

	if child then
		child.pressed = true
	end
end

function UiRoot:setDraggedChild(child)
	if self.draggedchild then
		self.draggedchild.dragged = false
	end

	self.draggedchild = child

	if child then
		child.dragged = true
	end
end

function UiRoot:updatePressedState(mx, my)
	-- release the pressed element if it has become orphaned from root
	if self.pressedchild and self.pressedchild.root ~= self then
		self:releasePressedchild(mx, my, 1)
	end
end

function UiRoot:updateHoveredState()
	-- if there is a pressed element, keep it hovered.
	self:setHoveredChild(self.pressedchild)

	if self.hoveredchild then
		return false
	end

	Ui.updateHoveredState(self)
	return false
end

function UiRoot:updateTooltipState()
	self.tooltip_static = false
	self.tooltip_title = ""
	self.tooltip = ""

	if self.hoveredchild then
		self.hoveredchild:updateTooltipState()
	end
end

function UiRoot:updateDraggedState(mx, my)
	if self.draggedchild then
		self.draggedchild:dragMove(mx, my)
	end
end

function UiRoot:updateStates()
	local mx, my = sdl.mouse.x(), sdl.mouse.y()
	self:updateContainsMouse(mx, my)
	self:updatePressedState(mx, my)
	self:updateHoveredState()
	self:updateDraggedState(mx, my)
	self:updateAnimations()
	self:updateTooltipState()
	self:updateState()
end

function UiRoot:pressHoveredchild(mx, my, button)
	local pressedchild = self.hoveredchild
	if pressedchild == nil then return end

	self:setPressedChild(pressedchild)

	if pressedchild.draggable then
		self:setDraggedChild(pressedchild)
		pressedchild:startDrag(mx, my, button)
	end

	return pressedchild:mousedown(mx, my, button)
end

function UiRoot:releasePressedchild(mx, my, button)
	local draggedchild = self.draggedchild
	local pressedchild = self.pressedchild

	if draggedchild then
		self:setDraggedChild(nil)

		-- Hack: always call stopDrag with argument button = 1
		draggedchild:stopDrag(mx, my, 1)
	end

	if pressedchild then
		self:setPressedChild(nil)

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

		if pressedchild then
			local consumeEvent = pressedchild:wheel(mx, my, wheel)

			if self.draggedchild and self.draggedchild:dragWheel(mx, my, wheel) then
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

		if not consumeEvent then
			consumeEvent = self:mousedown(mx, my, button)
		end

		self:cleanupDropdown()

		return consumeEvent
	end
	
	if type == sdl.events.mousebuttonup then
		local button = eventloop:mousebutton()

		if button == 1 and self.pressedchild then
			return self:releasePressedchild(mx, my, button)
		end

		return self:mouseup(mx, my, button)
	end
	
	if type == sdl.events.mousemotion then
		local pressedchild = self.pressedchild

		if pressedchild then
			local consumeEvent = pressedchild:mousemove(mx, my)

			if self.draggedchild and self.draggedchild:dragMove(mx, my) then
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

	if type == sdl.events.textinput then
		if self.focuschild then
			return self.focuschild:textinput(eventloop:textinput())
		else
			return false
		end
	end

	return false
end

