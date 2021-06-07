--[[
	A UI element with a simple purpose. Whenever this element is focused
	(and the console is closed), all keyboard input is overridden and fed
	into its 'text' field. The entered text can for example be displayed
	by decorating it with DecoInput.

	An alternate way of using the class is to call 'registerInput' for any
	other Ui class instance. This method will then copy functions from this
	class to the calling ui element.

	The method 'onEnter' can be overridden to catch and process what should
	happen when enter be pressed while the element is focused.

	Examples:
	-- line break:
	function ui:onEnter()
		self.typedtext = self.typedtext .. "\n"
	end

	-- unfocus the input box:
	function ui:onEnter()
		self.root:setfocus(nil)
	end
--]]
UiTextBox = Class.inherit(Ui)
function UiTextBox:new()
	Ui.new(self)
	self:init()
end

function UiTextBox:init()
	self.editable = true
	self.typedtext = ""
	self.caret = 0
	self.selection = nil
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
	self.caret = math.max(0, math.min(newcaret, self.typedtext:len()))
end

function UiTextBox:moveCaret(delta)
	self:setCaret(self.caret + delta)
end

function UiTextBox:tryStartSelection()
	if sdlext.isShiftDown() then
		if self.selection == nil then
			self.selection = self.caret
		end
	else
		self.selection = nil
	end
end

function UiTextBox:getSelection()
	if self.selection == nil then return 0,0 end
	local from = self.selection
	local to = self.caret

	if from < to then
		return from, to
	else
		return to, from
	end
end

function UiTextBox:deleteSelection()
	if not self.editable or self.selection == nil then return end
	local from, to = self:getSelection()

	self:setCaret(from)
	self:delete(to - from)
	self.selection = nil
end

function UiTextBox:addText(input)
	if not self.editable then return end

	if self.maxLength then
		local remainingLength = self.maxLength - self.typedtext:len()
		if input:len() > remainingLength then
			input = input:sub(0, remainingLength)
		end
	end

	local lead = self.typedtext:sub(0, self.caret)
	local trail = self.typedtext:sub(self.caret + 1, -1)

	self.typedtext = lead..input..trail
	self.caret = self.caret + input:len()
end

function UiTextBox:delete(count)
	if not self.editable then return end
	local lead = self.typedtext:sub(0, self.caret)
	local trail = self.typedtext:sub(self.caret + 1 + count, -1)

	self.typedtext = lead..trail
end

function UiTextBox:backspace(count)
	if not self.editable then return end
	local trail = self.typedtext:sub(self.caret + 1, -1)

	self:setCaret(self.caret - count)
	local lead = self.typedtext:sub(0, self.caret)

	self.typedtext = lead..trail
end

function UiTextBox:newline()
	if not self.editable then return end
	local lead = self.typedtext:sub(0, self.caret)
	local trail = self.typedtext:sub(self.caret + 1, -1)

	self.typedtext = lead.."\n"..trail
	self.caret = self.caret + 1
end

local punctuationAndSpaces = "%p+%s*"
local nonPunctuationAndSpaces = "[^%p%s]*%s*"

local function getFirstWord(text)
	return
		text:match("^"..punctuationAndSpaces)    or
		text:match("^"..nonPunctuationAndSpaces)
end

local function getLastWord(text)
	return
		text:match(punctuationAndSpaces.."$")    or
		text:match(nonPunctuationAndSpaces.."$")
end

function UiTextBox:onSelectAll()
	self.caret = 0
	self.selection = self.typedtext:len()
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
	if self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	elseif sdlext.isCtrlDown() then
		local trail = self.typedtext:sub(self.caret + 1, -1)
		local word = getFirstWord(trail)
		self:delete(word:len())
	else
		self:delete(1)
	end
end

function UiTextBox:onBackspace()
	if self.selection ~= nil and self.selection ~= self.caret then
		self:deleteSelection()
	elseif sdlext.isCtrlDown() then
		local lead = self.typedtext:sub(0, self.caret)
		local word = getLastWord(lead)
		self:backspace(word:len())
	else
		self:backspace(1)
	end
end

function UiTextBox:onArrowRight()
	self:tryStartSelection()

	if sdlext.isCtrlDown() then
		local trail = self.typedtext:sub(self.caret + 1, -1)
		local word = getFirstWord(trail)
		self:moveCaret(word:len())
	else
		self:moveCaret(1)
	end
end

function UiTextBox:onArrowLeft()
	self:tryStartSelection()

	if sdlext.isCtrlDown() then
		local lead = self.typedtext:sub(0, self.caret)
		local word = getLastWord(lead)
		self:moveCaret(-word:len())
	else
		self:moveCaret(-1)
	end
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
	self:tryStartSelection()
	self:setCaret(0)
end

function UiTextBox:onEnd()
	self:tryStartSelection()
	self:setCaret(self.typedtext:len())
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
}

local eventkeyHandler_ctrl = {
	[SDLKeycodes.a] = "onSelectAll",
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
	self.setMaxLength = UiTextBox.setMaxLength
	self.setAlphabet  = UiTextBox.setAlphabet
	self.setCaret     = UiTextBox.setCaret
	self.moveCaret    = UiTextBox.moveCaret
	self.addText      = UiTextBox.addText
	self.delete       = UiTextBox.delete
	self.backspace    = UiTextBox.backspace
	self.newline      = UiTextBox.newline
	self.keydown      = UiTextBox.keydown
	self.textinput    = UiTextBox.textinput
	self.onEnter      = self.onEnter or UiTextBox.onEnter
	self.onDelete     = self.onDelete or UiTextBox.onDelete
	self.onBackspace  = self.onBackspace or UiTextBox.onBackspace
	self.onArrowLeft  = self.onArrowLeft or UiTextBox.onArrowLeft
	self.onArrowRight = self.onArrowRight or UiTextBox.onArrowRight
	self.onArrowUp    = self.onArrowUp or UiTextBox.onArrowUp
	self.onArrowDown  = self.onArrowDown or UiTextBox.onArrowDown
	self.onHome       = self.onHome or UiTextBox.onHome
	self.onEnd        = self.onEnd or UiTextBox.onEnd
	self.onPageUp     = self.onPageUp or UiTextBox.onPageUp
	self.onPageDown   = self.onPageDown or UiTextBox.onPageDown
end
