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
UiInput = Class.inherit(Ui)
function UiInput:new()
	Ui.new(self)
	self.typedtext = ""
end

function UiInput:setMaxLength(maxLength)
	self.maxLength = maxLength
	return self
end

function UiInput:setAlphabet(alphabet)
	self.alphabet = alphabet
	return self
end

function UiInput:onEnter() end

function UiInput:keydown(keycode)
	if sdlext.isConsoleOpen() then return false end

	if keycode == SDLKeycodes.BACKSPACE then
		self.typedtext = self.typedtext:sub(1,-2)
	elseif SDLKeycodes.isEnter(keycode) then
		self:onEnter()
	end

	-- disable keyboard while the input field is active
	return true
end

function UiInput:textinput(textinput)
	if sdlext.isConsoleOpen() then return false end

	if not self.maxLength or self.typedtext:len() < self.maxLength then
		if not self.alphabet or self.alphabet:find(textinput) then
			self.typedtext = self.typedtext .. textinput
		end
	end

	return true
end

function Ui:registerInput()
	self.typedtext = self.typedtext or ""
	self.onEnter   = self.onEnter or UiInput.onEnter
	self.keydown   = self.keydown
	self.textinput = self.textinput
end