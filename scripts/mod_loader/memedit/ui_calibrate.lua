
local COLOR_GREEN = sdl.rgb(64, 196, 64)
local COLOR_YELLOW = sdl.rgb(192, 192, 64)
local COLOR_RED = sdl.rgb(192, 32, 32)
local MARK_TICK = deco.surfaces.markTick
local MARK_CROSS = deco.surfaces.markCross
local TEXT_SET_GREEN = deco.textset(COLOR_GREEN)
local TEXT_SET_YELLOW = deco.textset(COLOR_YELLOW)
local TEXT_SET_RED = deco.textset(COLOR_RED)

local function formatGetText(textId, ...)
	return string.format(GetText(textId), ...)
end

local rect = sdl.rect(0,0,0,0)
local decoPaddedSolid = DecoSolid(deco.colors.framebg)
function decoPaddedSolid:draw(screen, widget)
	rect.x = widget.rect.x + widget.padl
	rect.y = widget.rect.y + widget.padt
	rect.w = widget.rect.w - widget.padl - widget.padr
	rect.h = widget.rect.h - widget.padt - widget.padb

	screen:drawrect(self.color, rect)
end

local function createUi(screen, uiRoot)
	local memedit = modApi.memedit

	local frame = Ui()
		:widthpx(900):heightpx(300)
		:caption(GetText("Memedit_FrameTitle"))
		:registerDragMove()
		:padding(5)
		:decorate{
			DecoFrameHeader(),
			DecoFrame(),
		}
		:addTo(uiRoot)

	local innerFrame = UiWeightLayout()
		:width(1):height(1):vgap(0):hgap(0)
		:orientation(modApi.constants.ORIENTATION_VERTICAL)
		:addTo(frame)

	local scrollarea = UiScrollArea()
		:width(1):height(1)
		:padding(10)
		:addTo(innerFrame)

	local buttons = Ui()
		:width(1):heightpx(2)
		:decorate{DecoSolid(deco.colors.buttonborder)}
		:addTo(innerFrame)

	local buttons = Ui()
		:width(1):heightpx(60)
		:addTo(innerFrame)

	local textbox = UiWrappedText(
			nil,
			deco.uifont.tooltipTextLarge.font,
			deco.uifont.tooltipTextLarge.set
		)
		:width(1):height(1)
		:addTo(scrollarea)

	textbox.pixelWrap = true

	local button = Ui()
		:widthpx(100):heightpx(41)
		:anchor("center", "center")
		:decorate{
			DecoButton(),
			DecoAnchor(),
			DecoCAlignedText(
				nil,
				deco.uifont.tooltipTitleLarge.font,
				deco.uifont.tooltipTitleLarge.set
			)
		}
		:addTo(buttons)

	function button:relayout()
		if memedit.failed then
			self.decorations[3]:setsurface(GetText("Memedit_Button_Retry"))
			self:settooltip(GetText("Memedit_ButtonTooltip_Retry"))
		elseif memedit.calibrated then
			self.decorations[3]:setsurface(GetText("Memedit_Button_Close"))
			self:settooltip(GetText("Memedit_ButtonTooltip_Close"))
		elseif memedit.calibrating then
			self.decorations[3]:setsurface(GetText("Memedit_Button_Stop"))
			self:settooltip(GetText("Memedit_ButtonTooltip_Stop"))
		else
			self.decorations[3]:setsurface(GetText("Memedit_Button_Start"))
			self:settooltip(GetText("Memedit_ButtonTooltip_Start"))
		end

		Ui.relayout(self)
	end

	function button:onclicked(button)
		if button == 1 then
			if memedit.failed then
				memedit:recalibrate()
			elseif memedit.calibrated then
				frame:detach()
			elseif memedit.calibrating then
				memedit.scanner:stop()
			else
				memedit:recalibrate()
			end
		end

		return true
	end

	function textbox:updateText()
		local mods = mod_loader.mods
		local memeditMods = {}
		local textId

		for modId, mod in pairs(mods) do
			local extensions = mod.extensions

			if extensions and list_contains(extensions, "memedit") then
				table.insert(memeditMods, string.format("- [%s] with id [%s]", mod.name, modId))
			end
		end

		if memedit.failed then
			textId = "Memedit_Text_Failed"
		elseif memedit.calibrated then
			textId = "Memedit_Text_Success"
		else
			textId = "Memedit_Text_Initial"
		end

		self:setText(formatGetText(textId, table.concat(memeditMods, ", ")))
	end

	function textbox:relayout()
		if memedit.calibrating then
			self.visible = false
		else
			self.visible = true
			self:updateText()
		end

		UiWrappedText.relayout(self)
	end

	local scan_holder = Ui()
		:width(1):height(1)
		:hide()
		:addTo(scrollarea)

	function scan_holder:relayout()
		if memedit.calibrating then
			self.visible = true
		else
			self.visible = false
		end

		Ui.relayout(self)
	end

	local scan_row = UiWeightLayout()
		:width(1):heightpx(100):vgap(0):hgap(0)
		:orientation(modApi.constants.ORIENTATION_VERTICAL)
		:padding(-1)
		:decorate{ DecoSolid(deco.colors.buttonborder) }
		:addTo(scan_holder)

	local scan_titles = UiWeightLayout()
		:width(1):height(0.5):vgap(0):hgap(0)
		:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
		:addTo(scan_row)

	local scan_content = UiWeightLayout()
		:width(1):height(0.5):vgap(0):hgap(0)
		:orientation(modApi.constants.ORIENTATION_HORIZONTAL)
		:addTo(scan_row)

	WIDTH_CURRENT = 0.3
	WIDTHPX_ITERATION = 40
	WIDTHPX_RESULTS = 80
	WIDTH_INSTRUCTIONS = 0.6

	local title_current = Ui()
		:width(WIDTH_CURRENT):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText(GetText("Memedit_Title_CurrentScan"))
		}
		:addTo(scan_titles)

	local title_iteration = Ui()
		:widthpx(WIDTHPX_ITERATION):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText(GetText("Memedit_Title_Iteration"))
		}
		:addTo(scan_titles)

	local title_results = Ui()
		:widthpx(WIDTHPX_RESULTS):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText(GetText("Memedit_Title_Results"))
		}
		:addTo(scan_titles)

	local title_instructions = Ui()
		:width(WIDTH_INSTRUCTIONS):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText(GetText("Memedit_Title_Instructions"))
		}
		:addTo(scan_titles)

	local content_current = Ui()
		:width(WIDTH_CURRENT):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText()
		}
		:addTo(scan_content)

	local content_iteration = Ui()
		:widthpx(WIDTHPX_ITERATION):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText()
		}
		:addTo(scan_content)

	local content_results = Ui()
		:widthpx(WIDTHPX_RESULTS):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText()
		}
		:addTo(scan_content)

	local content_instructions = Ui()
		:width(WIDTH_INSTRUCTIONS):height(1)
		:padding(1)
		:decorate{
			decoPaddedSolid,
			DecoText()
		}
		:addTo(scan_content)

	scan_content.content_current = content_current
	scan_content.content_iteration = content_iteration
	scan_content.content_results = content_results
	scan_content.content_instructions = content_instructions

	function scan_content:relayout()
		local scanner = memedit.scanner
		if scanner.status == scanner.STATUS_RUNNING then
			local scan = scanner.currentScan
			if scan then
				local results = scan:getResultString()
				if results ~= "N/A" then results = results:match("%x") end
				self.content_current.decorations[2]:setsurface(scan.questName)
				self.content_iteration.decorations[2]:setsurface(scan.iteration)
				self.content_results.decorations[2]:setsurface(results)
				self.content_instructions.decorations[2]:setsurface(scan.issue or "Wait...")
			end
		end

		UiWeightLayout.relayout(self)
	end
end

local function requestUi()
	local uiRoot = sdlext.getUiRoot()
	if uiRoot then
		createUi(sdl.screen(), uiRoot)
	else
		modApi.events.onUiRootCreated:subscribe(createUi)
	end
end

return requestUi
