DecoRAlign = Class.inherit(UiDeco)
function DecoRAlign:new(rSpace)
	UiDeco.new(self)
	self.rSpace = rSpace or 0
end

function DecoRAlign:draw(screen, widget)
	local r = widget.rect
	widget.decorationx = r.w - self.rSpace
end
