--[[
	A UI element which lays its children out sequentially one after another,
	either horizontally or vertically, using wPercent and hPercent as weights
	for remaining space, rather than absolute percentages.

	Cannot be laid out if it doesn't have width or height set in pixels, either
	via widthpx()/heightpx(), or call to relayout() on its parent.

	Useful when you have a mix of fixed-size and percent-size elements, and want
	the percent-size elements to take up the remainder of space left by the
	fixed-size elements.
--]]
UiWeightLayout = Class.inherit(Ui)

function UiWeightLayout:new()
	Ui.new(self)

	self.gapHorizontal = 5
	self.gapVertical = 5
	self.horizontal = true
end

function UiWeightLayout:vgap(gap)
	self.gapVertical = gap
	return self
end

function UiWeightLayout:hgap(gap)
	self.gapHorizontal = gap
	return self
end

function UiWeightLayout:orientation(horizontal)
	self.horizontal = horizontal
	return self
end

function UiWeightLayout:relayout()
	if self.wPercent or self.hPercent then
		return
	end

	assert(type(self.horizontal) == "boolean")

	local remainingSpaceW = self.w - self.padl - self.padr
	local remainingSpaceH = self.h - self.padt - self.padb
	local weightSumW = 0
	local weightSumH = 0

	local visibleChildrenCount = 0
	for i = 1, #self.children do
		local child = self.children[i]
		if child.visible then
			visibleChildrenCount = visibleChildrenCount + 1
			if self.horizontal then
				if child.wPercent == nil then
					remainingSpaceW = math.max(0, remainingSpaceW - child.w)
				else
					weightSumW = weightSumW + child.wPercent
				end
			else
				if child.hPercent == nil then
					remainingSpaceH = math.max(0, remainingSpaceH - child.h)
				else
					weightSumH = weightSumH + child.hPercent
				end
			end
		end
	end

	remainingSpaceW = remainingSpaceW - (visibleChildrenCount - 1) * self.gapHorizontal
	remainingSpaceH = remainingSpaceH - (visibleChildrenCount - 1) * self.gapVertical

	for i = 1, #self.children do
		local child = self.children[i]

		if child.visible then
			if self.horizontal then
				if child.wPercent ~= nil then
					child.w = remainingSpaceW * (child.wPercent / weightSumW)
					child.wPercent = nil
				end
				if child.hPercent ~= nil then
					child.h = (self.h - self.padt - self.padb) * child.hPercent
					child.hPercent = nil
				end
			else
				if child.wPercent ~= nil then
					child.w = (self.w - self.padl - self.padr) * child.wPercent
					child.wPercent = nil
				end
				if child.hPercent ~= nil then
					child.h = remainingSpaceH * (child.hPercent / weightSumH)
					child.hPercent = nil
				end
			end
		end
	end

	local currentMaxSize = 0
	-- positions of the next child
	local nextX = 0
	local nextY = 0
	for i = 1, #self.children do
		local child = self.children[i]

		if child.visible then
			-- Handle wrapping
			-- Offset each row (col) by the tallest (or widest) child
			if self.horizontal then
				if nextX + child.w > self.w then
					nextX = 0
					nextY = nextY + currentMaxSize + self.gapVertical
					self.innerHeight = self.innerHeight + currentMaxSize + self.gapVertical
					currentMaxSize = 0
				end
			else
				if nextY + child.h > self.h then
					nextY = 0
					nextX = nextX + currentMaxSize + self.gapHorizontal
					self.innerWidth = self.innerWidth + currentMaxSize + self.gapHorizontal
					currentMaxSize = 0
				end
			end

			child.x = nextX
			child.y = nextY

			if self.horizontal then
				nextX = nextX + child.w + self.gapHorizontal
				currentMaxSize = math.max(currentMaxSize, child.h)
			else
				nextY = nextY + child.h + self.gapVertical
				currentMaxSize = math.max(currentMaxSize, child.w)
			end

			child.screenx = self.screenx + self.padl - self.dx + child.x
			child.screeny = self.screeny + self.padt - self.dy + child.y

			child:relayout()
			
			if self.horizontal then
				self.innerWidth = math.min(self.w, self.innerWidth + child.w + self.gapHorizontal)
			else
				self.innerHeight = math.min(self.h, self.innerHeight + child.h + self.gapVertical)
			end

			child.rect.x = child.screenx
			child.rect.y = child.screeny
			child.rect.w = child.w
			child.rect.h = child.h
		end
	end

	if self.horizontal then
		self.innerHeight = self.innerHeight + currentMaxSize
	else
		self.innerWidth = self.innerWidth + currentMaxSize
	end
end
