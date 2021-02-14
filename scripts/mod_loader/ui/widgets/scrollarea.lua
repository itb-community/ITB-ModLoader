
UiScrollArea = Class.inherit(Ui)

function UiScrollArea:new()
	Ui.new(self)

	self.scrollrect = sdl.rect(0,0,0,0)
	self.scrollbuttonrect = sdl.rect(0,0,0,0)

	self.scrollwidth = 16
	self.buttonheight = 0
	
	self.padr = self.padr + self.scrollwidth
	self.nofity = true

	self.scrollPressed = false
	self.scrollHovered = false
	self.clipRect = sdl.rect(0,0,0,0)
end

function UiScrollArea:draw(screen)
	local clipRect = self.clipRect
	
	local currentClipRect = screen:getClipRect()
	if currentClipRect then
		clipRect = self.clipRect:getIntersect(currentClipRect)
	end
	
	screen:clip(clipRect)
	Ui.draw(self, screen)
	
	if self.innerHeight > self.h then
		screen:drawrect(deco.colors.black, self.scrollrect)
		drawborder(screen, deco.colors.white, self.scrollrect, 2)

		if self.scrollPressed then
			screen:drawrect(deco.colors.focus, self.scrollbuttonrect)
		elseif self.scrollHovered then
			screen:drawrect(deco.colors.buttonborderhl, self.scrollbuttonrect)
		else
			screen:drawrect(deco.colors.white, self.scrollbuttonrect)
		end
	end
	
	screen:unclip()
end

function UiScrollArea:relayout()
	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollrect.y = self.screeny
	self.scrollrect.w = self.scrollwidth
	self.scrollrect.h = self.h

	if self.innerHeight > self.h and self.dy + self.h > self.innerHeight then
		self.dy = self.innerHeight - self.h
	elseif self.innerHeight < self.h and self.dy > 0 then
		self.dy = 0
	end
	
	local ratio = self.h / self.innerHeight
	local offset = self.dy / (self.innerHeight - self.h)
	if ratio > 1 then ratio = 1 end
	
	self.buttonheight = ratio * self.h
	self.scrollbuttonrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollbuttonrect.y = self.screeny + offset * (self.h - self.buttonheight)
	self.scrollbuttonrect.w = self.scrollwidth
	self.scrollbuttonrect.h = self.buttonheight

	self.clipRect.x = self.screenx
	self.clipRect.y = self.screeny
	self.clipRect.w = self.w
	self.clipRect.h = self.h
end

function UiScrollArea:mousedown(x, y, button)
	if x >= self.scrollrect.x then
		if self.root.pressedchild ~= nil then
			self.root.pressedchild.pressed = false
		end

		self.root.pressedchild = self
		self.pressed = true

		if self.innerHeight > self.h then
			local ratio = (y - self.screeny - self.buttonheight/2) / (self.h - self.buttonheight)
			if ratio < 0 then ratio = 0 end
			if ratio > 1 then ratio = 1 end

			self.dy = ratio * (self.innerHeight - self.h)

			self.scrollPressed = true
			return true
		end
	end

	return Ui.mousedown(self, x, y, button)
end

function UiScrollArea:mouseup(x, y, button)
	self.scrollPressed = false

	return Ui.mouseup(self, x, y, button)
end

function UiScrollArea:computeOffset(scrollAmount)
	local startdy = self.dy

	-- Have the scrolling speed scale with the height of the inner area,
	-- but capped by the height of the viewport.
	local d = math.max(20, self.innerHeight * 0.1)
	d = math.min(d, self.h * 0.8)
	d = d * scrollAmount

	self.dy = self.dy - d
	if self.dy < 0 then self.dy = 0 end
	if self.dy + self.h > self.innerHeight then self.dy = self.innerHeight - self.h end
	if self.h > self.innerHeight then self.dy = 0 end

	return self.dy - startdy
end

function UiScrollArea:wheel(mx, my, y)
	self:relayout()

	local offset = self:computeOffset(y)

	-- Call back to mousemove to update hover and tooltip statuses of the area's
	-- child elements.
	Ui.mousemove(self, mx, my + offset)

	return Ui.wheel(self, mx, my, y)
end

function UiScrollArea:mousemove(x, y)
	self.scrollHovered = x >= self.scrollrect.x

	if self.scrollPressed then
		self:relayout()

		local ratio = (y - self.screeny - self.buttonheight/2) / (self.h-self.buttonheight)
		if ratio < 0 then ratio = 0 end
		if ratio > 1 then ratio = 1 end
		
		self.dy = ratio * (self.innerHeight - self.h)

		return true
	end

	return Ui.mousemove(self, x, y)
end

function UiScrollArea:onMouseExit()
	self.scrollHovered = false
end

UiScrollAreaH = Class.inherit(UiScrollArea)

function UiScrollAreaH:new()
	Ui.new(self)
	
	self.scrollrect = sdl.rect(0,0,0,0)
	self.scrollbuttonrect = sdl.rect(0,0,0,0)

	self.scrollheight = 16
	self.buttonwidth = 0
	
	self.padb = self.padb + self.scrollheight
	self.nofitx = true

	self.scrollPressed = false
	self.scrollHovered = false
	self.clipRect = sdl.rect(0,0,0,0)
end

function UiScrollAreaH:draw(screen)
	local clipRect = self.clipRect
	
	local currentClipRect = screen:getClipRect()
	if currentClipRect then
		clipRect = self.clipRect:getIntersect(currentClipRect)
	end
	
	screen:clip(clipRect)
	Ui.draw(self, screen)
	
	if self.innerWidth > self.w then
		screen:drawrect(deco.colors.black, self.scrollrect)
		drawborder(screen, deco.colors.white, self.scrollrect, 2)

		if self.scrollPressed then
			screen:drawrect(deco.colors.focus, self.scrollbuttonrect)
		elseif self.scrollHovered then
			screen:drawrect(deco.colors.buttonborderhl, self.scrollbuttonrect)
		else
			screen:drawrect(deco.colors.white, self.scrollbuttonrect)
		end
	end
	
	screen:unclip()
end

function UiScrollAreaH:relayout()
	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx
	self.scrollrect.y = self.screeny + self.h - self.scrollheight
	self.scrollrect.w = self.w
	self.scrollrect.h = self.scrollheight

	if self.innerWidth > self.w and self.dx + self.w > self.innerWidth then
		self.dx = self.innerWidth - self.w
	elseif self.innerWidth < self.w and self.dx > 0 then
		self.dx = 0
	end
	
	local ratio = self.w / self.innerWidth
	local offset = self.dx / (self.innerWidth - self.w)
	if ratio > 1 then ratio = 1 end
	
	self.buttonwidth = ratio * self.w
	self.scrollbuttonrect.x = self.screenx + offset * (self.w - self.buttonwidth)
	self.scrollbuttonrect.y = self.screeny + self.h - self.scrollheight
	self.scrollbuttonrect.w = self.buttonwidth
	self.scrollbuttonrect.h = self.scrollheight

	self.clipRect.x = self.screenx
	self.clipRect.y = self.screeny
	self.clipRect.w = self.w
	self.clipRect.h = self.h
end

function UiScrollAreaH:mousedown(x, y, button)
	if y >= self.scrollrect.y then
		if self.root.pressedchild ~= nil then
			self.root.pressedchild.pressed = false
		end

		self.root.pressedchild = self
		self.pressed = true

		if self.innerWidth > self.w then
			local ratio = (x - self.screenx - self.buttonwidth/2) / (self.w - self.buttonwidth)
			if ratio < 0 then ratio = 0 end
			if ratio > 1 then ratio = 1 end

			self.dx = ratio * (self.innerWidth - self.w)

			self.scrollPressed = true
			return true
		end
	end

	return Ui.mousedown(self, x, y, button)
end

function UiScrollAreaH:computeOffset(scrollAmount)
	local startdx = self.dx

	-- Have the scrolling speed scale with the width of the inner area,
	-- but capped by the width of the viewport.
	local d = math.max(20, self.innerWidth * 0.1)
	d = math.min(d, self.w * 0.8)
	d = d * scrollAmount

	self.dx = self.dx - d
	if self.dx < 0 then self.dx = 0 end
	if self.dx + self.w > self.innerWidth then self.dx = self.innerWidth - self.w end
	if self.w > self.innerWidth then self.dw = 0 end

	return self.dx - startdx
end

function UiScrollAreaH:wheel(mx, my, y)
	self:relayout()

	local offset = self:computeOffset(y)

	-- Call back to mousemove to update hover and tooltip statuses of the area's
	-- child elements.
	Ui.mousemove(self, mx + offset, my)

	return Ui.wheel(self, mx, my, y)
end

function UiScrollAreaH:mousemove(x, y)
	self.scrollHovered = y >= self.scrollrect.y

	if self.scrollPressed then
		self:relayout()

		local ratio = (x - self.screenx - self.buttonwidth/2) / (self.w-self.buttonwidth)
		if ratio < 0 then ratio = 0 end
		if ratio > 1 then ratio = 1 end
		
		self.dx = ratio * (self.innerWidth - self.w)

		return true
	end

	return Ui.mousemove(self, x, y)
end
