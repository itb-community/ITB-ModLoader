DecoTextbox = Class.inherit(DecoText)
function DecoTextbox:new(t)
	t = t or {}
	assert(type(t) == "table", "Argument #1 must be a table")

	DecoText.new(self, t.text, t.font, t.textset)

	self.caret = sdl.text(self.font, self.textset, "A")

	self.caretcolor = t.caretcolor or deco.colors.white
	self.caretwidth = t.caretwidth or 2
	self.caretheight = self.caret:h()
	self.caretpos = 0

	self.selectioncolor = t.selectioncolor or deco.colors.debugMagenta -- TODO

	self.rect = sdl.rect(0,0,0,0)

	self.onCaretPositionChanged = nil
	self.onTextChanged = nil
end

function DecoTextbox:isCaretVisible()
	return self.caretwidth > 0 and self.caretheight > 0
end

function DecoTextbox:updateCaret(widget)
	if self:isCaretVisible() then
		self.caret = sdl.text(self.font, self.textset, widget.text:sub(0, widget.textBuffer.caretPosition))
		self.caretpos = self.caret:w()

		-- JustinFont has some weird issues causing the sdl.surface to report
		-- slightly bigger width than it should have. Correct for this.
		local offset = math.floor(0.025 * self.caretpos)
		self.caretpos = self.caretpos - offset
	end
end

function DecoTextbox:draw(screen, widget)
	if not self.onCaretPositionChanged and not self.onTextChanged then
		self.onCaretPositionChanged = widget.onCaretPositionChanged:subscribe(function()
			self:updateCaret(widget)
		end)
	end

	if widget:hasSelection() then
		-- TODO
	end

	if self:isCaretVisible() then
		self.rect.x = widget.rect.x + self.caretpos
		self.rect.y = widget.rect.y
		self.rect.w = self.caretwidth
		self.rect.h = self.caretheight
		screen:drawrect(self.caretcolor, self.rect)
	end

	DecoText.draw(self, screen, widget)
end



