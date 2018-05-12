--[[
	A UI widget that wraps long text and correctly handles newlines.
	Caches created sdl.text instances.
--]]
UiWrappedText = Class.inherit(UiBoxLayout)
local debug = false

function UiWrappedText:new(text, font, textset)
	UiBoxLayout.new(self)
	self.childrenCache = {}

	self:vgap(1)

	self.font = font or deco.uifont.default.font
	self.textset = textset or deco.uifont.default.set
	self.textAlign = "left"

	self.text = nil
	self.charWidth = 9.5
	self.lineHeight = 20

	if text then
		self:setText(text)
	end
end

function UiWrappedText:setText(text)
	if self.text == text then return end
	text = text or ""

	assert(type(text) == "string")
	self.text = text
	local allLines = {}

	if self.text and self.text ~= "" then
		local lines = modApi:splitString(text, "\n")
		for i = 1, #lines do
			local wrappedLines = modApi:splitString(self:wrap(lines[i], self.limit), "\n")
			for j = 1, #wrappedLines do
				table.insert(allLines, wrappedLines[j])
			end
		end
	end

	self:rebuild(allLines)
end

--[[
	http://lua-users.org/wiki/StringRecipes , section Text Wrapping
--]]
function UiWrappedText:wrap(str, limit, indent, indent1)
	indent = indent or ""
	indent1 = indent1 or indent
	limit = limit or 72
	local here = 1 - #indent1
	return indent1..str:gsub("(%s+)()(%S+)()", function(sp, st, word, fi)
		if fi-here > limit then
			here = st - #indent
			return "\n"..indent..word
		end
	end)
end

function UiWrappedText:buildText(text)
	local uitext = nil

	local skip = false
	if #self.childrenCache > 0 then
		uitext = table.remove(self.childrenCache)
		uitext.visible = true
	else
		uitext = Ui():decorate({ DecoText(text, self.font, self.textset) })

		if debug then
			uitext.decorations[2] = DecoSolid(sdl.rgba(255, 0, 255, 64))
		end

		skip = true
	end

	local size = self:computeTextSize(text)
	uitext:widthpx(size.w):heightpx(size.h)
	if not skip then uitext.decorations[1]:setsurface(text) end
	uitext.alignH = self.textAlign

	return uitext
end

function UiWrappedText:computeTextSize(text)
	local srf = sdl.text(self.font, self.textset, text)
	return { w = srf:w(), h = srf:h() }
end

function UiWrappedText:rebuild(lines)
	assert(type(lines) == "table")

	for i = #self.children, 1, -1 do
		local child = self.children[i]
		child:detach()
		child.visible = false
		table.insert(self.childrenCache, child)
	end

	for i, line in pairs(lines) do
		self:buildText(line):addTo(self)
	end
end

function UiWrappedText:relayout()
	for i, child in pairs(self.children) do
		local d = child.decorations[1]
		child.alignH = self.textAlign
		d.font = self.font
		d.textset = self.textset
		local size = self:computeTextSize(d.text)
		child:widthpx(size.w):heightpx(size.h)
	end

	UiBoxLayout.relayout(self)
end
