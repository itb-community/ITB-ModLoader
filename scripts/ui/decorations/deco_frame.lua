DecoFrame = Class.inherit(UiDeco)
function DecoFrame:new(color, bordercolor, bordersize)
	self.color = color or deco.colors.buttoncolor
	self.bordercolor = bordercolor or deco.colors.buttonbordercolor
	self.bordersize = bordersize or 2
	self.rect = sdl.rect(0, 0, 0, 0)
end

function DecoFrame:draw(screen, widget)
	local r = widget.rect

	screen:drawrect(self.color, r)

	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = self.bordersize
	self.rect.h = r.h
	screen:drawrect(self.bordercolor, self.rect)
	self.rect.x = r.x + r.w - self.bordersize
	screen:drawrect(self.bordercolor, self.rect)
	
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = r.w
	self.rect.h = self.bordersize
	screen:drawrect(self.bordercolor, self.rect)
	self.rect.y = r.y + r.h - self.bordersize
	screen:drawrect(self.bordercolor, self.rect)

	widget.decorationx = widget.decorationx + self.bordersize
end

function DecoFrame:apply(widget)
	widget:padding(self.bordersize)
end

function DecoFrame:unapply(widget)
	widget:padding(-self.bordersize)
end


DecoFrameCaption = Class.inherit(DecoCaption)
function DecoFrameCaption:new(color, font, textset)
	self.color = color or deco.colors.buttonbordercolor
	self.height = 40
	self.rect = sdl.rect(0,0,0,0)
	
	DecoCaption.new(self, deco.uifont.title.font, deco.uifont.title.set)
end

function DecoFrameCaption:draw(screen, widget)
	self:setsurface(widget.captiontext)

	local r = widget.rect
	
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = r.w
	self.rect.h = self.height
	
	screen:drawrect(self.color, self.rect)
	local offset = self.height/2 - self.surface:h()/2
	screen:blit(
		self.surface,
		nil,
		r.x + widget.decorationx + offset,
		r.y + widget.decorationy + offset
	)
end

function DecoFrameCaption:apply(widget)
	widget.padt = self.height
end

function DecoFrameCaption:unapply(widget)
	widget.padt = 0 --oops
end
