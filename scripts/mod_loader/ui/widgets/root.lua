UiRoot = Class.inherit(Ui)

function UiRoot:new()
	Ui.new(self)
	
	self.hoveredchild = nil
	self.pressedchild = nil
	self.focuschild = self
	self.translucent = true
	self.tooltipUi = UiTooltip():addTo(self)
end

function UiRoot:draw(screen)
	self:relayout()

	-- Temporary hack until I figure out how to
	-- update tooltip frame strata without causing flickering
	if self.tooltipUi.visible then
		self.tooltipUi:bringToTop()
	end

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
		self.currentDropDown
		and x >= self.currentDropDown.screenx
		and x <  self.currentDropDown.screenx + self.currentDropDown.w
		and y >= self.currentDropDown.screeny
		and y <  self.currentDropDown.screeny + self.currentDropDown.h
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
			local done = self.currentDropDown:wheel(mx, my,eventloop:wheel())
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
		
		if self.pressedchild and self.pressedchild:mouseup(mx, my, button) then
			self.pressedchild = nil
			return true
		end

		if
			child ~= nil                  and
			mx >= child.screenx           and
			mx <  child.screenx + child.w and
			my >= child.screeny           and
			my <  child.screeny + child.h
		then
			if child:mouseup(mx, my, button) then
				self.pressedchild = nil
				child.pressed = false
				return true
			end
		end

		local res = self:mouseup(mx, my, button)
		self.pressedchild = nil
		return res
	end
	
	if type == sdl.events.mousemotion then
		if self.hoveredchild ~= nil then
			self.hoveredchild.hovered = false
		end
		self.hoveredchild = nil
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

