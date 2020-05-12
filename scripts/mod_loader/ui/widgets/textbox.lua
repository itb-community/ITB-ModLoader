UiTextbox = Class.inherit(Ui)

function UiTextbox:new()
	Ui.new(self)
	self.textBuffer = EditableTextBuffer()
	self.caretPosition = 0
	self.selectionMarker = nil

	self.onTextChanged = self.textBuffer.onTextChanged
	self.onCaretPositionChanged = self.textBuffer.onCaretPositionChanged
	self.onSelectionChanged = self.textBuffer.onSelectionChanged
end

function UiTextbox:keydown(keycode)
	if not self.visible then
		return false
	end

	local handled = false

	if SDLKeycodes.isArrowKeyCode(keycode) then
		handled = self:handleArrows(keycode)
	elseif SDLKeycodes.isPrintableKeyCode(keycode) then
		self:handlePrintableCharacter(keycode)
		return true
	elseif SDLKeycodes.BACKSPACE then
		self:handleBackspace()
		return true
	elseif SDLKeycodes.DELETE then
		self:handleDelete()
		return true
	end

	if handled then
		return true
	end

	return Ui.keydown(self, keycode)
end

function UiTextbox:keyup(keycode)
	if not self.visible then
		return false
	end

	return Ui.keyup(self, keycode)
end

function UiTextbox:handleArrows(keycode)
	if sdlext.isShiftDown() then
		if keycode == SDLKeycodes.ARROW_RIGHT then
			self.textBuffer:moveSelectionMarkerNextCharacter()
			return true
		elseif keycode == SDLKeycodes.ARROW_LEFT then
			self.textBuffer:moveSelectionMarkerPreviousCharacter()
			return true
		end
	else
		if keycode == SDLKeycodes.ARROW_RIGHT then
			self.textBuffer:moveCaretNextCharacter()
			return true
		elseif keycode == SDLKeycodes.ARROW_LEFT then
			self.textBuffer:moveCaretPreviousCharacter()
			return true
		end
	end

	return false
end

function UiTextbox:handlePrintableCharacter(keycode)
	keycode = SDLKeycodes.normalizePrintableKeyCode(keycode)

	local character = string.char(keycode)
	self.textBuffer:insertCharacter(character)
	return true
end

function UiTextbox:handleDeleteSelection()
	if not self.textBuffer:hasSelection() then
		return
	end

	self.textBuffer:deleteSelection()
end

function UiTextbox:handleBackspace()
	if self.textBuffer:hasSelection() then
		self:handleDeleteSelection()
		return
	end

	self.textBuffer:deletePreviousCharacter()
end

function UiTextbox:handleDelete()
	if self.textBuffer:hasSelection() then
		self:handleDeleteSelection()
		return
	end

	self.textBuffer:deleteNextCharacter()
end
