UiCheckbox = Class.inherit(Ui)

function UiCheckbox:new()
	Ui.new(self)
	self.checked = false
end

function UiCheckbox:clicked()
	self.checked = not self.checked
	
	return Ui.clicked(self)
end

-- //////////////////////////////////////////////////////////////////////////

UiScrollArea = Class.inherit(Ui)

function UiScrollArea:new()
	Ui.new(self)

	self.scrollcolor = sdl.rgb(64,64,64)
	self.scrollrect = sdl.rect(0,0,0,0)

	self.scrollbuttoncolor = sdl.rgb(128,128,128)
	self.scrollbuttonrect = sdl.rect(0,0,0,0)

	self.scrollwidth = 16
	self.buttonheight = 0
	
	self.padr = self.padr + self.scrollwidth
	
	self.nofity = true

	self.scrollPressed = false
end

function UiScrollArea:draw(screen)
	--[[local oldClip = self.root.clippingrect
	self.root.clippingrect = sdl.rect(self.screenx,self.screeny,self.w,self.h)
	screen:clip(self.root.clippingrect)]]
	screen:clip(sdl.rect(self.screenx,self.screeny,self.w,self.h))
	Ui.draw(self, screen)
	
	if self.innerHeight > self.h then
		screen:drawrect(self.scrollcolor,self.scrollrect)
		screen:drawrect(self.scrollbuttoncolor,self.scrollbuttonrect)
	end
	
	screen:unclip()
	--[[if oldClip then
		screen:clip(oldClip)
	end]]
end

function UiScrollArea:relayout()
	Ui.relayout(self)
	
	self.scrollrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollrect.y = self.screeny
	self.scrollrect.w = self.scrollwidth
	self.scrollrect.h = self.h
	
	local ratio = self.h / self.innerHeight
	local offset = self.dy / (self.innerHeight - self.h)
	if ratio > 1 then ratio = 1 end
	
	self.buttonheight = ratio * self.h
	self.scrollbuttonrect.x = self.screenx + self.w - self.scrollwidth
	self.scrollbuttonrect.y = self.screeny + offset * (self.h - self.buttonheight)
	self.scrollbuttonrect.w = self.scrollwidth
	self.scrollbuttonrect.h = self.buttonheight
end

function UiScrollArea:mousedown(x, y)
	if x < self.scrollrect.x then return Ui.mousedown(self, x, y) end

	local ratio = (y - self.screeny - self.buttonheight/2) / (self.h-self.buttonheight)
	if ratio < 0 then ratio = 0 end
	if ratio > 1 then ratio = 1 end
	
	self.dy = ratio * (self.innerHeight - self.h)

	self.scrollPressed = true
	
	return true
end

function UiScrollArea:mouseup(x, y)
	self.scrollPressed = false

	return Ui.mouseup(self, x, y)
end

function UiScrollArea:wheel(mx,my,y)
	self:relayout()

	self.dy = self.dy - y * 20
	if self.dy < 0 then self.dy = 0 end
	if self.dy + self.h > self.innerHeight then self.dy = self.innerHeight - self.h end
	if self.h > self.innerHeight then self.dy=0 end

	return true
end

function UiScrollArea:mousemove(x, y)
	if self.scrollPressed then
		self:relayout()

		local ratio = (y - self.screeny - self.buttonheight/2) / (self.h-self.buttonheight)
		if ratio < 0 then ratio = 0 end
		if ratio > 1 then ratio = 1 end
		
		self.dy = ratio * (self.innerHeight - self.h)

		return true
	end

	return Ui.mousemove(self, x, y)
end

-- //////////////////////////////////////////////////////////////////////////

UiDropDown = Class.inherit(Ui)

function UiDropDown:new(values,strings,value)
	Ui.new(self)

	self.tooltip = ""
	self.nofitx = true
	self.nofity = true
	self.values = values
	self.strings = strings or {}
	if value then
		for i, v in pairs(values) do
			if value == v then
				self.choice = i
				self.value = v
				break
			end
		end
	end
	if not self.choice then
		self.choice = 1
		self.value = values[1]
	end
	self.open = false
	
	self.dropcolor = sdl.rgba(128,128,128,128)
	self.droprect = sdl.rect(0,0,0,0)
end

function UiDropDown:destroyDropDown()
	self.open = false
	self.root.currentDropDown = nil
	self.root.currentDropDownOwner = nil
end

function UiDropDown:createDropDown()
	self:relayout()
	if self.root.currentDropDown then
		self.root.currentDropDownOwner:destroyDropDown()
	end
	
	self.open = true
	
	local texts = {}
	
	local max_w = 32
	for i,v in ipairs(self.values) do
		local txt = DecoRAlignedText(self.strings[i] or tostring(v))
		
		if txt.surface:w() > max_w then
			max_w = txt.surface:w()
		end
		
		local object = Ui():width(1):heightpx(40):pospx(0, (i-1) * 40):decorate({DecoSolidHoverable(sdl.rgba(40,40,40,192),sdl.rgba(60,140,150,192)),txt})
		table.insert(texts,object)
		
		object.onclicked = function()
			self.choice = i
			self.value = self.values[i]
			
			self:destroyDropDown()
		end
	end
	
	self.dropDown = UiScrollArea():pospx(self.rect.x + self.w - math.max(max_w + 8, 210) - 60, self.rect.y + 48):widthpx(math.max(max_w + 8, 210)):heightpx(math.min(#self.values * 40,210)):padding(0)
	
	for i, object in ipairs(texts) do
		self.dropDown:add(object)
	end
	
	self.root.currentDropDownOwner = self
	self.root.currentDropDown = self.dropDown
end

function UiDropDown:draw(screen)
	if self.open then
		local oldClip = self.root.clippingrect
		self.root.clippingrect = nil
		--We don't want our dropdown to be clipped
		screen:unclip()
		
		Ui.draw(self, screen)
		
		if oldClip then
			screen:clip(oldClip)
		end
	else
		Ui.draw(self, screen)
	end
end

function UiDropDown:clicked()
	if self.open then
		self:destroyDropDown()
	else
		self:createDropDown()
	end
	
	return Ui.clicked(self)
end
