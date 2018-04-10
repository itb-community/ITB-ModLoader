UiRoot = Class.inherit(Ui)

function UiRoot:new()
	Ui.new(self)
	
	self.hoveredchild = nil
	self.pressedchild = nil
	self.translucent = true
	self.tooltipUi = UiTooltip():addTo(self)
end

function UiRoot:draw(screen)
	self:relayout()

	Ui.draw(self, screen)
	
	if self.currentDropDown then
		self:add(self.currentDropDown)
		self:relayout()
		self.currentDropDown:draw(screen)
		table.remove(self.children)
	end
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
		if self:dropdownEvent(mx,my) then
			local done = self.currentDropDown:wheel(mx, my,eventloop:wheel())
			table.remove(self.children)
			if done then
				return done
			end
		end
		return self:wheel(mx,my,eventloop:wheel())
	end

	if type == sdl.events.mousebuttondown then
		local done = self:mousedown(mx, my)
		if self:dropdownEvent(mx,my) then
			done = self.currentDropDown:mousedown(mx, my) or done
			table.remove(self.children)
		end
		return done
	end
	
	if type == sdl.events.mousebuttonup then
		local child = self.pressedchild
		if child ~= nil and mx>=child.screenx and mx<child.screenx+child.w and my>=child.screeny and my<child.screeny+child.h then
			if child:mouseup(mx, my) then
				self.pressedchild = nil
				child.pressed = false
				return true
			end
		end
		
		local res = self:mouseup(mx, my)
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
			if self.pressedchild:mousemove(mx, my) then
				return false
			end
		end
		
		if self:dropdownEvent(mx,my) then
			self.currentDropDown:mousemove(mx, my)
			table.remove(self.children)
			return false
		end
		
		self:mousemove(mx, my)
		return false
	end

	return false
end

