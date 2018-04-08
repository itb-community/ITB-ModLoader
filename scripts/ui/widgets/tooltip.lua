UiTooltip = Class.inherit(UiWrappedText)

function UiTooltip:new()
	UiWrappedText.new(self)
	
	self:padding(10)
		:decorate({ DecoFrame(deco.colors.buttoncolor, deco.colors.white) })
	
	self.translucent = true
	self.limit = 28

	self.text = ""
end

function UiTooltip:draw(screen)
	self:updateText()
	if self.text == "" then return end
	
	local x = sdl.mouse.x()
	local y = sdl.mouse.y()
	if x <= screen:w() / 2 then
		self.x = x
	else
		self.x = x - self.w
	end
	
	if y <= screen:h() / 2 then
		self.y = y
	else
		self.y = y - self.h
	end
	
	self.screenx = self.x
	self.screeny = self.y
	
	UiWrappedText.draw(self, screen)
end

function UiTooltip:updateText()
	if self.text ~= self.root.tooltip then
		self.w = 0
		self:setText(self.root.tooltip)
		self.w = self:maxChildSize() + self.padl + self.padr
	end
end
