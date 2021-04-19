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

	Example:
	function ui:onEnter()
		self.text = self.text .. "\n"
	end
--]]
UiInput = Class.inherit(Ui)
function UiInput:new()
	Ui.new(self)
	self.text = ""
end

function UiInput:onEnter() end

function UiInput:keydown(keycode)
	if sdlext.isConsoleOpen() then return false end

	if keycode == SDLKeycodes.BACKSPACE then
		self.text = self.text:sub(1,-2)
	elseif SDLKeycodes.isEnter(keycode) then
		self:onEnter()
	end

	-- disable keyboard while the input field is active
	return true
end

function UiInput:textinput(textinput)
	if sdlext.isConsoleOpen() then return false end

	self.text = self.text .. textinput

	return true
end

function Ui:registerInput()
	self.text = self.text or ""
	self.onEnter   = self.onEnter or UiInput.onEnter
	self.keydown   = self.keydown
	self.textinput = self.textinput
end
