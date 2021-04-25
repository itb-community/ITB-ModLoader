DecoFrame = Class.inherit(UiDeco)
function DecoFrame:new(color, bordercolor, bordersize)
	self.color = color or deco.colors.framebg
	self.bordercolor = bordercolor or deco.colors.buttonborder
	self.bordersize = bordersize or 2
	self.rect = sdl.rect(0, 0, 0, 0)
end

function DecoFrame:draw(screen, widget)
	local r = widget.rect

	self.rect.x = r.x
	self.rect.y = r.y + widget.decorationy
	self.rect.w = r.w
	self.rect.h = r.h - widget.decorationy

	screen:drawrect(self.color, self.rect)

	local c = self.bordercolor
	if widget.dragResizing then
		c = deco.colors.focus
	elseif widget.canDragResize then
		c = deco.colors.buttonborderhl
	end

	drawborder(screen, c, self.rect, self.bordersize)

	widget.decorationx = widget.decorationx + self.bordersize
	widget.decorationy = widget.decorationy + self.bordersize
end

function DecoFrame:apply(widget)
	widget:padding(self.bordersize)
end

function DecoFrame:unapply(widget)
	widget:padding(-self.bordersize)
end


DecoFrameHeader = Class.inherit(DecoCaption)
function DecoFrameHeader:new(bordercolor, fillcolor, bordersize, font, textset)
	self.bordercolor = bordercolor or deco.colors.buttonborder
	self.fillcolor = fillcolor or deco.colors.buttonhl
	self.bordersize = bordersize or 2

	self.height = 50
	self.triSize = 26
	self.triInset = 10
	self.rect = sdl.rect(0,0,0,0)

	DecoCaption.new(self, deco.uifont.title.font, deco.uifont.title.set)
end

function DecoFrameHeader:draw(screen, widget)
	self:setsurface(widget.captiontext)

	local r = widget.rect

	self.rect.x = r.x
	self.rect.y = r.y + self.triInset
	self.rect.w = r.w
	self.rect.h = self.height - self.triInset

	screen:drawrect(self.fillcolor, self.rect)
	drawborder(screen, self.bordercolor, self.rect, self.bordersize)

	self.rect.y = r.y
	self.rect.w = self.surface:w()
	self.rect.h = self.height
	screen:drawrect(self.bordercolor, self.rect)

	self.rect.x = r.x + self.rect.w
	self.rect.y = r.y
	self.rect.w = self.triSize
	self.rect.h = self.triSize
	drawtri_bl(screen, self.bordercolor, self.rect)

	self.rect.y = r.y + self.rect.h
	self.rect.h = self.height - self.rect.h
	screen:drawrect(self.bordercolor, self.rect)

	local offset = self.height / 2 - self.surface:h() / 2

	screen:blit(
		self.surface,
		nil,
		r.x + widget.decorationx + offset + 1,
		r.y + widget.decorationy + offset + 2
	)

	widget.decorationy = self.height - self.bordersize
end

function DecoFrameHeader:apply(widget)
	widget.padt = widget.padt + (self.height - self.bordersize)
end

function DecoFrameHeader:unapply(widget)
	widget.padt = widget.padt - (self.height - self.bordersize)
end

DecoBorder = Class.inherit(UiDeco)
function DecoBorder:new(bordercolor, bordersize, borderhlcolor, borderhlsize)
    self.bordercolor = bordercolor or deco.colors.buttonborder
    self.borderhlcolor = borderhlcolor or self.bordercolor
    self.bordersize = bordersize or 2
    self.borderhlsize = borderhlsize or self.bordersize
    self.rect =  sdl.rect(0, 0, 0, 0)
end

function DecoBorder:draw(screen, widget)
    local r = widget.rect
	
    self.rect.x = r.x
    self.rect.y = r.y
    self.rect.w = r.w
    self.rect.h = r.h
	
    local color = self.bordercolor
	local bordersize = self.bordersize
    if widget.hovered then
        color = self.borderhlcolor
        bordersize = self.borderhlsize
    end
	
    drawborder(screen, color, self.rect, bordersize)
end

function DecoBorder:apply(widget)
    widget:padding(self.bordersize)
end

function DecoBorder:unapply(widget)
    widget:padding(-self.bordersize)
end
