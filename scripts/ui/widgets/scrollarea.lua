
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
	self.clipRect = sdl.rect(0,0,0,0)
end

function UiScrollArea:draw(screen)
	--[[local oldClip = self.root.clippingrect
	self.root.clippingrect = sdl.rect(self.screenx,self.screeny,self.w,self.h)
	screen:clip(self.root.clippingrect)]]
	screen:clip(self.clipRect)
	Ui.draw(self, screen)
	
	if self.innerHeight > self.h then
		screen:drawrect(deco.colors.black, self.scrollrect)
		drawborder(screen, deco.colors.white, self.scrollrect, 2)

		if self.scrollPressed then
			screen:drawrect(deco.colors.buttonborderhlcolor, self.scrollbuttonrect)
		else
			screen:drawrect(deco.colors.white, self.scrollbuttonrect)
		end
	end
	
	screen:unclip()
	--[[if oldClip then
		screen:clip(oldClip)
	end]]
end

function UiScrollArea:relayout()
	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollrect.y = self.screeny
	self.scrollrect.w = self.scrollwidth
	self.scrollrect.h = self.h
	
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

function UiScrollArea:mousedown(x, y)
	if x < self.scrollrect.x then return Ui.mousedown(self, x, y) end

	local ratio = (y - self.screeny - self.buttonheight/2) / (self.h-self.buttonheight)
	if ratio < 0 then ratio = 0 end
	if ratio > 1 then ratio = 1 end
	
	self.dy = ratio * (self.innerHeight - self.h)

	self.scrollPressed = true
	
	return true
end

function UiScrollArea:mouseup(x, y)
	self.scrollPressed = false

	return Ui.mouseup(self, x, y)
end

function UiScrollArea:wheel(mx,my,y)
	self:relayout()

	-- Have the scrolling speed scale with the height of the inner area,
	-- but capped by the height of the viewport.
	local d = math.max(20, self.innerHeight * 0.1)
	d = math.min(d, self.h * 0.8)
	d = d * y

	self.dy = self.dy - d
	if self.dy < 0 then self.dy = 0 end
	if self.dy + self.h > self.innerHeight then self.dy = self.innerHeight - self.h end
	if self.h > self.innerHeight then self.dy = 0 end

	return true
end

function UiScrollArea:mousemove(x, y)
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
