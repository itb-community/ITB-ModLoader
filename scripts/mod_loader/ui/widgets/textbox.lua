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

function UiTextBox:addText(input)
	if not self.editable then return end
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

local function regex(char)
	if char:match("%p") then
		return "%p+%s*"
	elseif char:match("%s") then
		return "[^%p%s]*%s+"
	elseif char:match("%P") then
		return "[^%p%s]+%s*"
	end

	return ""
end

function UiTextBox:onEnter()
	self:newline()
end

function UiTextBox:onDelete()
	if sdlext.isCtrlDown() then
		local char = self.typedtext:sub(self.caret + 1, self.caret + 1)
		local trail = self.typedtext:sub(self.caret + 1, -1)
		local match = "^"..regex(char)
		local word = trail:match(match)
		self:delete(word:len())
	else
		self:delete(1)
	end
end

function UiTextBox:onBackspace()
	if sdlext.isCtrlDown() then
		local char = self.typedtext:sub(self.caret, self.caret)
		local lead = self.typedtext:sub(0, self.caret)
		local match = regex(char).."$"
		local word = lead:match(match)
		self:backspace(word:len())
	else
		self:backspace(1)
	end
end

function UiTextBox:onArrowRight()
	if sdlext.isCtrlDown() then
		local char = self.typedtext:sub(self.caret + 1, self.caret + 1)
		local trail = self.typedtext:sub(self.caret + 1, -1)
		local match = "^"..regex(char)
		local word = trail:match(match)
		self:moveCaret(word:len())
	else
		self:moveCaret(1)
	end
end

function UiTextBox:onArrowLeft()
	if sdlext.isCtrlDown() then
		local char = self.typedtext:sub(self.caret, self.caret)
		local lead = self.typedtext:sub(0, self.caret)
		local match = regex(char).."$"
		local word = lead:match(match)
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
	self:setCaret(0)
end

function UiTextBox:onEnd()
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

function UiTextBox:keydown(keycode)
	if sdlext.isConsoleOpen() then return false end

	local eventKeyHandler = eventkeyHandler[keycode]

	if eventKeyHandler then
		self[eventKeyHandler](self)
	end

	-- disable keyboard while the input field is active
	return true
end

function UiTextBox:textinput(textinput)
	if sdlext.isConsoleOpen() then return false end

	if not self.maxLength or self.typedtext:len() < self.maxLength then
		if not self.alphabet or self.alphabet:find(textinput) then
			self:addText(textinput)
		end
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
