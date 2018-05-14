--[[
	A UI widget that wraps long text and correctly handles newlines.
	Caches created sdl.text instances.
--]]
UiWrappedText = Class.inherit(UiBoxLayout)

function UiWrappedText:new(text, font, textset)
	UiBoxLayout.new(self)
	self.childrenCache = {}

	self:vgap(1)

	self.font = font or deco.uifont.default.font
	self.textset = textset or deco.uifont.default.set
	self.textAlign = "left"

	self.text = nil

	if text then
		self:setText(text)
	end
end

function UiWrappedText:computeTextSize(text)
	if type(text) == "string" then
		local srf = sdl.text(self.font, self.textset, text)
		local t = { w = srf:w(), h = srf:h() }
		srf = nil

		return t
	elseif type(text) == "userdata" then
		return { w = text:w(), h = text:h() }
	end
end

local function buildText(self, text)
	if text == "" then text = " " end

	local uitext = nil

	local skip = false
	if #self.childrenCache > 0 then
		uitext = table.remove(self.childrenCache)
		uitext.visible = true
	else
		uitext = Ui():decorate({ DecoText(text, self.font, self.textset) })

		skip = true
	end

	local size = self:computeTextSize(text)
	uitext:widthpx(size.w):heightpx(size.h)
	if not skip then uitext.decorations[1]:setsurface(text) end
	uitext.alignH = self.textAlign

	return uitext
end

local function rebuild(self, lines)
	assert(type(lines) == "table")

	for i = #self.children, 1, -1 do
		local child = self.children[i]
		child:detach()
		child.visible = false
		table.insert(self.childrenCache, child)
	end

	for i, line in pairs(lines) do
		buildText(self, line):addTo(self)
	end
end

--[[
	http://lua-users.org/wiki/StringRecipes , section Text Wrapping
--]]
local function wrap(self, str, limit, indent, indent1)
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 72
	local here = 1 - #indent1
	return indent1..str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
		if fi - here > limit then
			here = st - #indent
			return "\n"..indent..word
		end
	end)
end

function UiWrappedText:setText(text)
	if self.text == text then return end
	text = text or ""

	assert(type(text) == "string")
	self.text = text
	local allLines = {}

	if self.text and self.text ~= "" then
		local lines = modApi:splitStringEmpty(text, "\n")
		for i = 1, #lines do
			local wrappedLines = modApi:splitStringEmpty(wrap(self, lines[i], self.limit), "\n")
			for j = 1, #wrappedLines do
				table.insert(allLines, wrappedLines[j])
			end
		end
	end

	rebuild(self, allLines)
end

function UiWrappedText:relayout()
	for i, child in pairs(self.children) do
		local d = child.decorations[1]
		child.alignH = self.textAlign
		if d.font ~= self.font or d.textset ~= self.textset then
			d.font = self.font
			d.textset = self.textset
			d.surface = sdl.text(d.font, d.textset, d.text)
			child:widthpx(d.surface:w()):heightpx(d.surface:h())
		end
	end

	UiBoxLayout.relayout(self)
end
