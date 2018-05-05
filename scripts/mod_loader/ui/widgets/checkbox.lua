UiCheckbox = Class.inherit(Ui)

function UiCheckbox:new()
	Ui.new(self)
	self.checked = false
end

function UiCheckbox:clicked(button)
	if button == 1 then
		self.checked = not self.checked
	end
	
	return Ui.clicked(self, button)
end
