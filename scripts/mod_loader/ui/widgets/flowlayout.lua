--[[
	A UI element which lays its children out sequentially one after another,
	either horizontally or vertically.
--]]
UiFlowLayout = Class.inherit(Ui)

function UiFlowLayout:new()
	Ui.new(self)

	self.gapHorizontal = 5
	self.gapVertical = 5
	self.horizontal = true
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
				child.wPercent = nil
			end
			if child.hPercent ~= nil then
				child.h = (self.h - self.padt - self.padb) * child.hPercent
				child.hPercent = nil
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
				self.innerWidth = math.min(self.w, self.innerWidth + child.w + self.gapHorizontal)
			else
				nextY = nextY + child.h + self.gapVertical
				currentMaxSize = math.max(currentMaxSize, child.w)
				self.innerHeight = math.min(self.h, self.innerHeight + child.h + self.gapVertical)
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
end
