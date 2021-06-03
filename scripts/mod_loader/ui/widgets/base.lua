Ui = Class.new()

function Ui:new()
  	self.children = {}
	self.captiontext = ""
	self.w = 0
	self.h = 0
	self.x = 0
	self.y = 0
	self.dx = 0
	self.dy = 0
	self.padt = 0
	self.padr = 0
	self.padb = 0
	self.padl = 0
	self.screenx = 0
	self.screeny = 0
	self.font = uifont
	self.textset = uitextset
	self.innerWidth = 0
	self.innerHeight = 0
	self.bgcolor = nil
	self.rect = sdl.rect(0,0,0,0)
	self.decorations = {}
	self.animations = {}
	self.pressed = false
	self.hovered = false
	self.disabled = false
	self.focused = false
	self.containsMouse = false
	self.ignoreMouse = false
	self.visible = true
	self.root = self
	self.parent = nil
end

function Ui:add(child, index)
	child:setroot(self.root)
	if index then
		Assert.Equals("number", type(index))
		table.insert(self.children, index, child)
	else
		table.insert(self.children, child)
	end
	child.parent = self
	
	if self.nofitx == nil then
		if self.w > 0 and child.w + child.x > self.w - self.padl - self.padr then
			child.w = self.w - self.padl - self.padr - child.x
		end
	end
	
	if self.nofity == nil then
		if self.h > 0 and child.h + child.y > self.h - self.padt - self.padb then
			child.h = self.h - self.padt - self.padb - child.y
		end
	end
	
	return self
end

function Ui:remove(child)
	if not child then return self end

	if self.root and self.root.focuschild == child then
		-- pass self as arg for UiRoot override
		self:setfocus(self)
	end

	child:setroot(nil)
	remove_element(child, self.children)
	child.parent = nil

	return self
end

function Ui:detach()
	if not self.parent then return self end

	self.parent:remove(self)

	return self
end

function Ui:addTo(parent, index)
	Assert.Equals("table", type(parent))
	
	parent:add(self, index)
	
	return self
end

function Ui:setroot(root)
	self.root = root
	
	for i=1,#self.children do
		self.children[i]:setroot(root)
	end
	
	return self
end

function Ui:settooltip(text, title, static)
	self.tooltip_static = static
	self.tooltip_title = title
	self.tooltip = text

	return self
end

function Ui:decorate(decorations)
	for i=1,#self.decorations do
		self.decorations[i]:unapply(self)
	end

	self.decorations = decorations
	
	for i=1,#self.decorations do
		self.decorations[i]:apply(self)
	end

	return self
end

function Ui:show()
	self.visible = true
	
	return self
end

function Ui:hide()
	self.visible = false
	
	return self
end

--[[
	Attempts to set root's focus to this element. Returns true if this
	element successfully obtained focus.
--]]
function Ui:setfocus()
	if not self.visible then return false end

	self.root:setfocus(self)
end

--[[
	Returns true if this element, or any of its children, have focus.
--]]
function Ui:hasfocus()
	return self.focused
end

function Ui:pos(x, y)
	self.xPercent = x
	self.yPercent = y
	
	return self
end

function Ui:posCentered(x, y)
	x = x or 0.5
	y = y or 0.5
	self.xPercent = x - self.wPercent / 2
	self.yPercent = y - self.hPercent / 2

	return self
end

function Ui:anchor(alignH, alignV)
	self:anchorH(alignH)
	self:anchorV(alignV)
	return self
end

function Ui:anchorH(alignH)
	self.alignH = alignH
	return self
end

function Ui:anchorV(alignV)
	self.alignV = alignV
	return self
end

function Ui:pospx(x, y)
	self.x = x
	self.y = y
	
	return self
end

function Ui:setxpx(x)
	self.x = x
	self.xPercent = nil
	
	return self
end

function Ui:setypx(y)
	self.y = y
	self.yPercent = nil
	
	return self
end

function Ui:caption(text)
	self.captiontext = text
	
	return self
end

function Ui:padding(v)
	self.padt = self.padt + v
	self.padr = self.padr + v
	self.padb = self.padb + v
	self.padl = self.padl + v

	return self
end

function Ui:size(w, h)
	self.wPercent = w
	self.hPercent = h
	return self
end

function Ui:width(w)
	self.wPercent = w
	return self
end

function Ui:height(h)
	self.hPercent = h
	return self
end

function Ui:widthpx(w)
	self.w = w
	return self
end

function Ui:heightpx(h)
	self.h = h
	return self
end

function Ui:crop(crop)
	self.cropped = crop ~= false
	return self
end

function Ui:clip(clip)
	self.clipped = clip ~= false
	return self
end

function Ui:setTranslucent(translucent, cascade)
	translucent = translucent ~= false
	self.translucent = translucent
	
	if cascade then
		for _, child in ipairs(self.children) do
			child:setTranslucent(translucent, cascade)
		end
	end
	
	return self
end

local function handleMouseEvent(self, mx, my, func, ...)
	for _, child in ipairs(self.children) do
		if child.visible and child.containsMouse and not child.ignoreMouse then
			if child[func](child, mx, my, ...) then
				return true
			end
		end
	end

	if self.translucent then return false end
	return true
end

function Ui:wheel(mx,my,y)
	return handleMouseEvent(self, mx, my, "wheel", y)
end

function Ui:mousedown(mx, my, button)
	return handleMouseEvent(self, mx, my, "mousedown", button)
end

function Ui:mouseup(mx, my, button)
	return handleMouseEvent(self, mx, my, "mouseup", button)
end

function Ui:mousemove(mx, my)
	return handleMouseEvent(self, mx, my, "mousemove")
end

function Ui:keydown(keycode)
	if not self.visible then return false end

	if self.parent then
		return self.parent:keydown(keycode)
	end

	return false
end

function Ui:keyup(keycode)
	if not self.visible then return false end

	if self.parent then
		return self.parent:keyup(keycode)
	end

	return false
end

-- calling this function will update containsMouse
-- for this element and its children, and call
-- mouseEntered and mouseExited when applicable.
function Ui:updateContainsMouse(mx, my)
	local curr_containsMouse
	if not self.visible or self.ignoreMouse then
		curr_containsMouse = false
	else
		curr_containsMouse = rect_contains(
			self.screenx,
			self.screeny,
			self.w,
			self.h,
			mx, my
		)
	end

	if curr_containsMouse ~= self.containsMouse then
		if curr_containsMouse then
			self:mouseEntered()
		else
			self:mouseExited()
		end

		self.containsMouse = curr_containsMouse
	end

	for _, child in ipairs(self.children) do
		child:updateContainsMouse(mx, my)
	end
end

function Ui:updateHoveredState()
	if not self.visible or self.ignoreMouse or not self.containsMouse then
		return false
	end

	if not self.translucent and self.root then
		self.root:setHoveredChild(self)
	end

	for _, child in ipairs(self.children) do
		if child:updateHoveredState() then
			return true
		end
	end

	return self.hovered
end

function Ui:updateAnimations()
	if not self.visible then
		return
	end

	if self.animations then
		for _, anim in pairs(self.animations) do
			anim:update(modApi:deltaTime())
		end
	end

	for _, child in ipairs(self.children) do
		child:updateAnimations()
	end
end

function Ui:updateTooltipState()
	self.root.tooltip_title = self.tooltip_title
	self.root.tooltip = self.tooltip
	self.root.tooltip_static = self.draggable and self.dragged
end

-- update is called for all element after everything has been
-- relayed out, and every state has been updated.
-- elements can override this function for additional updates.
function Ui:updateState()
	for _, child in ipairs(self.children) do
		child:updateState()
	end
end

function Ui:textinput(textinput)
	if not self.visible then return false end

	if self.parent then
		return self.parent:textinput(textinput)
	end

	return false
end

function Ui:relayout()
	local innerX = self.x
	local innerY = self.y
	local innerWidth = 0
	local innerHeight = 0

	for i=1,#self.children do
		local child = self.children[i]
		
		if child.wPercent ~= nil then
			child.w = (self.w - self.padl - self.padr) * child.wPercent
		end
		if child.hPercent ~= nil then
			child.h = (self.h - self.padt - self.padb) * child.hPercent
		end
		if child.xPercent ~= nil then
			child.x = (self.w - self.padl - self.padr) * child.xPercent
		end
		if child.yPercent ~= nil then
			child.y = (self.h - self.padt - self.padb) * child.yPercent
		end
		
		local childleft, childright, childtop, childbottom
		
		if child.alignH == nil or child.alignH == "left" then
			child.screenx = self.screenx + self.padl - self.dx + child.x
		elseif child.alignH == "center" then
			child.screenx = self.screenx + self.w/2 - child.w/2 - self.dx + child.x
		elseif child.alignH == "right" then
			child.screenx = self.screenx + self.w - self.padr - child.w - self.dx - child.x
		end
		
		if child.alignV == nil or child.alignV == "top" then
			child.screeny = self.screeny + self.padt - self.dy + child.y
		elseif child.alignV == "center" then
			child.screeny = self.screeny + self.h/2 - child.h/2 - self.dy + child.y
		elseif child.alignV == "bottom" then
			child.screeny = self.screeny + self.h - self.padb - child.h - self.dy - child.y
		end
		
		child:relayout()
		
		if child.alignH == nil or child.alignH == "left" then
			childright = self.padl + child.x + child.w + self.padr
		elseif child.alignH == "center" then
			childright = self.w/2 - child.w/2 + child.x + child.w + self.padr
		elseif child.alignH == "right" then
			childleft = self.w - self.padl - child.x - child.w - self.padr
		end
		
		if child.alignV == nil or child.alignV == "top" then
			childbottom = self.padt + child.y + child.h + self.padb
		elseif child.alignV == "center" then
			childbottom = self.h/2 - child.h/2 + child.y + child.h + self.padb
		elseif child.alignV == "bottom" then
			childtop = self.h - self.padt - child.y - child.h - self.padb
		end
		
		if childleft and innerX < childleft then innerX = childleft end
		if childright and innerWidth < childright then innerWidth = childright end
		if childtop and innerY < childtop then innerY = childtop end
		if childbottom and innerHeight < childbottom then innerHeight = childbottom end
		
		child.rect.x = child.screenx
		child.rect.y = child.screeny
		child.rect.w = child.w
		child.rect.h = child.h
	end
	
	self.innerWidth = innerWidth
	self.innerHeight = innerHeight
	
	if self.cropped then
	--	self.x = innerX
	--	self.y = innerY
		self.w = innerWidth
		self.h = innerHeight
	end
end

local clipRect = sdl.rect(0,0,0,0)
function Ui:draw(screen)
	if not self.visible then return end
	
	local clip = self.clipped
	
	if clip then
		clipRect.x = self.rect.x-- + self.padl
		clipRect.y = self.rect.y-- + self.padt
		clipRect.w = self.rect.w-- - self.padl - self.padr
		clipRect.h = self.rect.h-- - self.padt - self.padb
		
		local currentClipRect = screen:getClipRect()
		if currentClipRect then
			clipRect = clipRect:getIntersect(currentClipRect)
		end
		
		screen:clip(clipRect)
	end
	
	self.decorationx = 0
	self.decorationy = 0
	for i=1,#self.decorations do
		local decoration = self.decorations[i]
		decoration:draw(screen, self)
	end

	for i=#self.children,1,-1 do
		local child = self.children[i]
		child:draw(screen)
	end
	
	if clip then
		screen:unclip()
	end
end

function Ui:clicked(button)
	if self.onclicked ~= nil then
		local ret = self:onclicked(button)
		-- Make sure we bug people to update their code to return
		-- either `true` or `false`, depending on whether they actually
		-- ended up handling the click.
		if ret == nil then
			error(
				"'onclicked' function must return a value.\n"
				.."True if your function handled the click, false if it ignored it."
			)
		end
		return ret
	end

	return false
end

function Ui:mouseEntered()
	if self.onMouseEnter ~= nil then
		self:onMouseEnter()
	end
end

function Ui:mouseExited()
	for i=1,#self.children do
		local child = self.children[i]
		if child.containsMouse then
			child.containsMouse = false
			child:mouseExited()
		end
	end

	if self.onMouseExit ~= nil then
		self:onMouseExit()
	end
end

function Ui:stopDrag(mx, my, button)
end

function Ui:dragMove(mx, my)
	return false
end

function Ui:dragWheel(mx, my, y)
	return false
end

function Ui:startDrag(mx, my, button)
	self:stopDrag(mx, my, button)
end

function Ui:swapSibling(destIndex)
	if self.parent == nil then return self end
	local list = self.parent.children
	if destIndex < 1 or destIndex > #list then return self end
	local sourceIndex = list_indexof(list, self)

	local dest = list[destIndex]
	list[destIndex] = self
	list[sourceIndex] = dest

	return self
end

function Ui:bringUp()
	if self.parent == nil then return self end
	local list = self.parent.children
	local index = list_indexof(list, self)
	if index == #list then return self end

	return self:swapSibling(index + 1)
end

function Ui:bringDown()
	if self.parent == nil then return self end
	local list = self.parent.children
	local index = list_indexof(list, self)
	if index == 1 then return self end

	return self:swapSibling(index - 1)
end

function Ui:bringToTop()
	if self.parent == nil then return self end
	local list = self.parent.children
	
	for k,v in pairs(list) do
		if self == v then
			table.remove(list, k)
			break
		end
	end
	
	table.insert(list, 1, self)
	return self
end

