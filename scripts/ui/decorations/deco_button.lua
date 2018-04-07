DecoButton = Class.inherit(UiDeco)
function DecoButton:new(color, bordercolor, hlcolor)
	self.color = color or deco.colors.buttoncolor
	self.bordercolor = bordercolor or deco.colors.buttonbordercolor
	self.hlcolor = hlcolor or deco.colors.buttonhlcolor
	self.disabledcolor = deco.colors.buttondisabledcolor
	
	self.rect = sdl.rect(0,0,0,0)
end

function DecoButton:draw(screen, widget)
	local r = widget.rect

	screen:drawrect(self.color, r)
	
	local color = self.bordercolor
	if widget.hovered then
		color = self.hlcolor
	end
	if widget.disabled then
		color = self.disabledcolor
	end
	
	self.rect.x=r.x
	self.rect.y=r.y
	self.rect.w=1
	self.rect.h=r.h
	screen:drawrect(color, self.rect)
	self.rect.x=r.x+r.w-1
	screen:drawrect(color, self.rect)
	
	self.rect.x=r.x
	self.rect.y=r.y
	self.rect.w=r.w
	self.rect.h=1
	screen:drawrect(color, self.rect)
	self.rect.y=r.y+r.h-1
	screen:drawrect(color, self.rect)

	self.rect.x=r.x+2
	self.rect.y=r.y+2
	self.rect.w=2
	self.rect.h=r.h-4
	screen:drawrect(color, self.rect)
	self.rect.x=r.x+r.w-4
	screen:drawrect(color, self.rect)
	
	self.rect.x=r.x+2
	self.rect.y=r.y+2
	self.rect.w=r.w-4
	self.rect.h=2
	screen:drawrect(color, self.rect)
	self.rect.y=r.y+r.h-4
	screen:drawrect(color, self.rect)
	
	widget.decorationx = widget.decorationx + 8
end

function DecoButton:apply(widget)
	widget:padding(5)
end

function DecoButton:unapply(widget)
	widget:padding(-5)
end
