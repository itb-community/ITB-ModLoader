UiDropDown = Class.inherit(Ui)

function UiDropDown:new(values,strings,value)
	Ui.new(self)

	self.tooltip = ""
	self.nofitx = true
	self.nofity = true
	self:updateOptions(values, strings)
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

	self.optionSelected = Event()
	
	local items = {}
	
	local max_w = 32
	for i, v in ipairs(self.values) do
		local txt = DecoRAlignedText(self.strings[i] or tostring(v))
		
		if txt.surface:w() > max_w then
			max_w = txt.surface:w()
		end
		
		local item = Ui()
			:width(1):heightpx(40)
			:decorate({
				DecoSolidHoverable(deco.colors.button, deco.colors.buttonborder),
				DecoAlign(0, 2),
				txt
			})
		table.insert(items, item)
		
		item.onclicked = function(btn, button)
			if button == 1 then
				local oldChoice = self.choice
				local oldValue = self.value

				self.choice = i
				self.value = self.values[i]

				self.optionSelected:dispatch(oldChoice, oldValue)
				self:destroyDropDown()

				return true
			end
			return false
		end
	end
	
	local function destroyDropDown()
		self:destroyDropDown()
	end
	
	local function mousedown(dropdown, mx, my, button)
		
		if
			button == 1                      and
			self.open                        and
			not self.containsMouse           and
			not dropdown.containsMouse
		then
			self:destroyDropDown()
			
		elseif button == 3 and self.open then
			self:destroyDropDown()
		end
		
		return Ui.mousedown(dropdown, mx, my, button)
	end
	
	local ddw = math.max(max_w + 8, 210)
	self.dropdown = Ui()
		:pospx(
			self.rect.x + self.w - ddw,
			self.rect.y + self.h + 2)
		:widthpx(ddw)
		:heightpx(math.min(2 + #self.values * 40, 210))
		:decorate({ DecoFrame(nil, nil, 1) })
	self.dropdown.owner = self
	self.dropdown.destroyDropDown = destroyDropDown
	self.dropdown.mousedown = mousedown
	
	local scrollarea = UiScrollArea()
		:width(1):height(1)
		:addTo(self.dropdown)

	local layout = UiBoxLayout()
		:width(1):height(1)
		:vgap(0)
		:dynamicResize(false)
		:addTo(scrollarea)
	
	for i, item in ipairs(items) do
		layout:add(item)
	end
end

function UiDropDown:updateOptions(values, strings)
	Assert.Equals("table", type(values))
	Assert.Equals({"table", "nil"}, type(strings))

	self.values = copy_table(values)
	self.strings = strings ~= nil and copy_table(strings) or {}
end

function UiDropDown:destroyDropDown()
	self.open = false
	self.dropdown.visible = false
end

function UiDropDown:createDropDown()
	if self.root then
		if self.dropdown.parent ~= self.root.dropDownUi then
			self.dropdown:detach()
		end
		
		if self.dropdown.parent == nil then
			self.dropdown:addTo(self.root.dropdownUi)
		end
		
		local max_w = 32
		local ddw = math.max(max_w + 8, 210)
		self.open = true
		self.dropdown.visible = true
		self.dropdown.x = self.rect.x + self.w - ddw
		self.dropdown.y = self.rect.y + self.h + 2
		
		self.dropdown.parent:relayout()
	end
end

function UiDropDown:mousedown(mx, my, button)
	
	if
		button == 1                      and
		self.open                        and
		not self.containsMouse           and
		not self.dropdown.containsMouse
	then
		self:destroyDropDown()
		
	elseif button == 3 and self.open then
		self:destroyDropDown()
	end
	
	return Ui.mousedown(self, mx, my, button)
end

function UiDropDown:clicked(button)
	if button == 1 then
		if self.open then
			self:destroyDropDown()
		else
			self:createDropDown()
		end
	end
	
	return Ui.clicked(self, button)
end

function UiDropDown:keydown(keycode)
	if self.focused then
		if self.open then
			if keycode == SDLKeycodes.ESCAPE then
				self:destroyDropDown()
			end

			return true
		else
			if SDLKeycodes.isEnter(keycode) then
				self:createDropDown()
				return true
			end
		end
	end

	return Ui.keydown(self, keycode)
end

function UiDropDown:keyup(keycode)
	if
		self.open and self.focused and (
			keycode == SDLKeycodes.ESCAPE  or
			SDLKeycodes.isEnter(keycode)
		)
	then
		return true
	end

	return Ui.keyup(self, keycode)
end
