UiDragDropList = Class.inherit(UiDraggable)

function UiDragDropList:new()
	UiDraggable.new(self)
end

function UiDragDropList:startDrag(mx, my, button)
	if button ~= 1 then
		return
	end

	UiDraggable.startDrag(self, mx, my, button)

	if self.dragPlaceholder ~= nil then
		local root = sdlext.getUiRoot()
		local owner = self.parent
		local index = list_indexof(owner.children, self)
		self:detach()
		self.owner = owner
		self.translucent = true

		owner:add(self.dragPlaceholder, index)
		self.dragPlaceholder:show()

		self:addTo(root.draggableUi)
		self.x = self.screenx
		self.y = self.screeny
	end
end

function UiDragDropList:stopDrag(mx, my, button)
	if button ~= 1 then
		return
	end

	if self.dragMoving and self.dragPlaceholder ~= nil then
		local index = list_indexof(self.owner.children, self.dragPlaceholder)
		self.dragPlaceholder:detach()
		self.dragPlaceholder:hide()

		self:detach()
		self:addTo(self.owner, index)
		self.translucent = self.dragPlaceholder.translucent
	end

	UiDraggable.stopDrag(self, mx, my, button)
end

function Ui:registerDragDropList(placeholder)
	Assert.True(Class.instanceOf(placeholder, Ui), "[Argument #1]:instanceOf(Ui)")
	self:registerDragMove()
	self.dragPlaceholder = placeholder
	self.startDrag = UiDragDropList.startDrag
	self.stopDrag = UiDragDropList.stopDrag
end
