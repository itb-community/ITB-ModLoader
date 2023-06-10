
--[[
	A decoration designed to be paired with the UiInputField Class,
	or another Ui object that has been registered as a UiInputField

	UiInputField.registerAsInputField(arbitraryUiObject)
--]]
local function isEqualColor(color1, color2)
	if true
		and color1.r == color2.r
		and color1.g == color2.g
		and color1.b == color2.b
		and color1.a == color2.a
	then
		return true
	end

	return false
end

local nullsurface = sdl.surface("")
local surfaceFonts = {}
local comparerFont = {}
SurfaceFont = {
	get = function(self, s)
		-- omit for speed
		--Assert.Equals('string', type(s))
		--Assert.Equals(1, s:len())

		local surfaces = self._surfaces
		if not surfaces[s] then
			local surface
			if s == "\n" then
				surface = nullsurface
			else
				surface = sdl.text(self.font, self.textset, s)
			end
			surfaces[s] = surface
		end


		return surfaces[s]
	end,
	__eq = function(a, b)
		if true
			and a.font == b.font
			and a.textset.antialias == b.textset.antialias
			and a.textset.outlineWidth == b.textset.outlineWidth
			and isEqualColor(a.textset.color, b.textset.color)
			and isEqualColor(a.textset.outlineColor, b.textset.outlineColor)
		then
			return true
		end

		return false
	end
}

SurfaceFont.__index = SurfaceFont
setmetatable(comparerFont, SurfaceFont)

function SurfaceFont:getOrCreate(font, textset)
	comparerFont.font = font
	comparerFont.textset = textset

	for i, surfaceFont in ipairs(surfaceFonts) do
		if surfaceFont == comparerFont then
			return surfaceFont
		end
	end

	local surfaceFont = {
		_surfaces = {},
		font = font,
		textset = deco.textset(
			sdl.rgba(
				textset.color.r,
				textset.color.g,
				textset.color.b,
				textset.color.a
			),
			sdl.rgba(
				textset.outlineColor.r,
				textset.outlineColor.g,
				textset.outlineColor.b,
				textset.outlineColor.a
			),
			textset.outlineWidth,
			textset.antialias
		)
	}
	setmetatable(surfaceFont, SurfaceFont)
	table.insert(surfaceFonts, surfaceFont)

	return surfaceFont
end

DecoInputField = Class.inherit(UiDeco)
function DecoInputField:new(opt)
	UiDeco.new(self)
	opt = opt or {}

	self.font = opt.font or deco.uifont.default.font
	self.textset = opt.textset or deco.uifont.default.set
	self.alignH = opt.alignH or "left"
	self.alignV = opt.alignV or "top"
	self.offsetX = opt.offsetX or 0
	self.offsetY = opt.offsetY or 0
	self.charSpacing = opt.charSpacing or 1
	self.caretBlinkMs = opt.caretBlinkMs or 600
	self.selectionColor = opt.selectionColor or deco.colors.buttonborder
	self.selectHeightOvershoot = 2

	self.rect = sdl.rect(0,0,0,0)
	self.drawbuffer = {}

	self:updateFont()
end

local function subscribe(event, subscription)
	local addSubscription = true
		and type(event) == 'table'
		and type(subscription) == 'function'
		and Event.instanceOf(event, Event) == true
		and event:isSubscribed(subscription) == false

	if addSubscription then
		event:subscribe(subscription)
	end
end

local function unsubscribe(event, subscription)
	local remSubscription = true
		and type(event) == 'table'
		and type(subscription) == 'function'
		and Event.instanceOf(event, Event) == true
		and event:isSubscribed(subscription) == true

	if remSubscription then
		event:unsubscribe(subscription)
	end
end

function DecoInputField:createMouseEventWrappers()
	if self.mousedown_wrapper == nil then
		self.mousedown_wrapper = function(widget, mx, my, button)
			self:mousedown(widget, mx, my, button)
		end
	end

	if self.mousemove_wrapper == nil then
		self.mousemove_wrapper = function(widget, mx, my)
			self:mousemove(widget, mx, my)
		end
	end
end

function DecoInputField:apply(widget)
	self.widget = widget
	self:createMouseEventWrappers()
	subscribe(widget.onMousePressEvent, self.mousedown_wrapper)
	subscribe(widget.onMouseMoveEvent, self.mousemove_wrapper)
end

function DecoInputField:unapply(widget)
	self.widget = nil
	self:createMouseEventWrappers()
	unsubscribe(widget.onMousePressEvent, self.mousedown_wrapper)
	unsubscribe(widget.onMouseMoveEvent, self.mousemove_wrapper)
end

function DecoInputField:updateFont()
	self.surfaceFont = SurfaceFont:getOrCreate(self.font, self.textset)
	self.surfaceHeight = self.surfaceFont:get("|"):h()
end

function DecoInputField:mousedown(widget, mx, my, button)
	local caret = self:screenToIndex(mx, my)
	widget:setCaret(caret)
	widget.selection = caret
end

function DecoInputField:mousemove(widget, mx, my)
	if widget.pressed then
		local caret = self:screenToIndex(mx, my)
		widget:setCaret(caret)
	end
end

function DecoInputField:setFont(font)
	font = font or deco.uifont.default.font

	if font ~= self.font then
		self.font = font
		updateFont(self)
	end
end

function DecoInputField:setTextSettings(textset)
	textset = textset or deco.uifont.default.set

	if textset ~= self.textset then
		self.textset = textset
		updateFont(self)
	end
end

function DecoInputField:setSelectionColor(color)
	self.selectionColor = color or deco.colors.transparent
end

function DecoInputField:screenToIndex(screenx, screeny)
	local widget = self.widget
	local textfield = widget.textfield
	local textLength = textfield:len()
	local drawbuffer = self.drawbuffer
	local surfaceHeight = self.surfaceHeight
	local charSpacing = self.charSpacing
	local overshoot = self.selectHeightOvershoot
	local x = self.x or 0
	local y = self.y or 0
	local character

	if screeny + overshoot < y then
		character =  0
	elseif screeny - overshoot > y + surfaceHeight then
		character = textLength
	else
		local function getValue(i)
			return x + drawbuffer[i * 2 + 1] + (drawbuffer[i * 2]:w() + charSpacing) / 2
		end

		character = BinarySearch(screenx, 0, textLength, getValue, "up")
	end

	return character
end

function DecoInputField:indexToScreen(index)
	local drawbuffer = self.drawbuffer
	local bufferindex = index * 2
	return
		self.x, drawbuffer[bufferindex + 1],
		self.y
end

function DecoInputField:draw(screen, widget)
	-- drawbuffer is a 0-indexed array containing alternating entries
	-- of surfaces to draw, and the x position to draw them, starting
	-- at 0 for the first character.
	local drawbuffer = self.drawbuffer

	local widgetWidth = widget.w
	local widgetHeight = widget.h
	local widgetLeft = widget.screenx
	local widgetTop = widget.screeny
	local widgetRight = widgetLeft + widgetWidth
	local widgetBottom = widgetTop + widgetHeight

	local alignV = self.alignV
	local alignH = self.alignH

	local selectFrom, selectTo = widget:getSelection()
	local selectionColor = self.selectionColor
	local textfield = widget.textfield
	local surfaceFont = self.surfaceFont
	local charSpacing = self.charSpacing
	local surfaceHeight = self.surfaceHeight
	local caretBlinkMs = self.caretBlinkMs
	local textLength = textfield:len()
	local bufferEnd = textLength * 2 - 2
	local focused = widget.focused
	local isCaret = false
	local caret = widget.caret
	local rect = self.rect
	rect.h = surfaceHeight

	-- localize common functions
	local getSurfaceWidth = nullsurface.w
	local getSurface = surfaceFont.get
	local drawrect = screen.drawrect
	local blit = screen.blit
	local textWidth = 0
	local textHeight = surfaceHeight

	if widget.focused then
		local focusChanged = focused ~= self.focused_prev
		local caretChanged = caret ~= self.caret_prev
		local time = os.clock() * 1000 % caretBlinkMs

		if not self.focustime or focusChanged or caretChanged then
			self.focustime = time
		end

		if (time - self.focustime) % caretBlinkMs * 2 < caretBlinkMs then
			isCaret = true
		end
	end

	self.focused_prev = widget.focused
	self.caret_prev = caret

	-- fill drawbuffer
	for i = 1, textLength do
		local char = textfield:sub(i, i)
		local bufferindex = i * 2 - 2
		local surface = getSurface(surfaceFont, char)
		local surfaceWidth = getSurfaceWidth(surface) + charSpacing

		drawbuffer[bufferindex] = surface
		drawbuffer[bufferindex+1] = textWidth
		textWidth = textWidth + surfaceWidth
	end

	local x = self.offsetX
	local y = self.offsetY

	if alignH == "center" then
		x = x + widgetLeft + math.floor((widgetWidth - textWidth) / 2)
	elseif alignH == "right" then
		x = x + widgetRight - textWidth
	else
		x = x + widgetLeft
	end

	if alignV == "center" then
		y = y + widgetTop + math.floor((widgetHeight - textHeight) / 2)
	elseif alignV == "bottom" then
		y = y + widgetBottom - textHeight
	else
		y = y + widgetTop
	end

	-- add final entry to simplify
	-- caret placement and lookup
	drawbuffer[bufferEnd+2] = nullsurface
	drawbuffer[bufferEnd+3] = textWidth

	-- draw selection
	if selectTo > selectFrom then
		local selectWidth = 0

		rect.x = x + drawbuffer[selectFrom * 2 + 1]
		rect.y = y

		for i = selectFrom * 2, selectTo * 2 - 2, 2 do
			local surface = drawbuffer[i]
			selectWidth = selectWidth + getSurfaceWidth(surface) + charSpacing
		end

		rect.w = selectWidth

		drawrect(screen, selectionColor, rect)
	end

	-- draw text
	for i = 0, bufferEnd, 2 do
		blit(screen, drawbuffer[i], nil, x + drawbuffer[i+1], y)
	end

	-- draw caret
	if isCaret then
		local i = caret * 2
		rect.x = x + drawbuffer[i+1]
		rect.y = y
		rect.w = 1
		drawrect(screen, self.textset.color, rect)
	end

	self.x = x
	self.y = y
	self.drawbuffer = drawbuffer
end
