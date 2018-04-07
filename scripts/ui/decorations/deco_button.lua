deco.colors.mainMenuButtonColor           = sdl.rgba(7 , 10, 18, 187)
deco.colors.mainMenuButtonColorDisabled   = sdl.rgba(7 , 10, 18, 84 )
deco.colors.mainMenuButtonColorHighlight  = sdl.rgba(24, 26, 34, 255)


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


DecoMainMenuButton = Class.inherit(UiDeco)
function DecoMainMenuButton:new(colorBase, colorHighlight)
	self.colorBase = colorBase or deco.colors.mainMenuButtonColor
	self.colorHighlight = colorHighlight or deco.colors.mainMenuButtonColorHighlight
	self.colorDisabled = deco.colors.mainMenuButtonColorDisabled
	
	self.bonusX = 0
	self.bonusWidth = 0
	self.color = self.colorBase

	self.rect = sdl.rect(0, 0, 0, 0)
end

function DecoMainMenuButton:draw(screen, widget)
	if widget.disabled then
		self.color = self.colorDisabled
	end

	self.rect.x = widget.rect.x + self.bonusX
	self.rect.y = widget.rect.y
	self.rect.w = widget.rect.w + self.bonusWidth
	self.rect.h = widget.rect.h

	screen:drawrect(self.color, self.rect)
	
	widget.decorationx = widget.decorationx + 65
	widget.decorationy = widget.decorationy + 1
end
