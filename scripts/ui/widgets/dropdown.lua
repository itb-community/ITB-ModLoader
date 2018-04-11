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
	for i, v in ipairs(self.values) do
		local txt = DecoRAlignedText(self.strings[i] or tostring(v))
		
		if txt.surface:w() > max_w then
			max_w = txt.surface:w()
		end
		
		local object = Ui()
			:width(1):heightpx(40)
			:decorate({
				DecoSolidHoverable(deco.colors.buttoncolor, deco.colors.buttonbordercolor),
				txt
			})
		table.insert(texts, object)
		
		object.onclicked = function()
			self.choice = i
			self.value = self.values[i]
			
			self:destroyDropDown()
			self.hovered = false
			return true
		end
	end
	
	local ddw = math.max(max_w + 8, 210)
	local dropDown = Ui()
		:pospx(
			self.rect.x + self.w - ddw,
			self.rect.y + self.h + 2
		)
		:widthpx(ddw)
		:heightpx(math.min(2 + #self.values * 40, 210))
		:decorate({ DecoFrame(nil, nil, 1) })

	local scrollarea = UiScrollArea()
		:width(1):height(1)
		:addTo(dropDown)

	local layout = UiBoxLayout()
		:vgap(0)
		:width(1)
		:addTo(scrollarea)
	
	for i, object in ipairs(texts) do
		layout:add(object)
	end
	
	self.root.currentDropDownOwner = self
	self.root.currentDropDown = dropDown
end

function UiDropDown:draw(screen)
	if self.open then
		-- keep the dropdown owner highlighted as long as
		-- the dropdown is open for additional clarity
		self.hovered = true

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
