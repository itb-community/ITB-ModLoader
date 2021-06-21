local BinarySearchMax = require("scripts/mod_loader/datastructures/binarySearch").max

--[[
	A decoration used to dynamically update and display
	text contained in a widget.
	Created mainly for the UiTextBox Class.
--]]
local nullsurface = sdl.surface("")
local surfaceFonts = {}
SurfaceFont = {
	_surfaces = {},
	font,
	textset,
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
		if not a.font ~= not b.font then
			return false
		end

		if not a.textset ~= not b.textset then
			return false
		end

		if a.font then
			if
				a.font.name ~= b.font.name or
				a.font.size ~= b.font.size
			then
				return false
			end
		end

		if a.textset then
			if 
				a.textset.outlineColor ~= b.textset.outlineColor or
				a.textset.outlineWidth ~= b.textset.outlineWidth or
				a.textset.antialias ~= b.textset.antialias
			then
				return false
			end
		end

		return true
	end
}

SurfaceFont.__index = SurfaceFont

function SurfaceFont:getOrCreate(font, textset)
	for i, surfaceFont in ipairs(surfaceFonts) do
		if surfaceFont:__eq{font = font, set = textset} then
			return surfaceFont
		end
	end

	local surfaceFont = {font = font, textset = textset}
	setmetatable(surfaceFont, SurfaceFont)

	return surfaceFont
end

DecoTextBox = Class.inherit(UiDeco)
function DecoTextBox:new(opt)
	UiDeco.new(self)
	opt = opt or {}

	self.font = opt.font or deco.uifont.default.font
	self.textset = opt.textset or deco.uifont.default.set
	self.alignH = opt.alignH or "left"
	self.alignV = opt.alignV or "top"
	self.wrapText = opt.wrapText or true
	self.splitWords = opt.splitWords or false
	self.lineSpacing = opt.lineSpacing or 0
	self.charSpacing = opt.charSpacing or 1
	self.caretBlinkMs = opt.caretBlinkMs or 600
	self.selectionColor = opt.selectionColor or deco.colors.buttonborder

	self.rect = sdl.rect(0,0,0,0)
	self.drawbuffer = {}
	self.offsetY = 0
	self.lines = {0}
	self.lineCount = 0

	self:updateFont()
end

function DecoTextBox:apply(widget)
	self.widget = widget

	-- TODO:
	-- checking instanceOf UiTextBox will not be sufficient
	-- if UiTextBox.registerAsTextBox is used to set up the
	-- text widget. (same in unapply)

	if widget:instanceOf(UiTextBox) then
		widget.onArrowUp = function(widget)
			self:onArrowUp(widget)
		end
		widget.onArrowDown = function(widget)
			self:onArrowDown(widget)
		end
		widget.mousedown = function(widget, mx, my, button)
			self:mousedown(widget, mx, my, button)
			return Ui.mousedown(widget, mx, my, button)
		end
		widget.mousemove = function(widget, mx, my)
			self:mousemove(widget, mx, my)
			return Ui.mousemove(widget, mx, my)
		end
		widget.wheel = function(widget, mx, my, y)
			self:wheel(widget, mx, my, y)
			return false
		end
		self.onTextAddedEventCallback = function(caret, text)
			self:onTextAdded(caret, text)
		end
		self.onTextRemovedBeforeEventCallback = function(caret, length)
			self:onTextRemovedBefore(caret, length)
		end
		self.onTextRemovedAfterEventCallback = function(caret, length)
			self:onTextRemovedAfter(caret, length)
		end
		self.onCaretMovedEventCallback = function(caret)
			self:onCaretMoved(caret)
		end

		widget.onTextAddedEvent:subscribe(self.onTextAddedEventCallback)
		widget.onTextRemovedBeforeEvent:subscribe(self.onTextRemovedBeforeEventCallback)
		widget.onTextRemovedAfterEvent:subscribe(self.onTextRemovedAfterEventCallback)
		widget.onCaretMovedEvent:subscribe(self.onCaretMovedEventCallback)
	end
end

function DecoTextBox:unapply(widget)
	-- TODO: check if this tracks
	if widget:instanceOf(UiTextBox) then
		local class = getmetatable(widget).__index
		widget.onArrowUp = class.onArrowUp
		widget.onArrowDown = class.onArrowDown
		widget.mousedown = class.mousedown
		widget.mousemove = class.mousemove
		widget.onTextAddedEvent:unsubscribe(self.onTextAddedEventCallback)
		widget.onTextRemovedBeforeEvent:unsubscribe(self.onTextRemovedBeforeEventCallback)
		widget.onTextRemovedAfterEvent:unsubscribe(self.onTextRemovedAfterEventCallback)
		widget.onCaretMovedEvent:unsubscribe(self.onCaretMovedEventCallback)
	end

	self.widget = nil
end

function DecoTextBox:updateFont()
	self.surfaceFont = SurfaceFont:getOrCreate(self.font, self.textset)
	self.surfaceHeight = self.surfaceFont:get("|"):h()
end

-- TODO:
-- When navigating with arrow keys, "preffered column"
-- should be remembered.
-- onArrowUp and onArrowDown should attempt to get
-- back to the preferred column if possible.
-- onArrowLeft and onArrowRight should update the
-- preferred column to the x position of the caret
-- at that character index.

function DecoTextBox:onArrowUp(widget)
	widget:tryStartSelection()
	local x, y = self:indexToScreen(widget:getCaret())
	y = y - (self.surfaceHeight - self.lineSpacing)
	local caret = self:screenToIndex(x, y)
	widget:setCaret(caret)
end

function DecoTextBox:onArrowDown(widget)
	widget:tryStartSelection()
	local x, y = self:indexToScreen(widget:getCaret())
	y = y + (self.surfaceHeight - self.lineSpacing)
	local caret = self:screenToIndex(x, y)
	widget:setCaret(caret)
end

function DecoTextBox:mousedown(widget, mx, my, button)
	local caret = self:screenToIndex(mx, my)
	widget:setCaret(caret)
	widget.selection = caret
end

function DecoTextBox:mousemove(widget, mx, my)
	if widget.pressed then
		local caret = self:screenToIndex(mx, my)
		widget:setCaret(caret)
	end
end

function DecoTextBox:wheel(widget, mx, my, y)
	if widget.pressed then
		-- TODO: do the necessary actions to adjust
		-- the selected characters
	end
end

function DecoTextBox:onCaretMoved(caret)
	-- Potential performance gain:
	-- store and update metadata about caret to
	-- offload some computation from the draw method
end

function DecoTextBox:onTextAdded(caret, text)
	-- Potential performance gain:
	-- store and update metadata about text to
	-- offload some computation from the draw method
end

function DecoTextBox:onTextRemovedAfter(caret, length)
	-- Potential performance gain:
	-- store and update metadata about text to
	-- offload some computation from the draw method
end

function DecoTextBox:onTextRemovedBefore(caret, length)
	-- Potential performance gain:
	-- store and update metadata about text to
	-- offload some computation from the draw method
end

function DecoTextBox:setFont(font)
	font = font or deco.uifont.default.font

	if font ~= self.font then
		self.font = font
		updateFont(self)
	end
end

function DecoTextBox:setTextSettings(textset)
	textset = textset or deco.uifont.default.set

	if textset ~= self.textset then
		self.textset = textset
		updateFont(self)
	end
end

function DecoTextBox:setSelectionColor(color)
	self.selectionColor = color or deco.colors.transparent
end

function DecoTextBox:setWrapText(wrapText)
	if wrapText == nil then
		wrapText = true
	end

	self.wrapText = wrapText
end

function DecoTextBox:setSplitWords(splitWords)
	if splitWords == nil then
		splitWords = true
	end

	self.splitWords = splitWords
end

function DecoTextBox:screenToIndex(screenx, screeny)
	local widget = self.widget
	local textfield = widget.textfield
	local textLength = textfield:size()
	local drawbuffer = self.drawbuffer
	local lines = self.lines
	local lineCount = self.lineCount

	-- adjust for vertical alignment
	screeny = screeny - self.offsetY

	if screeny < drawbuffer[2] then
		return 1
	elseif screeny > drawbuffer[textLength * 3 + 2] + self.surfaceHeight + self.charSpacing then
		return textLength + 1
	end

	local line = BinarySearchMax(1, lineCount, screeny, function(i)
		return drawbuffer[lines[i] + 2]
	end)

	local charStart = lines[line] / 3 + 1
	local charLimit
	if line < lineCount then
		charLimit = lines[line + 1] / 3
		if textfield:get(charLimit) ~= "\n" then
			charLimit = charLimit + 1
		end
	else
		charLimit = textLength + 1
	end

	local character = BinarySearchMax(charStart, charLimit, screenx, function(i)
		return drawbuffer[i * 3 - 2]
	end)

	return character
end

function DecoTextBox:indexToScreen(index)
	local drawbuffer = self.drawbuffer
	local bufferindex = index * 3 - 3
	return
		drawbuffer[bufferindex + 1],
		drawbuffer[bufferindex + 2] + self.offsetY
end

function DecoTextBox:draw(screen, widget)
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
	local lineSpacing = self.lineSpacing
	local surfaceHeight = self.surfaceHeight
	local lineHeight = surfaceHeight + lineSpacing
	local caretBlinkMs = self.caretBlinkMs
	local textLength = textfield:size()
	local bufferEnd = textLength * 3 - 3
	local focused = widget.focused
	local isCaret = false
	local caret = widget:getCaret()
	local rect = self.rect
	rect.h = lineHeight

	-- localize common functions
	local getSurfaceWidth = nullsurface.w
	local getCharacter = textfield.getSingle
	local getSurface = surfaceFont.get
	local drawrect = screen.drawrect
	local blit = screen.blit

	local lines = self.lines
	local wordWidth = 0
	local lineWidth = 0
	local lineIndex = 0
	local lineCount = 0
	local wrap = switch{}
	local commit = wrap.case
	local offsetX
	local offsetY

	if alignH == "center" then
		offsetX = function()
			return widgetLeft + (widgetWidth - lineWidth) / 2
		end
	elseif alignH == "right" then
		offsetX = function()
			return widgetRight - lineWidth
		end
	else
		offsetX = function()
			return widgetLeft
		end
	end

	local x = offsetX()
	local y = widgetTop

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

	local function commitLine(lineEnd)
		if lineEnd < lineIndex then return end

		x = offsetX()

		while lineEnd >= lineIndex do
			local surfaceWidth = getSurfaceWidth(drawbuffer[lineIndex]) + charSpacing
			drawbuffer[lineIndex+1] = x
			drawbuffer[lineIndex+2] = y
			x = x + surfaceWidth
			lineIndex = lineIndex + 3
		end

		y = y + lineHeight
		lineWidth = 0
		lineCount = lineCount + 1
		lines[lineCount + 1] = lineIndex
	end

	-- Potential performance gain:
	-- add metadata like lines and words when adding/deleting
	-- text, and refer to that metadata to determine wrapping
	-- instead of calculating it on draw.

	if self.wrapText then
		if self.splitWords then
			wrap["\n"] = function(index, char)
				local bufferindex = index * 3 - 3

				drawbuffer[bufferindex] = nullsurface
				commitLine(bufferindex)
			end
			wrap.default = function(index, char)
				local bufferindex = index * 3 - 3
				local surface = getSurface(surfaceFont, char)
				local surfaceWidth = getSurfaceWidth(surface) + charSpacing

				drawbuffer[bufferindex] = surface
				if lineWidth + surfaceWidth > widgetWidth then
					commitLine(bufferindex-3)
				end
				lineWidth = lineWidth + surfaceWidth
			end
		else
			local lineEnd = 0
			wrap["\n"] = function(index, char)
				local bufferindex = index * 3 - 3

				drawbuffer[bufferindex] = nullsurface
				lineWidth = lineWidth + wordWidth
				wordWidth = 0
				commitLine(bufferindex)
			end
			wrap[" "] = function(index, char)
				local bufferindex = index * 3 - 3
				local surface = getSurface(surfaceFont, char)
				local surfaceWidth = getSurfaceWidth(surface) + charSpacing

				drawbuffer[bufferindex] = surface
				if lineWidth + wordWidth + surfaceWidth > widgetWidth then
					if lineWidth == 0 then
						lineWidth = wordWidth
						wordWidth = 0
						lineEnd = bufferindex-3
					end
					commitLine(lineEnd)
				end
				lineWidth = lineWidth + wordWidth + surfaceWidth
				wordWidth = 0
				lineEnd = bufferindex
			end
			wrap.default = function(index, char)
				local bufferindex = index * 3 - 3
				local surface = getSurface(surfaceFont, char)
				local surfaceWidth = getSurfaceWidth(surface) + charSpacing

				drawbuffer[bufferindex] = surface
				if lineWidth + wordWidth + surfaceWidth > widgetWidth then
					if lineWidth == 0 then
						lineWidth = wordWidth
						wordWidth = 0
						lineEnd = bufferindex-3
					end
					commitLine(lineEnd)
				end
				wordWidth = wordWidth + surfaceWidth
			end
		end
	else
		wrap["\n"] = function(index, char)
			local bufferindex = index * 3 - 3

			drawbuffer[bufferindex] = nullsurface
			commitLine(bufferindex)
		end
		wrap.default = function(index, char)
			local bufferindex = index * 3 - 3
			local surface = getSurface(surfaceFont, char)
			local surfaceWidth = getSurfaceWidth(surface) + charSpacing

			drawbuffer[bufferindex] = surface
			lineWidth = lineWidth + surfaceWidth
		end
	end

	-- Potential performance gain:
	-- only calculate characters inside the widget. This is currently
	-- very difficult, due to every character's position being
	-- determined from start to end at drawtime
	
	-- fill drawbuffer
	for i = 1, textLength do
		local char = getCharacter(textfield, i, 1)
		commit(wrap, char, i)
	end

	-- commit any uncommited surfaces
	lineWidth = lineWidth + wordWidth
	commitLine(bufferEnd)

	if getCharacter(textfield, textLength) == "\n" then
		x = offsetX()
	elseif textLength > 0 then
		y = y - lineHeight
	end

	-- add final entry to simplify
	-- caret placement and lookup
	drawbuffer[bufferEnd+4] = x
	drawbuffer[bufferEnd+5] = y

	if alignV == "center" then
		local textHeight = lineCount * lineHeight - lineSpacing
		offsetY = (widgetHeight - textHeight) / 2
	elseif alignV == "bottom" then
		local textHeight = lineCount * lineHeight - lineSpacing
		offsetY = widgetHeight - textHeight
	else
		offsetY = 0
	end

	-- Potential performance gain:
	-- Calculating and drawing the selections over a
	-- string of characters will most likely be much
	-- faster than drawing a selection box over each
	-- character individually.
	-- Alternatively, sending a batch of rectangles
	-- to be drawn in one pass might be a good option
	-- as well.

	-- draw selection
	if selectTo > selectFrom then
		for i = selectFrom * 3 - 3, selectTo * 3 - 6, 3 do
			local surface = drawbuffer[i]
			rect.x = drawbuffer[i+1]
			rect.y = drawbuffer[i+2] + offsetY
			rect.w = getSurfaceWidth(surface) + charSpacing
			drawrect(screen, selectionColor, rect)
		end
	end

	local parent = widget.parent
	if parent:instanceOf(UiScrollArea) then
		-- Performance increase for when the textbox is
		-- the immediate child of a UiScrollArea widget.
		-- This is not a general solution, but a specific
		-- optimization to only draw characters inside
		-- the UiScrollArea's dimensions.

		local parentTop = parent.screeny
		local parentBottom = parentTop + parent.h

		-- draw text
		for i = 0, bufferEnd, 3 do
			local y = offsetY + drawbuffer[i+2]
			if y + surfaceHeight > parentTop and y < parentBottom then
				blit(screen, drawbuffer[i], nil, drawbuffer[i+1], y)
			end
		end
	else
		-- Potential performance gain:
		-- use a C function that can draw a batch of sprites instead
		-- of drawing each character one by one.

		-- draw text
		for i = 0, bufferEnd, 3 do
			blit(screen, drawbuffer[i], nil, drawbuffer[i+1], offsetY + drawbuffer[i+2])
		end
	end

	-- draw caret
	if isCaret then
		local i = caret * 3 - 3
		rect.x = drawbuffer[i+1]
		rect.y = drawbuffer[i+2] + offsetY
		rect.w = 1
		drawrect(screen, self.textset.color, rect)
	end

	self.offsetY = offsetY
	self.lineCount = lineCount
	self.drawbuffer = drawbuffer
end

-- TEST CODE:
-- creates a text box at game init for testing functionality
modApi.events.onUiRootCreated:subscribe(function(screen, root)
	tdeco = DecoTextBox{
		alignH = "left",
		alignV = "top",
		wrapText = true,
		splitWords = false
	}
	tscroll = UiScrollArea()
		:width(0.8):height(0.8)
		:decorate{
			DecoFrame(sdl.rgba(13, 15, 23, 128))
		}
		:addTo(root)
	tbox = UiTextBox()
		:width(1):height(1)
		:decorate{
			tdeco
		}
		:addTo(tscroll)

	tscroll:pos(0.1, 0.1)

	-- TODO:
	-- Updating widget height after draw is not
	-- optimal. It would be better if DecoTextBox
	-- would update lineCount/words, etc when text
	-- is added/deleted, so we can fetch an accurate
	-- text height before the time of draw.

	function tdeco:draw(screen, widget)
		DecoTextBox.draw(self, screen, widget)

		local surfaceHeight = self.surfaceHeight
		local lineSpacing = self.lineSpacing
		local lineCount = self.lineCount

		widget.hPercent = nil
		widget.h = math.max(
			lineCount * (surfaceHeight + lineSpacing) - lineSpacing,
			widget.parent.h
		)
	end
end)
