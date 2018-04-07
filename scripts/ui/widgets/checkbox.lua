UiCheckbox = Class.inherit(Ui)

function UiCheckbox:new()
	Ui.new(self)
	self.checked = false
end

function UiCheckbox:clicked()
	self.checked = not self.checked
	
	return Ui.clicked(self)
end
