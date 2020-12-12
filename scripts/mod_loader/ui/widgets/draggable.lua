UiDraggable = Class.inherit(Ui)

function UiDraggable:new()
	Ui.new(self)

	self.draggable = true
	self.dragMovable = true
	self.dragResizable = true
	self.__resizeHandle = 7
	self.__minSize = 50
end

function UiDraggable:isEdge(mx, my)
	local resizeHandle = self.__resizeHandle
	return mx < self.screenx + resizeHandle          or
	       my < self.screeny + resizeHandle          or
	       mx > self.screenx + self.w - resizeHandle or
	       my > self.screeny + self.h - resizeHandle
end

local RESIZE_DIR_TOPLEFT  = 0
local RESIZE_DIR_TOP      = 1
local RESIZE_DIR_TOPRIGHT = 2
local RESIZE_DIR_RIGHT    = 3
local RESIZE_DIR_BOTRIGHT = 4
local RESIZE_DIR_BOT      = 5
local RESIZE_DIR_BOTLEFT  = 6
local RESIZE_DIR_LEFT     = 7
local function getResizeDirection(self, mx, my)
	local ox = mx - self.screenx
	local oy = my - self.screeny
	local resizeHandle = self.__resizeHandle
	-- use double the resize handle size to make corners easier to click
	local rh2 = resizeHandle * 2

	if     ox < rh2          and oy < rh2          then
		return RESIZE_DIR_TOPLEFT
	elseif ox > self.w - rh2 and oy < rh2          then
		return RESIZE_DIR_TOPRIGHT
	elseif ox > self.w - rh2 and oy > self.h - rh2 then
		return RESIZE_DIR_BOTRIGHT
	elseif ox < rh2          and oy > self.h - rh2 then
		return RESIZE_DIR_BOTLEFT
	elseif oy < resizeHandle          then
		return RESIZE_DIR_TOP
	elseif oy > self.h - resizeHandle then
		return RESIZE_DIR_BOT
	elseif ox < resizeHandle          then
		return RESIZE_DIR_LEFT
	elseif ox > self.w - resizeHandle then
		return RESIZE_DIR_RIGHT
	end

	return nil
end

function UiDraggable:startDrag(mx, my, button)
	self.__index.startDrag(self, mx, my, button)

	if button ~= 1 then
		return
	end

	self.dragX = mx
	self.dragY = my

	if self.dragMovable then
		self.dragMoving = true
	end
	if self.dragResizable then
		self.startX = self.screenx
		self.startY = self.screeny
		self.dragW = self.w
		self.dragH = self.h
		self.dragResizing = UiDraggable.isEdge(self, mx, my, self.__resizeHandle)
		self.__resizeDir = getResizeDirection(self, mx, my, self.__resizeHandle)
	end

	if self.parent then
		self.parent:relayout()
	end
end

function UiDraggable:stopDrag(mx, my, button)
	self.__index.stopDrag(self, mx, my, button)

	if button ~= 1 then
		return
	end

	self.dragMoving   = false
	self.dragResizing = false
	
	if self.dropTargets then
		local target = self.hoverTarget
		if target then
			if target.onDragTargetStop then
				target:onDragTargetStop(self)
			end
			
			if target.onDragTargetDrop then
				target:onDragTargetDrop(self)
			end
			
			target.hovered = false
			self.hoverTarget = nil
		end
	end
end

function UiDraggable:dragMove(mx, my)
	if self.dragResizable and self.dragResizing then
		local minsize = self.__minSize or 50
		if
			self.__resizeDir == RESIZE_DIR_TOPLEFT or
			self.__resizeDir == RESIZE_DIR_BOTLEFT or
			self.__resizeDir == RESIZE_DIR_LEFT
		then
			mx = math.min(mx, self.dragX + self.dragW - minsize)
			self.x = self.startX + (mx - self.dragX)
			self.w = math.max(self.dragW - (mx - self.dragX), minsize)
		end

		if
			self.__resizeDir == RESIZE_DIR_TOPLEFT  or
			self.__resizeDir == RESIZE_DIR_TOP      or
			self.__resizeDir == RESIZE_DIR_TOPRIGHT
		then
			my = math.min(my, self.dragY + self.dragH - minsize)
			self.y = self.startY + (my - self.dragY)
			self.h = math.max(self.dragH - (my - self.dragY), minsize)
		end

		if
			self.__resizeDir == RESIZE_DIR_TOPRIGHT or
			self.__resizeDir == RESIZE_DIR_RIGHT    or
			self.__resizeDir == RESIZE_DIR_BOTRIGHT
		then
			self.w = math.max(self.dragW + mx - self.dragX, minsize)
		end
		if
			self.__resizeDir == RESIZE_DIR_BOTRIGHT or
			self.__resizeDir == RESIZE_DIR_BOT      or
			self.__resizeDir == RESIZE_DIR_BOTLEFT
		then
			self.h = math.max(self.dragH + my - self.dragY, minsize)
		end
	elseif self.dragMovable and self.dragMoving then
		self.x = self.x + mx - self.dragX
		self.y = self.y + my - self.dragY
		self.dragX = mx
		self.dragY = my
		
		if self.dropTargets then
			local first = 1
			local target = self.hoverTarget
			
			if target then
				if not rect_contains(target.rect, mx, my) then
					self.hoverTarget = nil
					target.hovered = false
					
					if target.onDragTargetStop then
						target:onDragTargetStop(self)
					end
				end
				first = 2
			end
			
			for i = first, #self.dropTargets do
				local target = self.dropTargets[i]
				if rect_contains(target.rect, mx, my) then
					self.hoverTarget = target
					target.hovered = true
					
					if target.onDragTargetStart then
						target:onDragTargetStart(self)
					end
					
					-- swap to front, to save iterations later
					self.dropTargets[1], self.dropTargets[i] = self.dropTargets[i], self.dropTargets[1]
					
					break
				end
			end
		end
	else
		self.__index.dragMove(self, mx, my)
	end
end

function UiDraggable:mousemove(mx, my)
	local result = self.__index.mousemove(self, mx, my)

	self.canDragResize = self.dragResizable and
		UiDraggable.isEdge(self, mx, my, self.__resizeHandle)

	return result
end

function UiDraggable:mouseExited()
	self.__index.mouseExited(self)

	self.canDragResize = false
end

-- //////////////////////////////////////////////////////////////////////////////////

local function registerDragFunctions(self)
	self.startDrag   = UiDraggable.startDrag
	self.stopDrag    = UiDraggable.stopDrag
	self.dragMove    = UiDraggable.dragMove
	self.mousemove   = UiDraggable.mousemove
	self.mouseExited = UiDraggable.mouseExited
end

function Ui:registerDragMove()
	registerDragFunctions(self)
	self.draggable   = true
	self.dragMovable = true
end

function Ui:registerDragResize(resizeHandleSize, minSize)
	registerDragFunctions(self)
	self.draggable     = true
	self.dragResizable = true
	self.__resizeHandle = resizeHandleSize or self.__resizeHandle
	self.__minSize = minSize or self.__minSize
end

function Ui:registerDropTarget(target)
	self.dropTargets = self.dropTargets or {}
	table.insert(self.dropTargets, target)
end
