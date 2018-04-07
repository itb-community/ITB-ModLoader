DecoFrame = Class.inherit(UiDeco)
function DecoFrame:new(color, bordercolor)
	self.color = color or deco.colors.buttoncolor
	self.bordercolor = bordercolor or deco.colors.buttonbordercolor
	self.rect = sdl.rect(0,0,0,0)
end

function DecoFrame:draw(screen, widget)
	local r = widget.rect

	screen:drawrect(self.color, r)
	
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = 2
	self.rect.h = r.h
	screen:drawrect(self.bordercolor, self.rect)
	self.rect.x = r.x + r.w - 2
	screen:drawrect(self.bordercolor, self.rect)
	
	self.rect.x = r.x
	self.rect.y = r.y
	self.rect.w = r.w
	self.rect.h = 2
	screen:drawrect(self.bordercolor, self.rect)
	self.rect.y = r.y + r.h - 2
	screen:drawrect(self.bordercolor, self.rect)
end

function DecoFrame:apply(widget)
	widget:padding(2)
end

function DecoFrame:unapply(widget)
	widget:padding(-2)
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
	local offset = self.height/2 - self.surface:h()/2 + 2
	screen:blit(self.surface, nil, r.x + offset, r.y + offset)
end

function DecoFrameCaption:apply(widget)
	widget.padt = self.height
end

function DecoFrameCaption:unapply(widget)
	widget.padt = 0 --oops
end
