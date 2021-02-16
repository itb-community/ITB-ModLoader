UiRoot = Class.inherit(Ui)

function UiRoot:new()
	Ui.new(self)
	
	self.highlightedChildren = {}
	self.hoveredchild = nil
	self.pressedchild = nil
	self.focuschild = self
	self.translucent = true
	self.priorityUi = Ui():addTo(self)
	self.tooltipUi = UiTooltip():addTo(self.priorityUi)
end

function UiRoot:draw(screen)
	-- priorityUi is relayed out last, but drawn first
	self.priorityUi.visible = false
	self:relayout()

	self.priorityUi.visible = true
	self.priorityUi:bringToTop()
	self.priorityUi:relayout()

	Ui.draw(self, screen)
	
	if self.currentDropDown then
		self:add(self.currentDropDown)
		self:relayout()
		self.currentDropDown:draw(screen)
		table.remove(self.children)
	end
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

function UiRoot:dropdownEvent(x,y)
	if
		self.currentDropDown and
		rect_contains(
			self.currentDropDown.screenx,
			self.currentDropDown.screeny,
			self.currentDropDown.w,
			self.currentDropDown.h,
			x, y
		)
	then
		self:add(self.currentDropDown)
		self:relayout()
		return true
	end

	return false
end

function UiRoot:event(eventloop)
	if not self.visible then return false end
	
	local type = eventloop:type()
	local mx = sdl.mouse.x()
	local my = sdl.mouse.y()
	
	if type == sdl.events.mousewheel then
		if self:dropdownEvent(mx, my) then
			local done = self.currentDropDown:wheel(mx, my, eventloop:wheel())
			table.remove(self.children)
			if done then
				return done
			end
		end

		return self:wheel(mx, my, eventloop:wheel())
	end

	if type == sdl.events.mousebuttondown then
		local button = eventloop:mousebutton()
		self:setfocus(nil)
		local done = self:mousedown(mx, my, button)
		if self:dropdownEvent(mx, my) then
			done = self.currentDropDown:mousedown(mx, my, button) or done
			table.remove(self.children)
		end
		return done
	end
	
	if type == sdl.events.mousebuttonup then
		local button = eventloop:mousebutton()
		local child = self.pressedchild

		local dEvent = self:dropdownEvent(mx, my)
		if
			self.currentDropDown and self.currentDropDownOwner ~= child and
			not dEvent
		then
			-- destroy the dropdown if we click somewhere away from it
			self.currentDropDownOwner.hovered = false
			self.currentDropDownOwner:destroyDropDown()
		end
		if dEvent then table.remove(self.children) end
		
		-- Notify pressed children of the event, even if the mouse is released
		-- outside of them.
		if self.pressedchild and self.pressedchild:mouseup(mx, my, button) then
			self.pressedchild.pressed = false
			self.pressedchild = nil
			return true
		end

		local res = self:mouseup(mx, my, button)
		self.pressedchild = nil
		return res
	end
	
	if type == sdl.events.mousemotion then
		for i = #self.highlightedChildren, 1, -1 do
			self.highlightedChildren[i].highlighted = false
			table.remove(self.highlightedChildren, i)
		end
		if self.hoveredchild ~= nil then
			self.hoveredchild.hovered = false
		end
		self.hoveredchild = nil
		self.tooltip_static = false
		self.tooltip_title = false
		self.tooltip = ""

		if self.pressedchild ~= nil then
			return self.pressedchild:mousemove(mx, my)
		end
		
		if self:dropdownEvent(mx,my) then
			local handled = self.currentDropDown:mousemove(mx, my)
			table.remove(self.children)
			return handled
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

