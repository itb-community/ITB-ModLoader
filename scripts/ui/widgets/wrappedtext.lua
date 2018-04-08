--[[
	A UI widget that wraps long text and correctly handles newlines.
	Caches created sdl.text instances.
--]]
UiWrappedText = Class.inherit(UiBoxLayout)

function UiWrappedText:new(text, font, textset)
	UiBoxLayout.new(self)
	self.childrenCache = {}

	self:vgap(1)

	local defaultTextSet = function()
		local res = sdl.textsettings()
		res.antialias = false
		res.color = sdl.rgb(255, 255, 255)
		res.outlineColor = res.color
		res.outlineWidth = 0
		return res
	end

	self.font = font or sdlext.font("fonts/JustinFont12Bold.ttf", 12)
	self.textset = textset or defaultTextSet()
	self.textAlign = "left"

	self.text = nil
	self:setText(text)
end

function UiWrappedText:setText(text)
	if self.text == text then return end
	text = text or ""

	assert(type(text) == "string")
	self.text = text

	local lines = modApi:splitString(text, "\n")
	local allLines = {}
	for i = 1, #lines do
		local wrappedLines = modApi:splitString(self:wrap(lines[i], self.limit), "\n")
		for j = 1, #wrappedLines do
			table.insert(allLines, wrappedLines[j])
		end
	end

	self:rebuild(allLines)
end

--[[
	http://lua-users.org/wiki/StringRecipes , section Text Wrapping
]]--
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
		skip = true
	end

	-- TODO: Need a way to find out character height and width.
	-- For now, hardcode them.
	uitext:widthpx(9.5 * string.len(text)):heightpx(20)
	if not skip then uitext.decorations[1]:setsurface(text) end
	uitext.alignH = self.textAlign

	return uitext
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
		child.alignH = self.textAlign
		child.decorations[1].font = self.font
		child.decorations[1].textset = self.textset
	end

	UiBoxLayout.relayout(self)
end
