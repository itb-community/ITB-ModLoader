local GapBuffer = require("scripts/mod_loader/datastructures/gap_buffer").string
--[[
	A UI element with a simple purpose. Whenever this element is focused
	(and the console is closed), all keyboard input is overridden and fed
	into its 'textfield' object. The entered text can for example be displayed
	by decorating it with DecoTextBox.

	An alternate way of using the class is to call 'registerInput' for any
	other Ui class instance. This method will then copy functions from this
	class to the calling ui element.
--]]

UiTextBox = Class.inherit(Ui)
function UiTextBox:new()
	Ui.new(self)
	self:init()
end

function UiTextBox:init()
	self.editable = true

	self.textfield = GapBuffer()
	self.selection = nil

	self.onTextAddedEvent = Event()
	self.onTextRemovedBeforeEvent = Event()
	self.onTextRemovedAfterEvent = Event()
	self.onCaretMovedEvent = Event()
end

function UiTextBox:setMaxLength(maxLength)
	self.maxLength = maxLength
	return self
end

function UiTextBox:setAlphabet(alphabet)
	self.alphabet = alphabet
	return self
end

function UiTextBox:setCaret(newcaret)
	local textfield = self.textfield
	local size = textfield:size()

	if newcaret < 1 then
		newcaret = 1
	elseif newcaret > size + 1 then
		newcaret = size + 1
	end

	self.textfield:move(newcaret)
	self.onCaretMovedEvent:dispatch(newcaret)
end

function UiTextBox:moveCaret(delta)
	local textfield = self.textfield
	self:setCaret(textfield.gap_left + delta)
end

function UiTextBox:getCaret()
	return self.textfield.gap_left
end

function UiTextBox:tryStartSelection()
	if sdlext.isShiftDown() then
		if self.selection == nil then
			self.selection = self:getCaret()
		end
	else
		self.selection = nil
	end
end

function UiTextBox:deleteSelection()
	if not self.editable or self.selection == nil then return end
	local from, to = self:getSelection()

	self:setCaret(from)
	self:delete(to - from)
	self.selection = nil
end

function UiTextBox:getSelection()
	if self.selection == nil then return 0,0 end
	local from = self.selection
	local to = self:getCaret()

	if from < to then
		return from, to
	else
		return to, from
	end
end

function UiTextBox:getText(from, to)
	return self.textfield:get(from, to - from + 1)
end

function UiTextBox:copy()
	local from, to = self:getSelection()
	local text = self.textfield:get(from, to - from)
	if type(text) == 'string' then
		sdl.clipboard.set(text)
	end
end

function UiTextBox:paste()
	if not self.editable then return end
	local text = sdl.clipboard.get()
	if type(text) == 'string' then
		self:addText(text)
	end
end

-- TODO:
-- function UiTextBox:undo()
-- end

-- TODO:
-- function UiTextBox:redo()
-- end

function UiTextBox:addText(input)
	if not self.editable then return end

	local length = input:len()
	local textfield = self.textfield
	local caret = textfield.gap_left
	if self.maxLength then
		local remainingLength = self.maxLength - textfield:size()
		if length > remainingLength then
			input = input:sub(0, remainingLength)
		end
	end

	textfield:insert(caret, input)
	self.onTextAddedEvent:dispatch(caret, input)
end

function UiTextBox:delete(length)
	if not self.editable then return end
	local textfield = self.textfield
	local caret = textfield.gap_left
	local size = textfield:size()

	if length > size + 1 - caret then
		length = size + 1 - caret
	end

	textfield:deleteAfter(caret, length)
	self.onTextRemovedAfterEvent:dispatch(caret, length)
end

function UiTextBox:backspace(length)
	if not self.editable then return end
	local textfield = self.textfield
	local caret = textfield.gap_left
	local size = textfield:size()

	if length > caret - 1 then
		length = caret - 1
	end

	textfield:deleteBefore(caret, length)
	self.onTextRemovedBeforeEvent:dispatch(caret, length)
end

function UiTextBox:newline()
	if not self.editable then return end
	local textfield = self.textfield
	local caret = textfield.gap_left

	textfield:insert(caret, "\n")
	self.onTextAddedEvent:dispatch(caret, "\n")
end

-- TODO:
-- find a way to scan and return complete words

-- local punctuationAndSpaces = "%p+%s*"
-- local nonPunctuationAndSpaces = "[^%p%s]*%s*"

-- local function getFirstWordIndices(text)
	-- return
		-- text:find("^"..punctuationAndSpaces)    or
		-- text:find("^"..nonPunctuationAndSpaces)
-- end

-- local function getLastWordIndices(text)
	-- return
		-- text:find(punctuationAndSpaces.."$")    or
		-- text:find(nonPunctuationAndSpaces.."$")
-- end

function UiTextBox:onSelectAll()
	self:setCaret(1)
	self.selection = self.textfield:size() + 1
end

function UiTextBox:onCopy()
	self:copy()
end

function UiTextBox:onCut()
	self:copy()
	self:deleteSelection()
end

function UiTextBox:onPaste()
	self:deleteSelection()
	self:paste()
end

function UiTextBox:onInput(text)
	self:deleteSelection()
	self:addText(text)
end

function UiTextBox:onEnter()
	self:deleteSelection()
	self:newline()
end

function UiTextBox:onDelete()
	-- TODO: deleting one word at a time
	-- is not implemented yet

	if self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	-- elseif sdlext.isCtrlDown() then
		-- local trail = self.typedtext:sub(self.caret + 1, -1)
		-- local from, to = getFirstWordIndices(trail)
		-- self:delete(to - from)
	else
		self:delete(1)
	end
end

function UiTextBox:onBackspace()
	-- TODO: deleting one word at a time
	-- is not implemented yet

	if self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	-- elseif sdlext.isCtrlDown() then
		-- local lead = self.typedtext:sub(0, self.caret)
		-- local from, to = getLastWordIndices(lead)
		-- self:backspace(to - from)
	else
		self:backspace(1)
	end
end

function UiTextBox:onArrowRight()
	self:tryStartSelection()

	-- TODO: moving the caret one word at a time
	-- is not implemented yet

	-- if sdlext.isCtrlDown() then
		-- local trail = self.typedtext:sub(self.caret + 1, -1)
		-- local from, to = getFirstWordIndices(trail)
		-- self:moveCaret(to - from)
	-- else
		self:moveCaret(1)
	-- end
end

function UiTextBox:onArrowLeft()
	self:tryStartSelection()

	-- TODO: moving the caret one word at a time
	-- is not implemented yet

	-- if sdlext.isCtrlDown() then
		-- local lead = self.typedtext:sub(0, self.caret)
		-- local from, to = getLastWordIndices(lead)
		-- self:moveCaret(from - to)
	-- else
		self:moveCaret(-1)
	-- end
end

function UiTextBox:onArrowUp()
	-- hard to define without knowing
	-- character widths and word wrapping
end

function UiTextBox:onArrowDown()
	-- hard to define without knowing
	-- character widths and word wrapping
end

function UiTextBox:onHome()
	-- TODO:
	-- Home should preferably set the caret
	-- to the start of the current line.
	-- Ctrl+Home should send the caret to
	-- the start of the document.

	self:tryStartSelection()
	self:setCaret(0)
end

function UiTextBox:onEnd()
	-- TODO:
	-- End should preferably set the caret
	-- to the end of the current line.
	-- Ctrl+End should send the caret to
	-- the end of the document.

	self:tryStartSelection()
	self:setCaret(self.textfield:size())
end

function UiTextBox:onPageUp()
	-- hard to define
end

function UiTextBox:onPageDown()
	-- hard to define
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
	[SDLKeycodes.PAGEUP] = "onPageUp",
	[SDLKeycodes.PAGEDOWN] = "onPageDown"
	-- TODO: add 'tab'
}

local eventkeyHandler_ctrl = {
	[SDLKeycodes.a] = "onSelectAll",
	[SDLKeycodes.x] = "onCut",
	[SDLKeycodes.c] = "onCopy",
	[SDLKeycodes.v] = "onPaste"
}

function UiTextBox:keydown(keycode)
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

function UiTextBox:textinput(textinput)
	if sdlext.isConsoleOpen() then return false end

	if not self.alphabet or self.alphabet:find(textinput) then
		self:onInput(textinput)
	end

	return true
end

function Ui:registerAsTextBox()
	UiTextBox.init(self)
	self.setMaxLength      = UiTextBox.setMaxLength
	self.setAlphabet       = UiTextBox.setAlphabet
	self.setCaret          = UiTextBox.setCaret
	self.moveCaret         = UiTextBox.moveCaret
	self.tryStartSelection = UiTextBox.tryStartSelection
	self.deleteSelection   = UiTextBox.deleteSelection
	self.getSelection      = UiTextBox.getSelection
	self.copy              = UiTextBox.copy
	self.paste             = UiTextBox.paste
	self.addText           = UiTextBox.addText
	self.delete            = UiTextBox.delete
	self.backspace         = UiTextBox.backspace
	self.newline           = UiTextBox.newline
	self.keydown           = UiTextBox.keydown
	self.textinput         = UiTextBox.textinput
	self.onInput           = self.onInput or UiTextBox.onInput
	self.onEnter           = self.onEnter or UiTextBox.onEnter
	self.onDelete          = self.onDelete or UiTextBox.onDelete
	self.onBackspace       = self.onBackspace or UiTextBox.onBackspace
	self.onArrowLeft       = self.onArrowLeft or UiTextBox.onArrowLeft
	self.onArrowRight      = self.onArrowRight or UiTextBox.onArrowRight
	self.onArrowUp         = self.onArrowUp or UiTextBox.onArrowUp
	self.onArrowDown       = self.onArrowDown or UiTextBox.onArrowDown
	self.onHome            = self.onHome or UiTextBox.onHome
	self.onEnd             = self.onEnd or UiTextBox.onEnd
	self.onPageUp          = self.onPageUp or UiTextBox.onPageUp
	self.onPageDown        = self.onPageDown or UiTextBox.onPageDown
	self.onCut             = self.onCut or UiTextBox.onCut
	self.onCopy            = self.onCopy or UiTextBox.onCopy
	self.onPaste           = self.onPaste or UiTextBox.onPaste
	self.onSelectAll       = self.onSelectAll or UiTextBox.onSelectAll
end
