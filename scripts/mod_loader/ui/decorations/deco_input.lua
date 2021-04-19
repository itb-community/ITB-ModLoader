--[[
	A decoration used to display its widget's 'text' field as text,
	within the widget's area. Created mainly for the UiInput Class,
	in order to have text be dynamically created as the text changes.

	The following actions updates the displayed text:
	- edit widget.text
	- edit widget.w
	- edit widget.h
	- call setFont
	- call setTextSettings
	- call setWrapType
	- edit alignH
	- edit alignV
	- edit lineSpacing
	- set rebuild = true

	No wrap is fast enough; word wrap is not fast; char wrap is super
	slow. Everything could probably be improved, but it is serviceable
	for small input fields.
--]]
DecoInput = Class.inherit(UiDeco)
function DecoInput:new(opt)
	UiDeco.new(self)
	opt = opt or {}
	self.font = font or deco.uifont.default.font
	self.textset = textset or deco.uifont.default.set
	self.wrapType = opt.wrapType
	self.alignH = opt.alignH
	self.alignV = opt.alignV
	self.lineSpacing = opt.lineSpacing or 0
	self.surfaces = {}
end

-- finalize text by removing leading and trailing spaces
local function finalizeText(text)
	return text:gsub("^%s",""):gsub("%s$","")
end

local function splitInWords(text)
	local texts = {}
	local i = 1
	for word in text:gmatch("%S*%s*") do
		texts[i] = word
		i = i + 1
	end
	return texts
end

local function splitInChars(text)
	local texts = {}
	local i = 1
	for char in text:gmatch(".") do
		texts[i] = char
		i = i + 1
	end
	return texts
end

function DecoInput:buildSurfaces(words)
	local surfaces = {}
	local text = ""
	local i = 1
	for _, word in ipairs(words) do
		local prev_text = text
		text = text .. word
		local surface = sdl.text(self.font, self.textset, text)
		if prev_text:find("\n") or surface:w() > self.width then
			if surfaces[i] ~= nil then
				-- finalize surface on this line by removing leading and trailing spaces
				surfaces[i] = sdl.text(self.font, self.textset, finalizeText(prev_text))
				-- move to the next line
				text = word
				i = i + 1
			end
		end
		surfaces[i] = surface
	end
	-- finalize surface on final line by removing leading and trailing spaces
	surfaces[i] = sdl.text(self.font, self.textset, finalizeText(text))

	return surfaces
end

function DecoInput:buildTexts()
	self.rebuild = false

	if not self.width or not self.font or not self.textset or not self.text then
		return
	end

	if self.wrapType == "word" or self.wrapType == "char" then
		local text = self.text
		if self.wrapType == "word" then
			text = splitInWords(text)
		else
			text = splitInChars(text)
		end
		self.surfaces = self:buildSurfaces(text)
	else
		self.surfaces = { sdl.text(self.font, self.textset, finalizeText(self.text)) }
	end
end

function DecoInput:setFont(font)
	font = font or deco.uifont.default.font

	if font ~= self.font then
		self.font = font
		self.rebuild = true
	end
end

function DecoInput:setTextSettings(textset)
	textset = textset or deco.uifont.default.set

	if textset ~= self.textset then
		self.textset = textset
		self.rebuild = true
	end
end

function DecoInput:setWrapType(wrapType)
	if wrapType ~= self.wrapType then
		self.wrapType = wrapType
		self.rebuild = true
	end
end

function DecoInput:draw(screen, widget)
	if widget.w ~= self.width or widget.text ~= self.text then
		self.width = widget.w
		self.text = widget.text
		self.rebuild = true
	end

	if self.rebuild then
		self:buildTexts()
	end

	if #self.surfaces == 0 then
		return
	end

	local y = widget.screeny

	if self.alignV == "bottom" then
		y = widget.screeny + widget.h - self.surfaces[1]:h()
	elseif self.alignV == "center" then
		y = widget.screeny + (widget.h - (self.surfaces[1]:h() * #self.surfaces + self.lineSpacing * (#self.surfaces - 1))) / 2
	end

	y = y + widget.decorationy
	for _, surface in ipairs(self.surfaces) do
		local x = widget.screenx

		if self.alignH == "right" then
			x = widget.screenx + widget.w - surface:w()
		elseif self.alignH == "center" then
			x = widget.screenx + (widget.w - surface:w()) / 2
		end

		x = x + widget.decorationx
		screen:blit(surface, nil, x, y)

		if self.alignV == "bottom" then
			y = y - surface:h() - self.lineSpacing
		else
			y = y + surface:h() + self.lineSpacing
		end
	end
end
