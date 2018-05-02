DecoText = Class.inherit(DecoSurface)
function DecoText:new(text, font, textset)
	self.font = font or deco.uifont.default.font
	self.textset = textset or deco.uifont.default.set
	self.text = text or ""

	DecoSurface.new(self, sdl.text(self.font, self.textset, self.text))
end

function DecoText:setsurface(text)
	if text ~= self.text then
		self.text = text
		self.surface = sdl.text(self.font, self.textset, self.text)
	end
end

function DecoText:setcolor(color)
	if color ~= self.textset.color then
		self.textset = deco.textset(color, self.textset.outlineColor, self.textset.outlineWidth)
		self.surface = sdl.text(self.font, self.textset, self.text)
	end
end

function DecoText:setfont(font)
	if font ~= self.textset.font then
		self.surface = sdl.text(font, self.textset, self.text)
	end
end


DecoRAlignedText = Class.inherit(DecoText)
function DecoRAlignedText:new(text, font, textset, rSpace)
	DecoText.new(self, text, font, textset)
	self.rSpace = rSpace or 0
end

function DecoRAlignedText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	screen:blit(self.surface, nil, r.x + r.w - self.rSpace - self.surface:w(), r.y + widget.decorationy + r.h/2 - self.surface:h()/2)
	
	widget.decorationx = r.w - self.rSpace
end


DecoCAlignedText = Class.inherit(DecoText)
function DecoCAlignedText:new(text, font, textset)
	DecoText.new(self, text, font, textset)
end

function DecoCAlignedText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	screen:blit(
		self.surface, nil,
		r.x + widget.decorationx + r.w/2 - self.surface:w()/2,
		r.y + widget.decorationy + r.h/2 - self.surface:h()/2
	)

	widget.decorationx = widget.decorationx + self.surface:w()
end


DecoCaption = Class.inherit(DecoText)
function DecoCaption:new(font, textset)
	DecoText.new(self, self.text, font, textset)
end

function DecoCaption:draw(screen,widget)
	self:setsurface(widget.captiontext)
	
	DecoText.draw(self, screen, widget)
end
