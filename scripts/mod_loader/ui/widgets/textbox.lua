UiTextbox = Class.inherit(UiWrappedText)

function UiTextbox:new(text, font, textset)
	UiWrappedText.new(self, text, font, textset)

	self.textBuffer = EditableTextBuffer(text)

	self.onTextChanged = self.textBuffer.onTextChanged
	self.onCaretPositionChanged = self.textBuffer.onCaretPositionChanged
	self.onSelectionChanged = self.textBuffer.onSelectionChanged

	self.onTextChanged:subscribe(function(oldText, newText)
		self.__index.setText(self, newText)
	end)
end

function UiTextbox:relayout()
	local h = self.h

	UiWrappedText.relayout(self)

	self.h = h
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
	elseif SDLKeycodes.HOME then
		self:handleHome()
		return true
	elseif SDLKeycodes.END then
		self:handleEnd()
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

function UiTextbox:hasSelection()
	return self.textBuffer:hasSelection()
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

function UiTextbox:handleHome()
	-- TODO
end

function UiTextbox:handleEnd()
	-- TODO
end
