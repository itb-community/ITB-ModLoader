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
	self.draggableUi = PriorityUi():addTo(self.priorityUi)
	self.dropdownUi = PriorityUi():addTo(self.priorityUi)
end

function UiRoot:relayout()
	self.rect.x = self.screenx
	self.rect.y = self.screeny
	self.rect.w = self.w
	self.rect.h = self.h

	Ui.relayout(self)
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
	screen:clearmask()
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
	-- we permit the focus to be set to nil, ui elements with a parent,
	-- or to the root itself
	if newfocus and newfocus ~= self and newfocus.parent == nil then
		newfocus = self
	end

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

-- Hack: always call startDrag and stopDrag
-- with argument button = 1
function UiRoot:setDraggedChild(child)
	if self.draggedchild then
		self.draggedchild.dragged = false
		self.draggedchild:stopDrag(sdl.mouse.x(), sdl.mouse.y(), 1)
	end

	self.draggedchild = child

	if child then
		child.dragged = true
		child:startDrag(sdl.mouse.x(), sdl.mouse.y(), 1)
	end
end

function UiRoot:updatePressedState(mx, my)
	local draggedchild = self.draggedchild
	local pressedchild = self.pressedchild

	-- release the pressed element if it has become orphaned from root
	if pressedchild and pressedchild.root ~= self then

		if draggedchild then
			self:setDraggedChild(nil)

			-- Hack: always call stopDrag with argument button = 1
			draggedchild:stopDrag(mx, my, 1)
		end

		self:setPressedChild(nil)

		pressedchild:mouseup(mx, my, button)
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

function UiRoot:event(eventloop)
	if not self.visible then return false end
	
	local type = eventloop:type()
	local mx = sdl.mouse.x()
	local my = sdl.mouse.y()
	
	if type == sdl.events.mousewheel then
		local wheel = eventloop:wheel()
		local pressedchild = self.pressedchild
		local draggedchild = self.draggedchild
		local consumeEvent = self:wheel(mx, my, wheel)

		-- pressedchild.wheel must have already been
		-- called if this element contains the mouse.
		if pressedchild and not pressedchild.containsMouse and pressedchild:wheel(mx, my, wheel) then
			consumeEvent = true
		end

		if draggedchild and draggedchild:dragWheel(mx, my, wheel) then
			consumeEvent = true
		end

		return consumeEvent
	end

	if type == sdl.events.mousebuttondown then
		local button = eventloop:mousebutton()
		local pressedchild = self.pressedchild
		local hoveredchild = self.hoveredchild

		if hoveredchild then
			hoveredchild:setfocus()
		end

		local consumeEvent = self:mousedown(mx, my, button)

		self:setDraggedChild(nil)

		if pressedchild then
			self:setPressedChild(nil)
			pressedchild:mouseup(mx, my, button)
		end

		if button == 1 and hoveredchild then
			self:setPressedChild(hoveredchild)

			if hoveredchild.draggable then
				self:setDraggedChild(hoveredchild)
			end
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
		local pressedchild = self.pressedchild
		local consumeEvent = self:mouseup(mx, my, button)

		if button == 1 and pressedchild then
			self:setDraggedChild(nil)
			self:setPressedChild(nil)

			if pressedchild.containsMouse then
				if pressedchild:clicked(button) then
					consumeEvent = true
				end
			else
				-- pressedchild.mouseup must have already been
				-- called if this element contains the mouse.
				if pressedchild:mouseup(mx, my, button) then
					consumeEvent = true
				end
			end
		end

		return consumeEvent
	end
	
	if type == sdl.events.mousemotion then
		local pressedchild = self.pressedchild
		local draggedchild = self.draggedchild
		local consumeEvent = self:mousemove(mx, my)

		if pressedchild then
			if draggedchild and draggedchild:dragMove(mx, my) then
				consumeEvent = true
			end

			-- pressedchild.mousemove must have already been
			-- called if this element contains the mouse.
			if not pressedchild.containsMouse and pressedchild:mousemove(mx, my) then
				consumeEvent = true
			end
		end

		return consumeEvent
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

