--[[
	A UI element which lays its children out sequentially one after another,
	either horizontally or vertically. Width or height of this UI element
	is adjusted dynamically to contain all of its children (along the laid
	out axis). The other axis (height when laying out horizontally, and width
	when laying out vertically) is NOT adjusted, and has to be set manually.

	Useful when you have multiple elements with fixed size, but don't know how
	many of them there are ahead of time.
--]]
UiBoxLayout = Class.inherit(Ui)

function UiBoxLayout:new()
	Ui.new(self)

	self.gapHorizontal = nil
	self.gapVertical = nil
end

function UiBoxLayout:hgap(hgap)
	self.gapHorizontal = hgap or 0
	self.gapVertical = nil
	self.nofitx = true
	self.nofity = nil
	assert(type(self.gapHorizontal) == "number")

	return self
end

function UiBoxLayout:isHBox()
	return self.gapHorizontal and not self.gapVertical
end

function UiBoxLayout:vgap(vgap)
	self.gapHorizontal = nil
	self.gapVertical = vgap or 0
	self.nofitx = nil
	self.nofity = true
	assert(type(self.gapVertical) == "number")

	return self
end

function UiBoxLayout:isVBox()
	return self.gapVertical and not self.gapHorizontal
end

function UiBoxLayout:maxChildSize(dim)
	dim = dim or (self:isVBox() and "width" or "height")
	assert(type(dim) == "string", "Not a string: "..tostring(dim))
	assert(dim == "width" or dim == "height", "Neither 'width' nor 'height': "..tostring(dim))

	local maxSize = 0

	for i = 1, #self.children do
		local child = self.children[i]
		if child.visible then
			if child.wPercent ~= nil then
				child.w = (self.w - self.padl - self.padr) * child.wPercent
				child.wPercent = nil
			end
			if child.hPercent ~= nil then
				child.h = (self.h - self.padt - self.padb) * child.hPercent
				child.hPercent = nil
			end

			local t = dim == "width" and child.w or child.h
			maxSize = math.max(maxSize, t)
		end
	end

	return maxSize
end

function UiBoxLayout:relayout()
	local lastChild = nil
	local nextOffset = 0 -- position of the next child

	for i = 1, #self.children do
		local child = self.children[i]
		if child.visible then
			if child.wPercent ~= nil then
				child.w = (self.w - self.padl - self.padr) * child.wPercent
				child.wPercent = nil
			end
			if child.hPercent ~= nil then
				child.h = (self.h - self.padt - self.padb) * child.hPercent
				child.hPercent = nil
			end

			lastChild = child
		end
	end

	for i = 1, #self.children do
		local child = self.children[i]
		if child.visible then
			if self:isHBox() then
				if not child.alignV or child.alignV == "top" then
					child.y = 0
				elseif child.alignV == "center" then
					child.y = (self.h - self.padt - self.padb - child.h)/2
				elseif child.alignV == "bottom" then
					child.y = self.h - self.padt - self.padb - child.h
				end

				child.x = nextOffset
				nextOffset = nextOffset + child.w + self.gapHorizontal
			elseif self:isVBox() then
				if not child.alignH or child.alignH == "left" then
					child.x = 0
				elseif child.alignH == "center" then
					child.x = (self.w - self.padl - self.padr - child.w)/2
				elseif child.alignH == "right" then
					child.x = self.w - self.padl - self.padr - child.w
				end

				child.y = nextOffset
				nextOffset = nextOffset + child.h + self.gapVertical
			end
			
			child.screenx = self.screenx + self.padl - self.dx + child.x
			child.screeny = self.screeny + self.padt - self.dy + child.y
			
			child:relayout()
			
			child.rect.x = child.screenx
			child.rect.y = child.screeny
			child.rect.w = child.w
			child.rect.h = child.h
		end
	end

	if lastChild then
		if self:isHBox() then
			self.w = lastChild.x + self.padl + self.padr + lastChild.w
		end
		if self:isVBox() then
			self.h = lastChild.y + self.padt + self.padb + lastChild.h
		end
	else
		self.w = self:isHBox() and 0 or self.w
		self.h = self:isVBox() and 0 or self.h
	end

	self.innerWidth = self.w
	self.innerHeight = self.h
end
