DecoRAlign = Class.inherit(UiDeco)
function DecoRAlign:new(rSpace)
	UiDeco.new(self)
	self.rSpace = rSpace or 0
end

function DecoRAlign:draw(screen, widget)
	local r = widget.rect
	widget.decorationx = r.w - self.rSpace
end


DecoCAlign = Class.inherit(UiDeco)
function DecoCAlign:new(cOffset)
	UiDeco.new(self)
	self.cOffset = cOffset or 0
end

function DecoCAlign:draw(screen, widget)
	local r = widget.rect
	widget.decorationx = r.w/2 + self.cOffset
end

DecoAlign = Class.inherit(UiDeco)
function DecoAlign:new(lSpace, tSpace)
	UiDeco.new(self)
	self.lSpace = lSpace or 0
	self.tSpace = tSpace or 0
end

function DecoAlign:draw(screen, widget)
	widget.decorationx = widget.decorationx + self.lSpace
	widget.decorationy = widget.decorationy + self.tSpace
end

DecoFixedCAlign = Class.inherit(UiDeco)
function DecoFixedCAlign:new(hSize, tOffset)
  UiDeco.new(self)
  self.cOffset = -hSize / 2
  self.tOffset = tOffset or 0
end
function DecoFixedCAlign:draw(screen, widget)
  widget.decorationx = widget.rect.w/2 + self.cOffset
  widget.decorationy = self.tOffset
end
