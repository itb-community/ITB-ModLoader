UiTextbox = Class.inherit(Ui)

function UiTextbox:new()
	Ui.new(self)
	self.textBuffer = ""
	self.caretPosition = 0
	self.selectionMarker = nil

	self.onTextChanged = Event()
	self.onCaretPositionChanged = Event()
	self.onSelectionChanged = Event()

	self:setupEventHandlers()
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
		self.selectionMarker = self.selectionMarker or self.caretPosition

		local oldMarker = self.selectionMarker
		if keycode == SDLKeycodes.ARROW_RIGHT then
			self.selectionMarker = math.min(string.len(self.textBuffer), self.selectionMarker + 1)
			self.onSelectionChanged:fire(oldMarker, self.selectionMarker)
			return true
		elseif keycode == SDLKeycodes.ARROW_LEFT then
			self.selectionMarker = math.max(0, self.selectionMarker - 1)
			self.onSelectionChanged:fire(oldMarker, self.selectionMarker)
			return true
		end
	else
		self.selectionMarker = nil

		local oldPos = self.caretPosition
		if keycode == SDLKeycodes.ARROW_RIGHT then
			self.caretPosition = math.min(string.len(self.textBuffer), self.caretPosition + 1)
			self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
			return true
		elseif keycode == SDLKeycodes.ARROW_LEFT then
			self.caretPosition = math.max(0, self.caretPosition - 1)
			self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
			return true
		end
	end

	return false
end

function UiTextbox:handlePrintableCharacter(keycode)
	local oldText = self.textBuffer
	local oldPos = self.caretPosition

	self.textBuffer = string.insert(self.textBuffer, self.caretPosition, keycode)
	self.caretPosition = self.caretPosition + 1

	self.onTextChanged:fire(oldText, self.textBuffer)
	self.onCaretPositionChanged(oldPos, self.caretPosition)
end

function UiTextbox:hasSelection()
	return self.selectionMarker ~= nil
end

function UiTextbox:handleRemoveSelection()
	if not self:hasSelection() then
		return
	end

	local oldText = self.textBuffer
	local oldPos = self.caretPosition

	local selectionStart = math.min(self.caretPosition, self.selectionMarker)
	local selectionEnd = math.max(self.caretPosition, self.selectionMarker)

	-- TODO: check for off-by-one errors
	local leading = self.textBuffer:sub(0,  selectionStart)
	local trailing = self.textBuffer:sub(selectionEnd)

	self.textBuffer = leading .. trailing
	self.caretPosition = selectionStart
	self.selectionMarker = nil

	self.onTextChanged:fire(oldText, self.textBuffer)
	self.onCaretPositionChanged(oldPos, self.caretPosition)
end

function UiTextbox:handleBackspace()
	if self:hasSelection() then
		self:handleRemoveSelection()
		return
	end

	if self.caretPosition == 0 then
		return
	end

	local oldText = self.textBuffer
	local oldPos = self.caretPosition

	local leading = self.textBuffer:sub(0, self.caretPosition - 1)
	local trailing = self.textBuffer:sub(self.caretPosition + 1)

	self.textBuffer = leading .. trailing
	self.caretPosition = math.max(0, self.caretPosition - 1)

	self.onTextChanged:fire(oldText, self.textBuffer)
	self.onCaretPositionChanged(oldPos, self.caretPosition)
end

function UiTextbox:handleDelete()
	if self:hasSelection() then
		self:handleRemoveSelection()
		return
	end

	if self.caretPosition == #self.textBuffer then
		return
	end

	local oldText = self.textBuffer

	local leading = self.textBuffer:sub( 0, self.caretPosition)
	local trailing = self.textBuffer:sub(self.caretPosition + 2)

	self.textBuffer = leading .. trailing

	self.onTextChanged:fire(oldText, self.textBuffer)
end
