--[[
	A decoration used to display its widget's 'text' field as text,
	within the widget's area. Created mainly for the UiInput Class,
	in order to have text be dynamically created as the text changes.

	The following actions rebuilds the text:
	- edit widget.text
	- edit widget.w
	- edit widget.h
	- call setFont
	- call setTextSettings
	- call setWrapText
	- call setSplitWords
	- call setPrefix
	- call setSuffix
	- set rebuild = true

	The following actions updates the
	displayed text without having to rebuild:
	- edit alignH
	- edit alignV
	- edit lineSpacing
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

DecoInput = Class.inherit(UiDeco)
function DecoInput:new(opt)
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
	self.lineSpacing = opt.lineSpacing or 0
	self.markerBlinkMs = opt.markerBlinkMs or 600
	self.rect = sdl.rect(0,0,0,0)
	self.lines = {}
	updateFont(self)
end

function DecoInput:buildLines()
	self.rebuild = false

	if not self.width or not self.font or not self.textset or not self.text then
		return
	end

	local text = self.prefix .. self.text .. self.suffix
	local length = text:len()
	local lines = {}
	local word = {w = 0}
	local line = {w = 0, c_w = 0}

	local function commit(char)
		word.w = word.w + char:w()
		table.insert(word, char)
	end

	local function newword()
		line.w = line.w + word.w
		for _, char in ipairs(word) do
			table.insert(line, char)
		end
		word = {w = 0}
	end

	local function newline()
		table.insert(lines, line)
		line = {w = 0, c_w = 0}
	end

	for i = 1, length do
		local str = text:sub(i,i)
		local char_is_space = str:match("%s")
		local char_is_enter = str:match("\n")
		local char = self.surfaceFont:get(str)

		if char_is_enter then
			newword()
			newline()
		else
			if self.wrapText and line.w + word.w + char:w() > self.width then
				if line.w == 0 then
					newword()
				end
				newline()
			end

			if self.wrapText and self.splitWords then
				line.w = line.w + char:w()
				table.insert(line, char)
			else
				if char_is_space then
					newword()
				end

				commit(char)
			end
		end

		if i == length then
			newword()
			newline()
		end
	end

	self.lines = lines
end

function DecoInput:setFont(font)
	font = font or deco.uifont.default.font

	if font ~= self.font then
		self.font = font
		updateFont(self)
		self.rebuild = true
	end
end

function DecoInput:setTextSettings(textset)
	textset = textset or deco.uifont.default.set

	if textset ~= self.textset then
		self.textset = textset
		updateFont(self)
		self.rebuild = true
	end
end

function DecoInput:setWrapText(wrapText)
	if wrapText ~= self.wrapText then
		self.wrapText = wrapText
		self.rebuild = true
	end
end

function DecoInput:setSplitWords(splitWords)
	if splitWords ~= self.splitWords then
		self.splitWords = splitWords
		self.rebuild = true
	end
end

function DecoInput:setPrefix(prefix)
	if prefix ~= self.prefix then
		self.prefix = prefix or ""
		self.rebuild = true
	end
end

function DecoInput:setSuffix(suffix)
	if suffix ~= self.suffix then
		self.suffix = suffix or ""
		self.rebuild = true
	end
end

function DecoInput:draw(screen, widget)
	if widget.typedtext ~= self.text then
		self.text = widget.typedtext
		self.rebuild = true
	end

	if widget.w ~= self.width then
		self.width = widget.w
		self.rebuild = true
	end

	self.wasfocused = self.focused
	self.focused = widget.focused

	if self.rebuild then
		self:buildLines()
	end

	local x = widget.screenx + widget.decorationx
	local y = widget.screeny + widget.decorationy
	local textHeight = self.surfaceHeight

	if #self.lines > 1 then
		textHeight = textHeight + (#self.lines - 1) * (self.surfaceHeight + self.lineSpacing)
	end

	if self.alignV == "bottom" then
		y = y + widget.h - textHeight
	elseif self.alignV == "center" then
		y = y + math.floor(widget.h / 2 - textHeight / 2)
	end

	if self.alignH == "right" then
		x = x + widget.w - 1
	elseif self.alignH == "center" then
		x = x + math.floor(widget.w / 2)
	end

	for l, line in ipairs(self.lines) do
		x = widget.screenx + widget.decorationx

		if self.alignH == "right" then
			x = x + widget.w - line.w - 1
		elseif self.alignH == "center" then
			x = x + math.floor(widget.w / 2 - line.w / 2)
		end

		for c, char in ipairs(line) do
			screen:blit(char, nil, x, y)
			x = x + char:w()
		end

		if l ~= #self.lines then
			y = y + self.surfaceHeight + self.lineSpacing
		end
	end

	if self.focused then
		local time = os.clock() * 1000 % self.markerBlinkMs

		if not self.wasfocused or not self.focustime then
			self.focustime = time
		end

		if (time - self.focustime) % self.markerBlinkMs * 2 < self.markerBlinkMs then
			self.rect.x = x
			self.rect.y = y
			self.rect.w = 1
			self.rect.h = self.surfaceHeight
			screen:drawrect(self.textset.color, self.rect)
		end
	end
end
