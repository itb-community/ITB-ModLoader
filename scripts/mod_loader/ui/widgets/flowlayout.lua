--[[
	A UI element which lays its children out sequentially one after another,
	either horizontally or vertically. Overflowing elements are moved to the
	next "line" -- very similar to how text commonly is laid out, for example
	in this comment.

	Useful when you have multiple elements with fixed size, but don't know how
	many of them there are ahead of time.
--]]
UiFlowLayout = Class.inherit(Ui)

function UiFlowLayout:new()
	Ui.new(self)

	self.gapHorizontal = 5
	self.gapVertical = 5
	self.horizontal = true
	self.isCompact = false
end

function UiFlowLayout:vgap(gap)
	self.gapVertical = gap
	return self
end

function UiFlowLayout:hgap(gap)
	self.gapHorizontal = gap
	return self
end

function UiFlowLayout:orientation(horizontal)
	self.horizontal = horizontal
	return self
end

function UiFlowLayout:compact(compact)
	self.isCompact = compact
	return self
end

function UiFlowLayout:relayout()
	assert(type(self.horizontal) == "boolean")

	self.innerWidth = 0
	self.innerHeight = 0

	for i = 1, #self.children do
		local child = self.children[i]

		if child.visible then
			if child.wPercent ~= nil then
				child.w = (self.w - self.padl - self.padr) * child.wPercent
			end
			if child.hPercent ~= nil then
				child.h = (self.h - self.padt - self.padb) * child.hPercent
			end
		end
	end

	local currentMaxSize = 0
	-- positions of the next child
	local nextX = 0
	local nextY = 0
	local lastChild = nil
	for i = 1, #self.children do
		local child = self.children[i]

		if child.visible then
			-- Handle wrapping
			-- Offset each row (col) by the tallest (or widest) child
			if self.horizontal then
				if nextX + child.w > self.w then
					nextX = 0
					nextY = nextY + currentMaxSize + self.gapVertical
					if self.innerHeight > 0 then
						self.innerHeight = self.innerHeight + self.gapVertical
					end
					self.innerHeight = self.innerHeight + currentMaxSize
					currentMaxSize = 0
				end
			else
				if nextY + child.h > self.h then
					nextY = 0
					nextX = nextX + currentMaxSize + self.gapHorizontal
					if self.innerWidth > 0 then
						self.innerWidth = self.innerWidth + self.gapHorizontal
					end
					self.innerWidth = self.innerWidth + currentMaxSize
					currentMaxSize = 0
				end
			end

			child.x = nextX
			child.y = nextY

			if self.horizontal then
				nextX = nextX + child.w
				currentMaxSize = math.max(currentMaxSize, child.h)

				if nextX <= self.w then
					self.innerWidth = math.max(self.innerWidth, nextX)
				end

				nextX = nextX + self.gapHorizontal
			else
				nextY = nextY + child.h
				currentMaxSize = math.max(currentMaxSize, child.w)

				if nextY <= self.h then
					self.innerHeight = math.max(self.innerHeight, nextY)
				end

				nextY = nextY + self.gapVertical
			end

			child.screenx = self.screenx + self.padl - self.dx + child.x
			child.screeny = self.screeny + self.padt - self.dy + child.y

			child:relayout()

			child.rect.x = child.screenx
			child.rect.y = child.screeny
			child.rect.w = child.w
			child.rect.h = child.h

			lastChild = child
		end
	end

	if self.horizontal then
		self.innerHeight = self.innerHeight + currentMaxSize
	else
		self.innerWidth = self.innerWidth + currentMaxSize
	end

	if lastChild then
		if self.horizontal then
			self.h = lastChild.y + self.padt + self.padb + lastChild.h
			if self.isCompact then
				self.w = self.innerWidth
			end
		else
			self.w = lastChild.x + self.padl + self.padr + lastChild.w
			if self.isCompact then
				self.h = self.innerHeight
			end
		end
	else
		self.w = self.horizontal and 0 or self.w
		self.h = self.horizontal and self.h or 0
	end
end
