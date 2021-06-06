--[[
	A decoration used to dynamically update and display
	text contained in a widget.
	Created mainly for the UiTextBox Class.
--]]

local surfaceFonts = {}
SurfaceFont = {
	_surfaces = {},
	font,
	textset,
	get = function(self, s)
		Assert.Equals('string', type(s))
		Assert.Equals(1, s:len())
		s = s

		if not self._surfaces[s] then
			self._surfaces[s] = sdl.text(self.font, self.textset, s)
		end

		return self._surfaces[s]
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

local function updateFont(self)
	self.surfaceFont = SurfaceFont:getOrCreate(self.font, self.textset)
	self.surfaceHeight = self.surfaceFont:get("|"):h()
end

DecoTextBox = Class.inherit(UiDeco)
function DecoTextBox:new(opt)
	UiDeco.new(self)
	opt = opt or {}
	self.font = opt.font or deco.uifont.default.font
	self.textset = opt.textset or deco.uifont.default.set
	self.wrapText = opt.wrapText or false
	self.splitWords = opt.splitWords or false
	self.alignH = opt.alignH or "center"
	self.alignV = opt.alignV or "center"
	self.prefix = opt.prefix or ""
	self.suffix = opt.suffix or ""
	self.charSpacing = opt.charSpacing or 1
	self.lineSpacing = opt.lineSpacing or 0
	self.caretBlinkMs = opt.caretBlinkMs or 600
	self.rect = sdl.rect(0,0,0,0)
	updateFont(self)
end

function DecoTextBox:apply(widget)
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
end

function DecoTextBox:unapply(widget)
	-- TODO: check if this tracks
	local class = getmetatable(widget).__index
	widget.onArrowUp = class.onArrowUp
	widget.onArrowDown = class.onArrowDown
	widget.mousedown = class.mousedown
end

function DecoTextBox:onArrowUp(widget)
	local x, y = self:caretToScreen(widget.caret)
	y = y - (self.surfaceHeight - self.lineSpacing)
	local caret = self:screenToCaret(x, y)
	widget:setCaret(caret)
end

function DecoTextBox:onArrowDown(widget)
	local x, y = self:caretToScreen(widget.caret)
	y = y + (self.surfaceHeight - self.lineSpacing)
	local caret = self:screenToCaret(x, y)
	widget:setCaret(caret)
end

function DecoTextBox:mousedown(widget, mx, my, button)
	local caret = self:screenToCaret(mx, my)
	widget:setCaret(caret)
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

function DecoTextBox:setPrefix(prefix)
	self.prefix = prefix or ""
end

function DecoTextBox:setSuffix(suffix)
	self.suffix = suffix or ""
end

local linebuffer
local linewidth
local wordbuffer
local wordwidth
local linebuffers
local linewidths
local nullsurface = sdl.surface("")

local function newword()
	linebuffer[#linebuffer+1] = wordbuffer
	linewidth = linewidth + wordwidth
	wordbuffer = {}
	wordwidth = 0
end

local function newline()
	linebuffers[#linebuffers+1] = linebuffer
	linewidths[#linewidths+1] = linewidth
	linebuffer = {}
	linewidth = 0
end

function DecoTextBox:caretToScreen(caret)
	local x, y = 0, 0

	if self.coordsByChars then
		local caretPosition = self.coordsByChars[caret]
		if caretPosition then
			x = caretPosition[1]
			y = caretPosition[2]
		end
	end

	return x, y
end

function DecoTextBox:screenToCaret(x, y)
	local caret = 0

	if self.coordsByLines and #self.coordsByLines > 0 then
		local linebuffer_best = self.coordsByLines[1]

		-- find best line
		for line = 2, #self.textByLines do
			local linebuffer = self.coordsByLines[line]
			if linebuffer[1][2] > y then
				break
			end

			linebuffer_best = linebuffer
			caret = caret + #self.coordsByLines[line-1]
		end

		-- find best char
		for char = 1, #linebuffer_best do
			if linebuffer_best[char][1] > x then
				break
			end

			caret = caret + 1
		end
	end

	return caret
end

function DecoTextBox:drawCaret(screen, x, y)
	self.rect.x = x
	self.rect.y = y
	self.rect.w = 1
	self.rect.h = self.surfaceHeight
	screen:drawrect(self.textset.color, self.rect)
end

function DecoTextBox:draw(screen, widget)
	local focused = widget.focused
	local caret = widget.caret
	local isCaret = false
	local focusChanged = focused ~= self.focused_prev
	local caretChanged = caret ~= self.caret_prev

	if focused then
		local time = os.clock() * 1000 % self.caretBlinkMs

		if not self.focustime or focusChanged or caretChanged then
			self.focustime = time
		end

		if (time - self.focustime) % self.caretBlinkMs * 2 < self.caretBlinkMs then
			isCaret = true
		end
	end

	self.focused_prev = focused
	self.caret_prev = caret

	linebuffer = {}
	linewidth = 0
	wordbuffer = {}
	wordwidth = 0
	linebuffers = {}
	linewidths = {}

	self.linebuffers = linebuffers
	self.linewidths = linewidths

	local text = self.prefix..widget.typedtext..self.suffix
	local length = text:len()
	for i = 1, length do
		local char = text:sub(i,i)

		if char == "\n" then
			newword()
			newline()
			wordbuffer[#wordbuffer+1] = nullsurface
		else
			local surf = self.surfaceFont:get(char)
			local surfwidth = surf:w() + self.charSpacing

			if self.wrapText then
				if wordwidth + surfwidth >= widget.w then
					newword()
					newline()
				end
			end

			wordbuffer[#wordbuffer+1] = surf
			wordwidth = wordwidth + surfwidth

			if self.wrapText and not self.splitWords then
				if linewidth + wordwidth >= widget.w then
					newline()
				end

				if char == " " then
					newword()
				end
			end
		end
	end

	if #wordbuffer > 0 then
		newword()
	end

	if #linebuffer > 0 then
		newline()
	end

	local x = widget.screenx + widget.decorationx + widget.dx
	local y = widget.screeny + widget.decorationy + widget.dy
	local textheight = #linebuffers * (self.surfaceHeight + self.lineSpacing) - self.lineSpacing
	local coordsByLines = {}
	local coordsByChars = { [0] = { x, y } }

	if self.alignV == "bottom" then
		y = y + widget.h - textheight
	elseif self.alignV == "center" then
		y = y + math.floor(widget.h / 2 - textheight / 2)
	end

	for line = 1, #linebuffers do
		local linebuffer = linebuffers[line]
		local linewidth = linewidths[line]
		coordsByLines[line] = {}

		if self.alignH == "right" then
			x = x + widget.w - linewidth
		elseif self.alignH == "center" then
			x = x + math.floor((widget.w - linewidth) / 2)
		end

		for word = 1, #linebuffer do
			local wordbuffer = linebuffer[word]

			for _, surf in ipairs(wordbuffer) do
				local w = surf:w()
				if w > 0 then
					screen:blit(surf, nil, x, y)
					x = x + w + self.charSpacing
				end

				local coords = { x, y }
				coordsByChars[#coordsByChars + 1] = coords
				coordsByLines[line][#coordsByLines[line] + 1] = coords
			end
		end

		x = widget.screenx + widget.decorationx
		y = y + self.surfaceHeight + self.lineSpacing
	end

	self.coordsByChars = coordsByChars
	self.coordsByLines = coordsByLines

	if isCaret then
		self:drawCaret(screen, self:caretToScreen(caret))
	end
end
