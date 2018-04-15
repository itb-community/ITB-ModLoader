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
	self.innerHeight = 0
	self.bgcolor = nil
	self.rect = sdl.rect(0,0,0,0)
	self.decorations = {}
	self.animations = {}
	self.pressed = false
	self.hovered = false
	self.disabled = false
	self.containsMouse = false
	self.visible = true
	self.root = self
	self.parent = nil
end

function Ui:add(child)
	child:setroot(self.root)
	table.insert(self.children,child)
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

function Ui:addTo(parent)
	if parent == nil then return self end
	
	parent:add(self)
	
	return self
end

function Ui:setroot(root)
	self.root = root
	
	for i=1,#self.children do
		self.children[i]:setroot(root)
	end
	
	return self
end

function Ui:settooltip(tip)
	self.tooltip = tip
	
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

function Ui:pos(x, y)
	self.xPercent = x
	self.yPercent = y
	
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

function Ui:wheel(mx,my,y)
	for i=1,#self.children do
		local child = self.children[i]
		
		if
			child.visible                 and
			mx >= child.screenx           and
			mx <  child.screenx + child.w and
			my >= child.screeny           and
			my <  child.screeny + child.h
		then
			if child:wheel(mx,my,y) then
				return true
			end
		end
	end

	return false
end

function Ui:mousedown(mx, my)
	if not self.visible then return false end
	
	if self.root.pressedchild ~= nil then
		self.root.pressedchild.pressed = false
	end
	
	self.root.pressedchild = self
	self.pressed = true

	for i=1,#self.children do
		local child = self.children[i]

		if
			child.visible                 and
			mx >= child.screenx           and
			mx <  child.screenx + child.w and
			my >= child.screeny           and
			my <  child.screeny + child.h
		then
			if child:mousedown(mx, my) then
				return true
			end
		end
	end

	return false
end

function Ui:mouseup(mx, my)
	if not self.visible then return false end
	
	if
		self.root.pressedchild == self and
		self.pressed                   and
		not self.disabled              and
		mx >= self.screenx             and
		mx <  self.screenx + self.w    and
		my >= self.screeny             and
		my <  self.screeny + self.h
	then
		self.pressed = false
		if self:clicked() then return true end
	end

	for i=1,#self.children do
		local child = self.children[i]
		
		if
			child ~= self.root.pressedchild and
			child.visible                   and
			mx >= child.screenx             and
			mx <  child.screenx + child.w   and
			my >= child.screeny             and
			my <  child.screeny + child.h
		then
			if child:mouseup(mx, my) then
				return true
			end
		end
	end

	return false
end

function Ui:mousemove(mx, my)
	if not self.visible then return false end
	
	if self.root.hoveredchild ~= nil then
		self.root.hoveredchild.hovered = false
	end
	
	self.root.hoveredchild = self
	self.hovered = true
	
	if self.tooltip then
		self.root.tooltip = self.tooltip
	end

	for i=1,#self.children do
		local child = self.children[i]
		if
			child ~= self.root.pressedchild and
			child.visible                   and
			mx >= child.screenx             and
			mx <  child.screenx + child.w   and
			my >= child.screeny             and
			my <  child.screeny + child.h
		then
			if not child.containsMouse then
				child.containsMouse = true
				child:mouseEntered()
			end
			
			self.root.hoveredchild = child
			if child:mousemove(mx, my) then
				return true
			end
		elseif child.containsMouse then
			child.containsMouse = false
			child:mouseExited()
		end
	end
	
	if self.translucent then return false end
	return true
end

function Ui:relayout()
	local innerHeight = 0

	for i=1,#self.children do
		local child = self.children[i]
		
		if child.wPercent ~= nil then
			child.w = (self.w - self.padl - self.padr) * child.wPercent
			child.wPercent = nil
		end
		if child.hPercent ~= nil then
			child.h = (self.h - self.padt - self.padb) * child.hPercent
			child.hPercent = nil
		end
		if child.xPercent ~= nil then
			child.x = (self.w - self.padl - self.padr) * child.xPercent
			child.xPercent = nil
		end
		if child.yPercent ~= nil then
			child.y = (self.h - self.padt - self.padb) * child.yPercent
			child.yPercent = nil
		end
		
		child.screenx = self.screenx + self.padl - self.dx + child.x
		child.screeny = self.screeny + self.padt - self.dy + child.y
		
		child:relayout()
		
		local childbottom = self.padt + child.y + child.h + self.padb
		if innerHeight < childbottom then innerHeight = childbottom end
		
		child.rect.x = child.screenx
		child.rect.y = child.screeny
		child.rect.w = child.w
		child.rect.h = child.h
	end
	
	self.innerHeight = innerHeight
end

function Ui:draw(screen)
	if not self.visible then return end
	
	if self.animations then
		for _, anim in pairs(self.animations) do
			anim:update(modApi:deltaTime())
		end
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
end

function Ui:clicked()
	if self.onclicked ~= nil then
		local ret = self:onclicked()
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
end

