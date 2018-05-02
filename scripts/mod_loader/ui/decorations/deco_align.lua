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
