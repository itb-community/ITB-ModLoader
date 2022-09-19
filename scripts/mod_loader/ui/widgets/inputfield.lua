-- TODO: remove characters not in 'alphabet', also when pasting text

--[[
	A UI element with a simple purpose. Whenever this element is focused
	(and the console is closed), all keyboard input is overridden and fed
	into its 'textfield' object. The entered text can for example be displayed
	by decorating it with DecoInputField.
	An alternate way of using the class is to register any arbitrary Ui object,
	populating it with all relevant functions.

	UiInputField.registerAsInputField(arbitraryUiObject)
--]]

local newtext = {}
UiInputField = Class.inherit(Ui)
UiInputField._ALPHABET_UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
UiInputField._ALPHABET_LOWER = "abcdefghjiklmnopqrstuvwxyz"
UiInputField._ALPHABET_NUMBERS = "1234567890"
UiInputField._ALPHABET_SYMBOLS = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ "
UiInputField._ALPHABET_CHARS = UiInputField._ALPHABET_UPPER..UiInputField._ALPHABET_LOWER

function UiInputField:new()
	Ui.new(self)
	self:init()
end

function UiInputField:init()
	self._debugName = "UiInputField"
	self.textfield = ""
	self.editable = true
	self.selection = nil
	self.caret = 0
	self.focused_prev = false

	self.onMousePressEvent = Event()
	self.onMouseMoveEvent = Event()
	self.onTextAddedEvent = Event()
	self.onTextRemovedEvent = Event()
	self.onCaretMovedEvent = Event()
	self.onFocusChangedEvent = Event()
end

function UiInputField:setText(text)
	self.textfield = text
	self.selection = nil
	self:setCaret(self.caret)
	return self
end

function UiInputField:setMaxLength(maxLength)
	self.maxLength = maxLength
	return self
end

function UiInputField:setAlphabet(alphabet)
	self.alphabet = alphabet
	return self
end

function UiInputField:setCaret(newcaret)
	local oldcaret = self.caret
	local size = self.textfield:len()
	local selection = self.selection

	if newcaret < 0 then
		newcaret = 0
	elseif newcaret > size then
		newcaret = size
	end

	self.caret = newcaret
	self.onCaretMovedEvent:dispatch(newcaret, oldcaret)
end

function UiInputField:moveCaret(delta)
	self:setCaret(self.caret + delta)
end

function UiInputField:getCaret()
	return self.caret
end

function UiInputField:tryStartSelection()
	if sdlext.isShiftDown() then
		if self.selection == nil then
			self.selection = self.caret
		end
	else
		self.selection = nil
	end
end

function UiInputField:deleteSelection()
	if not self.editable or self.selection == nil then return end
	local from, to = self:getSelection()

	self:setCaret(from)
	self:delete(to - from)
	self.selection = nil
end

function UiInputField:getSelection()
	if self.selection == nil then return 0,0 end
	local from = self.selection
	local to = self.caret

	if from < to then
		return from, to
	else
		return to, from
	end
end

function UiInputField:copy()
	local from, to = self:getSelection()
	local text = self.textfield:sub(from + 1, to)
	if type(text) == 'string' then
		sdl.clipboard.set(text)
	end
end

function UiInputField:paste()
	if not self.editable then return end
	local text = sdl.clipboard.get()
	if type(text) == 'string' then
		self:addText(text)
	end
end

function UiInputField:addText(input)
	if not self.editable then return end

	local textfield = self.textfield
	local textlength = textfield:len()
	local inputlength = input:len()
	local caret = self.caret
	local maxlength = self.maxLength

	if maxlength then
		local remainingLength = maxlength - textlength
		if inputlength > remainingLength then
			input = input:sub(0, remainingLength)
			inputlength = input:len()
		end
	end

	newtext[1] = textfield:sub(0, caret)
	newtext[2] = input
	newtext[3] = textfield:sub(caret + 1, textlength)

	self.textfield = table.concat(newtext)
	self.caret = caret + inputlength
	self.onTextAddedEvent:dispatch(caret, input)
end

function UiInputField:delete(length)
	if not self.editable then return end
	local textfield = self.textfield
	local textlength = textfield:len()
	local caret = self.caret
	local selection = self.selection

	if length > textlength - caret then
		length = textlength - caret
	end

	if selection and selection > caret then
		if selection - length < caret then
			self.selection = nil
		else
			self.selection = selection - length
		end
	end

	newtext[1] = textfield:sub(0, caret)
	newtext[2] = ""
	newtext[3] = textfield:sub(caret + length + 1, -1)

	self.textfield = table.concat(newtext)
	self.onTextRemovedEvent:dispatch(caret, length)
end

function UiInputField:backspace(length)
	if not self.editable then return end
	local textfield = self.textfield
	local textlength = textfield:len()
	local caret = self.caret
	local selection = self.selection

	if length > caret then
		length = caret
	end

	if selection then
		if selection > caret then
			self.selection = selection - length
		elseif selection < caret then
			if selection + length > caret then
				self.selection = nil
			end
		end
	end

	newtext[1] = textfield:sub(0, caret - length)
	newtext[2] = ""
	newtext[3] = textfield:sub(caret + 1, -1)

	self.textfield = table.concat(newtext)
	self.caret = caret - length

	self.onTextRemovedEvent:dispatch(caret - length, length)
end

function UiInputField:newline()
	if not self.editable then return end
	local textfield = self.textfield
	local caret = self.caret

	self:addText("\n")
end

regex_list = {
	"%p+%s*",      -- punctuation + spaces
	"[^%p%s]*%s*", -- non-punctuation + spaces
}

function getFirstWordIndices(text)
	local out1, out2

	for _, regex in ipairs(regex_list) do
		out1, out2 = text:find("^"..regex)

		if out1 and out2 then
			return out1 - 1, out2
		end
	end

	return 0, text:len()
end

function getLastWordIndices(text)
	local out1, out2

	for _, regex in ipairs(regex_list) do
		out1, out2 = text:find(regex.."$")

		if out1 and out2 then
			return out1 - 1, out2
		end
	end

	return 0, text:len()
end

function UiInputField:onSelectAll()
	self:setCaret(0)
	self.selection = self.textfield:len()
end

function UiInputField:onCopy()
	self:copy()
end

function UiInputField:onCut()
	self:copy()
	self:deleteSelection()
end

function UiInputField:onPaste()
	self:deleteSelection()
	self:paste()
end

function UiInputField:onInput(text)
	self:deleteSelection()
	self:addText(text)
end

function UiInputField:onEnter()
	self.root:setfocus(nil)
end

function UiInputField:onDelete()
	if sdlext.isCtrlDown() then
		local trail = self.textfield:sub(self.caret + 1, -1)
		local from, to = getFirstWordIndices(trail)
		self:delete(to - from)
	elseif self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	else
		self:delete(1)
	end
end

function UiInputField:onBackspace()
	if sdlext.isCtrlDown() then
		local lead = self.textfield:sub(0, self.caret)
		local from, to = getLastWordIndices(lead)
		self:backspace(to - from)
	elseif self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	else
		self:backspace(1)
	end
end

function UiInputField:onArrowRight()
	self:tryStartSelection()

	if sdlext.isCtrlDown() then
		local trail = self.textfield:sub(self.caret + 1, -1)
		local from, to = getFirstWordIndices(trail)
		self:moveCaret(to - from)
	else
		self:moveCaret(1)
	end
end

function UiInputField:onArrowLeft()
	self:tryStartSelection()

	if sdlext.isCtrlDown() then
		local lead = self.textfield:sub(0, self.caret)
		local from, to = getLastWordIndices(lead)
		self:moveCaret(from - to)
	else
		self:moveCaret(-1)
	end
end

function UiInputField:onArrowUp()
	self:onArrowLeft()
end

function UiInputField:onArrowDown()
	self:onArrowRight()
end

function UiInputField:onHome()
	self:tryStartSelection()
	self:setCaret(0)
end

function UiInputField:onEnd()
	self:tryStartSelection()
	self:setCaret(self.textfield:len())
end

local eventkeyHandler = {
	[SDLKeycodes.BACKSPACE] = "onBackspace",
	[SDLKeycodes.DELETE] = "onDelete",
	[SDLKeycodes.ARROW_RIGHT] = "onArrowRight",
	[SDLKeycodes.ARROW_LEFT] = "onArrowLeft",
	[SDLKeycodes.ARROW_UP] = "onArrowUp",
	[SDLKeycodes.ARROW_DOWN] = "onArrowDown",
	[SDLKeycodes.RETURN] = "onEnter",
	[SDLKeycodes.RETURN2] = "onEnter",
	[SDLKeycodes.KP_ENTER] = "onEnter",
	[SDLKeycodes.HOME] = "onHome",
	[SDLKeycodes.END] = "onEnd",
}

local eventkeyHandler_ctrl = {
	[SDLKeycodes.a] = "onSelectAll",
	[SDLKeycodes.x] = "onCut",
	[SDLKeycodes.c] = "onCopy",
	[SDLKeycodes.v] = "onPaste"
}

function UiInputField:relayout()
	local focused = self.focused
	local focused_prev = self.focused_prev

	if focused ~= focused_prev then

		if not focused then
			self.selection = nil
		end

		self.focused_prev = focused
		self.onFocusChangedEvent:dispatch(self, focused, focused_prev)
	end
end

function UiInputField:mousedown(mx, my, button)
	if button == 1 then
		self.onMousePressEvent:dispatch(self, mx, my, button)
	end
end

function UiInputField:mousemove(mx, my)
	if self.pressed then
		self.onMouseMoveEvent:dispatch(self, mx, my)
	end
end

function UiInputField:keydown(keycode)
	if sdlext.isConsoleOpen() then return false end
	local eventKeyHandler

	eventKeyHandler = eventkeyHandler[keycode]

	if not eventKeyHandler and sdlext.isCtrlDown() then
		eventKeyHandler = eventkeyHandler_ctrl[keycode]
	end

	if eventKeyHandler then
		self[eventKeyHandler](self)
	end

	-- disable keyboard while the input field is active
	return true
end

function UiInputField:textinput(textinput)
	if sdlext.isConsoleOpen() then return false end

	if not self.alphabet or self.alphabet:find(textinput) then
		self:onInput(textinput)
	end

	return true
end

function UiInputField:registerAsInputField()
	UiInputField.init(self)
	self.setMaxLength      = UiInputField.setMaxLength
	self.setAlphabet       = UiInputField.setAlphabet
	self.setCaret          = UiInputField.setCaret
	self.moveCaret         = UiInputField.moveCaret
	self.tryStartSelection = UiInputField.tryStartSelection
	self.deleteSelection   = UiInputField.deleteSelection
	self.getSelection      = UiInputField.getSelection
	self.copy              = UiInputField.copy
	self.paste             = UiInputField.paste
	self.addText           = UiInputField.addText
	self.delete            = UiInputField.delete
	self.backspace         = UiInputField.backspace
	self.newline           = UiInputField.newline
	self.mousedown         = UiInputField.mousedown
	self.mousemove         = UiInputField.mousemove
	self.keydown           = UiInputField.keydown
	self.textinput         = UiInputField.textinput
	self.onInput           = self.onInput or UiInputField.onInput
	self.onEnter           = self.onEnter or UiInputField.onEnter
	self.onDelete          = self.onDelete or UiInputField.onDelete
	self.onBackspace       = self.onBackspace or UiInputField.onBackspace
	self.onArrowLeft       = self.onArrowLeft or UiInputField.onArrowLeft
	self.onArrowRight      = self.onArrowRight or UiInputField.onArrowRight
	self.onArrowDown       = self.onArrowDown or UiInputField.onArrowDown
	self.onArrowUp         = self.onArrowUp or UiInputField.onArrowUp
	self.onHome            = self.onHome or UiInputField.onHome
	self.onEnd             = self.onEnd or UiInputField.onEnd
	self.onCut             = self.onCut or UiInputField.onCut
	self.onCopy            = self.onCopy or UiInputField.onCopy
	self.onPaste           = self.onPaste or UiInputField.onPaste
	self.onSelectAll       = self.onSelectAll or UiInputField.onSelectAll
end
