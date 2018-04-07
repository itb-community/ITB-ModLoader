UiTooltip = Class.inherit(Ui)

function UiTooltip:new()
	Ui.new(self)
	
	self.translucent = true
	self.tooltip_w_base = 20
	self.tooltip_h_base = 20
	self.tooltip_h_line = 22
	self.linelenmax = 30
end

function UiTooltip:draw(screen)
	self:updateTooltip()
	
	local x = sdl.mouse.x()
	local y = sdl.mouse.y()
	if x <= screen:w() / 2 then
		self.x = x
	else
		self.x = x - self.w
	end
	
	if y <= screen:h() / 2 then
		self.y = y
	else
		self.y = y - self.h
	end
	
	self.screenx = self.x
	self.screeny = self.y
	self:relayout()
		
	Ui.draw(self,screen)
end

function UiTooltip:updateTooltip()
	if self.tooltip ~= self.root.tooltip then
		self.tooltip = self.root.tooltip
		self.children = {}
		if self.tooltip and self.tooltip:len() > 0 then
			local lines = modApi:splitString(self.tooltip,"\n")
			for i = 1, #lines do
				lines[i] = modApi:splitString(lines[i],"%s")
			end
			local newlines = {}
			for i = 1, #lines do
				local linelen = 0
				local newline = {}
				
				for j, word in ipairs(lines[i]) do
					--TODO: Check for width on screen in pixels instead of number of characters
					if #newline > 0 and word:len() + linelen > self.linelenmax then
						linelen = 0
						table.insert(newlines,newline)
						newline = {}
					end
					
					if #newline > 0 then
						table.insert(newline," ")
					end
					table.insert(newline,word)
					linelen = linelen + 1 + word:len()
				end
				if #newline > 0 then
					table.insert(newlines,newline)
				end
			end
			
			local texts = {}
			local tooltip_w = self.tooltip_w_base
			local tooltip_h = self.tooltip_h_base + #newlines * self.tooltip_h_line
			
			for i, line in ipairs(newlines) do
				local text = DecoText(table.concat(line),sdlext.font("fonts/JustinFont12Bold.ttf",12))
				tooltip_w = math.max(tooltip_w,self.tooltip_w_base + text.surface:w())
				table.insert(texts,text)
			end
			self.w = tooltip_w
			self.h = tooltip_h
			for i, text in ipairs(texts) do
				self:add(Ui():pospx(10,(i - 0.5 - #texts / 2) * 22):width(1):height(1):decorate({text}))
			end
			
			self:add(Ui():width(1):height(1):decorate({DecoFrame(sdl.rgba(0,0,0,127),sdl.rgb(255,255,255))}))
		end
	end
end