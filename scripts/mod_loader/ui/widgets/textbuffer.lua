EditableTextBuffer = Class.new()

function EditableTextBuffer:new(text)
	self.text = text or ""
	self.caretPosition = 0
	self.selectionMarker = nil

	self.onTextChanged = Event()
	self.onCaretPositionChanged = Event()
	self.onSelectionChanged = Event()
end

function EditableTextBuffer:insertCharacter(keycode)
	local oldText = self.text
	local oldPos = self.caretPosition

	self.text = self.text:sub(0, self.caretPosition) .. keycode .. self.text:sub(self.caretPosition + 1)
	self.caretPosition = self.caretPosition + 1

	self.onTextChanged:fire(oldText, self.text)
	self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
end

function EditableTextBuffer:moveCaretPreviousCharacter()
	local oldPos = self.caretPosition
	self.caretPosition = math.max(0, self.caretPosition - 1)
	self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
end

function EditableTextBuffer:moveCaretNextCharacter()
	local oldPos = self.caretPosition
	self.caretPosition = math.min(string.len(self.text), self.caretPosition + 1)
	self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
end

function EditableTextBuffer:moveSelectionMarkerPreviousCharacter()
	self.selectionMarker = self.selectionMarker or self.caretPosition
	local oldMarker = self.selectionMarker

	self.selectionMarker = math.max(0, self.selectionMarker - 1)
	self.onSelectionChanged:fire(oldMarker, self.selectionMarker)
end

function EditableTextBuffer:moveSelectionMarkerNextCharacter()
	self.selectionMarker = self.selectionMarker or self.caretPosition
	local oldMarker = self.selectionMarker

	self.selectionMarker = math.min(string.len(self.text), self.selectionMarker + 1)
	self.onSelectionChanged:fire(oldMarker, self.selectionMarker)
end

function EditableTextBuffer:hasSelection()
	return self.selectionMarker ~= nil
end

function EditableTextBuffer:deselect()
	self.selectionMarker = nil
end

function EditableTextBuffer:deleteSelection()
	local oldText = self.text
	local oldPos = self.caretPosition

	local selectionStart = math.min(self.caretPosition, self.selectionMarker)
	local selectionEnd = math.max(self.caretPosition, self.selectionMarker)

	-- TODO: check for off-by-one errors
	local leading = self.text:sub(0,  selectionStart)
	local trailing = self.text:sub(selectionEnd)

	self.text = leading .. trailing
	self.caretPosition = selectionStart
	self.selectionMarker = nil

	self.onTextChanged:fire(oldText, self.text)
	self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
end

function EditableTextBuffer:deletePreviousCharacter()
	if self.caretPosition == 0 then
		return
	end

	local oldText = self.text
	local oldPos = self.caretPosition

	local leading = self.text:sub(0, self.caretPosition - 1)
	local trailing = self.text:sub(self.caretPosition + 1)

	self.text = leading .. trailing
	self.caretPosition = math.max(0, self.caretPosition - 1)

	self.onTextChanged:fire(oldText, self.text)
	self.onCaretPositionChanged:fire(oldPos, self.caretPosition)
end

function EditableTextBuffer:deleteNextCharacter()
	if self.caretPosition == #self.text then
		return
	end

	local oldText = self.text

	local leading = self.text:sub( 0, self.caretPosition)
	local trailing = self.text:sub(self.caretPosition + 2)

	self.text = leading .. trailing

	self.onTextChanged:fire(oldText, self.text)
end


