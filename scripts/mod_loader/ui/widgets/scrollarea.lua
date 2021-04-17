
UiScrollArea = Class.inherit(Ui)

function UiScrollArea:new()
	Ui.new(self)

	self.scrollrect = sdl.rect(0,0,0,0)
	self.scrollbuttonrect = sdl.rect(0,0,0,0)

	self.scrollwidth = 16
	self.buttonheight = 0
	
	self.padr = self.padr + self.scrollwidth
	self.nofity = true
	self.dyTarget = 0
	self.scrollSpeed = 100
	self.scrollOvershoot = 0
	self.scrollChangefactor = 0.4 -- <0.0, 1.0]

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
	if self.dy ~= self.dyTarget then
		if math.abs(self.dy - self.dyTarget) > 1 then
			self.dy = self.dy * (1 - self.scrollChangefactor) + self.dyTarget * self.scrollChangefactor
		else
			self.dy = self.dyTarget
		end
	end

	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollrect.y = self.screeny
	self.scrollrect.w = self.scrollwidth
	self.scrollrect.h = self.h

	local upperlimit = math.max(0, self.innerHeight - self.h)
	if self.dy > upperlimit then
		self.dyTarget = upperlimit
	elseif self.dy < 0 then
		self.dyTarget = 0
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
		if self.innerHeight > self.h then
			local ratio = (y - self.screeny - self.buttonheight/2) / (self.h - self.buttonheight)
			if ratio < 0 then ratio = 0 end
			if ratio > 1 then ratio = 1 end

			self.dyTarget = ratio * (self.innerHeight - self.h)

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

function UiScrollArea:wheel(mx, my, y)
	if not self.scrollPressed then
		local upperlimit = math.max(0, self.innerHeight - self.h)
		self.dyTarget = math.max(-self.scrollOvershoot, math.min(upperlimit + self.scrollOvershoot, self.dyTarget - y * self.scrollSpeed))
	end

	return Ui.wheel(self, mx, my, y)
end

function UiScrollArea:mousemove(x, y)
	self.scrollHovered = x >= self.scrollrect.x

	if self.scrollPressed then
		local ratio = (y - self.screeny - self.buttonheight/2) / (self.h-self.buttonheight)
		if ratio < 0 then ratio = 0 end
		if ratio > 1 then ratio = 1 end
		
		self.dyTarget = ratio * (self.innerHeight - self.h)

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
	self.dxTarget = 0
	self.scrollSpeed = 100
	self.scrollOvershoot = 0
	self.scrollChangefactor = 0.4 -- <0.0, 1.0]

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
	if self.dx ~= self.dxTarget then
		if math.abs(self.dx - self.dxTarget) > 1 then
			self.dx = self.dx * (1 - self.scrollChangefactor) + self.dxTarget * self.scrollChangefactor
		else
			self.dx = self.dxTarget
		end
	end

	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx
	self.scrollrect.y = self.screeny + self.h - self.scrollheight
	self.scrollrect.w = self.w
	self.scrollrect.h = self.scrollheight

	local upperlimit = math.max(0, self.innerWidth - self.w)
	if self.dx > upperlimit then
		self.dxTarget = upperlimit
	elseif self.dx < 0 then
		self.dxTarget = 0
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
		if self.innerWidth > self.w then
			local ratio = (x - self.screenx - self.buttonwidth/2) / (self.w - self.buttonwidth)
			if ratio < 0 then ratio = 0 end
			if ratio > 1 then ratio = 1 end

			self.dxTarget = ratio * (self.innerWidth - self.w)

			self.scrollPressed = true
			return true
		end
	end

	return Ui.mousedown(self, x, y, button)
end

function UiScrollAreaH:wheel(mx, my, y)
	if not self.scrollPressed then
		local upperlimit = math.max(0, self.innerWidth - self.w)
		self.dxTarget = math.max(-self.scrollOvershoot, math.min(upperlimit + self.scrollOvershoot, self.dxTarget - y * self.scrollSpeed))
	end

	return Ui.wheel(self, mx, my, y)
end

function UiScrollAreaH:mousemove(x, y)
	self.scrollHovered = y >= self.scrollrect.y

	if self.scrollPressed then
		local ratio = (x - self.screenx - self.buttonwidth/2) / (self.w-self.buttonwidth)
		if ratio < 0 then ratio = 0 end
		if ratio > 1 then ratio = 1 end
		
		self.dxTarget = ratio * (self.innerWidth - self.w)

		return true
	end

	return Ui.mousemove(self, x, y)
end
