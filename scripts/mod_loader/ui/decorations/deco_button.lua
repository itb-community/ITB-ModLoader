DecoButton = Class.inherit(UiDeco)
function DecoButton:new(color, bordercolor, hlcolor, borderhlcolor)
	self.color = color or deco.colors.button
	self.bordercolor = bordercolor or deco.colors.buttonborder
	self.hlcolor = hlcolor or deco.colors.buttonhl
	self.borderhlcolor = borderhlcolor or deco.colors.buttonborderhl
	self.disabledcolor = deco.colors.buttondisabled
	self.disabledbordercolor = deco.colors.buttondisabledborder
	
	self.rect = sdl.rect(0, 0, 0, 0)
end

function DecoButton:draw(screen, widget)
	local r = widget.rect

	local basecolor = self.color
	local bordercolor = self.bordercolor

	if widget.hovered then
		basecolor = self.hlcolor
		if widget.containsMouse or widget.dragMoving then
			bordercolor = self.borderhlcolor
		end
	end
	if widget.disabled then
		basecolor = self.disabledcolor
	end
	
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = r.w
	self.rect.h = r.h
	screen:drawrect(bordercolor, self.rect)

	self.rect.x = r.x + 1
	self.rect.y = r.y + 1
	self.rect.w = r.w - 2
	self.rect.h = r.h - 2
	screen:drawrect(basecolor, self.rect)
	
	if not widget.disabled then
		self.rect.x = r.x + 2
		self.rect.y = r.y + 2
		self.rect.w = r.w - 4
		self.rect.h = r.h - 4
		screen:drawrect(bordercolor, self.rect)

		self.rect.x = r.x + 4
		self.rect.y = r.y + 4
		self.rect.w = r.w - 8
		self.rect.h = r.h - 8
		screen:drawrect(basecolor, self.rect)
	end
	
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
	self.colorBase = colorBase or deco.colors.mainMenuButton
	self.colorHighlight = colorHighlight or deco.colors.mainMenuButtonHighlight
	self.colorDisabled = deco.colors.mainMenuButtonDisabled
	
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


DecoSurfaceButton = Class.inherit(UiDeco)
function DecoSurfaceButton:new(srfBase, srfHighlight, srfDisabled)
	assert(srfBase)

	self.srfBase = srfBase
	self.srfHighlight = srfHighlight or srfBase
	self.srfDisabled = srfDisabled or srfBase
end

function DecoSurfaceButton:draw(screen, widget)
	local r = widget.rect

	local surface = self.srfBase
	if widget.disabled then
		surface = self.srfDisabled
	elseif widget.hovered then
		surface = self.srfHighlight
	end

	screen:blit(
		surface,
		nil,
		r.x + widget.decorationx,
		r.y + widget.decorationy + r.h / 2 - surface:h() / 2
	)

	widget.decorationx = widget.decorationx + surface:w()
end
