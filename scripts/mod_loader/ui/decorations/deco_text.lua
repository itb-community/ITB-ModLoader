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
	if not IsColorEqual(color, self.textset.color) then
		self.textset = deco.textset(color, self.textset.outlineColor, self.textset.outlineWidth)
		self.surface = sdl.text(self.font, self.textset, self.text)
	end
end

function DecoText:setfont(font)
	if font ~= self.textset.font then
		self.surface = sdl.text(font, self.textset, self.text)
	end
end

function DecoText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	local x = math.floor(r.x + widget.decorationx)
	local y = math.floor(r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2)

	screen:blit(self.surface, nil, x, y)
	
	widget.decorationx = widget.decorationx + self.surface:w()
end

DecoRAlignedText = Class.inherit(DecoText)
function DecoRAlignedText:new(text, font, textset, rSpace)
	DecoText.new(self, text, font, textset)
	self.rSpace = rSpace or 0
end

function DecoRAlignedText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	local x = math.floor(r.x + r.w - self.rSpace - self.surface:w())
	local y = math.floor(r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2)

	screen:blit(self.surface, nil, x, y)
	
	widget.decorationx = r.w - self.rSpace
end


DecoCAlignedText = Class.inherit(DecoText)
function DecoCAlignedText:new(text, font, textset)
	DecoText.new(self, text, font, textset)
end

function DecoCAlignedText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect

	local x = math.floor(r.x + widget.decorationx + r.w / 2 - self.surface:w() / 2)
	local y = math.floor(r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2)

	screen:blit(self.surface, nil, x, y)

	widget.decorationx = widget.decorationx + self.surface:w()
end


DecoAlignedText = Class.inherit(DecoText)
function DecoAlignedText:new(text, font, textset, alignH, alignV)
	DecoText.new(self, text, font, textset)
	
	self.alignH = alignH
	self.alignV = alignV
end

function DecoAlignedText:draw(screen, widget)
	if self.surface == nil then return end
	local r = widget.rect
	local x, y
	
	if self.alignH == nil or self.alignH == "left" then
		x = math.floor(r.x + widget.decorationx)
		
	elseif self.alignH == "center" then
		x = math.floor(r.x + widget.decorationx + r.w / 2 - self.surface:w() / 2)
		
	elseif self.alignH == "right" then
		x = math.floor(r.x - widget.decorationx + r.w - self.surface:w())
	end
	
	if self.alignV == nil or self.alignV == "top" then
		y = math.floor(r.y + widget.decorationy)
		
	elseif self.alignV == "center" then
		y = math.floor(r.y + widget.decorationy + r.h / 2 - self.surface:h() / 2)
		
	elseif self.alignV == "bottom" then
		y = math.floor(r.y - widget.decorationy + r.h - self.surface:h())
	end

	screen:blit(self.surface, nil, x, y)
	
	if self.alignH == nil or self.alignH == "left" or self.alignH == "center" then
		widget.decorationx = widget.decorationx + self.surface:w()
		
	elseif self.alignH == "right" then
		widget.decorationx = widget.decorationx - self.surface:w()
	end
end


DecoCaption = Class.inherit(DecoText)
function DecoCaption:new(font, textset, colorNormal, colorDisabled)
	DecoText.new(self, self.text, font, textset)

	self.colorNormal = colorNormal or deco.colors.white
	self.colorDisabled = colorDisabled or self.colorNormal
end

function DecoCaption:setsurface(text, color)
	local textset = nil
	if color and not IsColorEqual(color, self.textset.color) then
		textset = deco.textset(color, self.textset.outlineColor, self.textset.outlineWidth)
	end

	if text ~= self.text or textset then
		self.text = text or self.text
		self.surface = sdl.text(self.font, textset or self.textset, self.text)
	end
end

function DecoCaption:draw(screen,widget)
	local color = nil
	if widget.disabled then
		color = self.colorDisabled
	else
		color = self.colorNormal
	end

	self:setsurface(widget.captiontext, color)

	DecoText.draw(self, screen, widget)
end
