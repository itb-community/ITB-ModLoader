
local COLOR_GREEN = sdl.rgb(64, 196, 64)
local COLOR_YELLOW = sdl.rgb(192, 192, 64)
local COLOR_RED = sdl.rgb(192, 32, 32)
local TEXT_SET_STAT = deco.textset(deco.colors.buttonborder, nil, nil, true)

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

local function decoTextStat(text)
	return DecoText(text, deco.uifont.tooltipText.font, TEXT_SET_STAT)
end

local function decoRAlignedTextStat(text)
	return DecoRAlignedText(text, deco.uifont.tooltipText.font, TEXT_SET_STAT)
end

local function disableMemeditMods()
	local modConfiguration = modApi:getCurrentModConfiguration()

	sdlext.config(
		modApi:getCurrentModcontentPath(),
		function(obj)
			for modId, modOptions in pairs(obj.modOptions) do
				local mod = mod_loader.mods[modId]
				if true
					and mod
					and mod.extensions
					and list_contains(mod.extensions, "memedit")
				then
					-- Update cache
					modConfiguration[modId].enabled = false
					-- Update file
					modOptions.enabled = false

					-- TODO:
					-- After merging #163: "feature-failed-mod-popup"
					-- we can also disable mods that have dependency
					-- on the mods we disabled, by checking each mod's
					-- mod.dependency table.
				end
			end
		end
	)

	sdlext.showButtonDialog(
		GetText("Memedit_Popup_Disable_FrameTitle"),
		GetText("Memedit_Popup_Disable_FrameText"),
		responseFn,
		{ GetText("Button_Ok") },
		{ "" }
	)
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

	-- STATS
	--------

	local stats_holder = Ui()
		:width(1):heightpx(40)
		:addTo(innerFrame)

	local stats_padding = 10
	local stats_num_width = 40
	local stats = UiBoxLayout()
		:height(1) -- adjust width later
		:anchorH("right")
		:hgap(stats_padding)
		:addTo(stats_holder)

	local stat_total_text = Ui()
		:height(1) -- adjust width later
		:decorate{ decoTextStat(GetText("Memedit_Stats_Scans")) }
		:addTo(stats)

	local stat_succeeded_text = Ui()
		:height(1) -- adjust width later
		:decorate{ decoTextStat(GetText("Memedit_Stats_Succeeded")) }
		:addTo(stats)

	local stat_failed_text = Ui()
		:height(1) -- adjust width later
		:decorate{ decoTextStat(GetText("Memedit_Stats_Failed")) }
		:addTo(stats)

	stat_total_text:widthpx(stat_total_text.decorations[1].surface:w() + stats_num_width)
	stat_succeeded_text:widthpx(stat_succeeded_text.decorations[1].surface:w() + stats_num_width)
	stat_failed_text:widthpx(stat_failed_text.decorations[1].surface:w() + stats_num_width)
	stats:widthpx(stat_total_text.w + stat_succeeded_text.w + stat_failed_text.w + stats_padding * 2)

	local stat_total_num = Ui()
		:widthpx(stats_num_width):height(1)
		:anchorH("right")
		:decorate{ decoRAlignedTextStat() }
		:addTo(stat_total_text)

	local stat_succeeded_num = Ui()
		:widthpx(stats_num_width):height(1)
		:anchorH("right")
		:decorate{ decoRAlignedTextStat() }
		:addTo(stat_succeeded_text)

	local stat_failed_num = Ui()
		:widthpx(stats_num_width):height(1)
		:anchorH("right")
		:decorate{ decoRAlignedTextStat() }
		:addTo(stat_failed_text)

	function stat_total_num:relayout()
		local total = 0
			+ #memedit.scanner.scans_succeeded
			+ #memedit.scanner.scans_queued
			+ #memedit.scanner.scans_blocked
			+ #memedit.scanner.scans_failed

		self.decorations[1]:setsurface(tostring(total))
		Ui.relayout(self)
	end

	function stat_succeeded_num:relayout()
		local succeeded = #memedit.scanner.scans_succeeded

		if succeeded > 0 then
			self.decorations[1]:setcolor(COLOR_GREEN)
		else
			self.decorations[1]:setcolor(deco.colors.buttonborder)
		end

		self.decorations[1]:setsurface(tostring(succeeded))
		Ui.relayout(self)
	end

	function stat_failed_num:relayout()
		local failed = #memedit.scanner.scans_failed

		if failed > 0 then
			self.decorations[1]:setcolor(COLOR_RED)
		else
			self.decorations[1]:setcolor(deco.colors.buttonborder)
		end

		self.decorations[1]:setsurface(tostring(failed))
		Ui.relayout(self)
	end

	-- BUTTONS
	----------

	Ui():width(1):heightpx(2)
		:decorate{DecoSolid(deco.colors.buttonborder)}
		:addTo(innerFrame)

	local buttons = Ui()
		:width(1):heightpx(60)
		:addTo(innerFrame)

	local button_main = Ui()
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

	local button_disable = Ui()
		:widthpx(100):heightpx(41)
		:anchor("right", "center")
		:decorate{
			DecoButton(),
			DecoAnchor(),
			DecoCAlignedText(
				GetText("Memedit_Button_Disable"),
				deco.uifont.tooltipTitleLarge.font,
				deco.uifont.tooltipTitleLarge.set
			)
		}
		:settooltip(GetText("Memedit_ButtonTooltip_Disable"))
		:addTo(buttons)

	function button_main:relayout()
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

	function button_main:onclicked(button)
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

	function button_disable:onclicked(button)
		if button == 1 then
			memedit.scanner:stop()
			disableMemeditMods()
			frame:detach()
		end

		return true
	end

	-- TEXT BOX
	-----------

	local textbox = UiWrappedText(
			nil,
			deco.uifont.tooltipTextLarge.font,
			deco.uifont.tooltipTextLarge.set
		)
		:width(1):height(1)
		:addTo(scrollarea)

	textbox.pixelWrap = true

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

	-- CURRENT SCAN
	---------------

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

	WIDTH_CURRENT = 0.40
	WIDTHPX_ITERATION = 40
	WIDTHPX_RESULTS = 80
	WIDTH_INSTRUCTIONS = 0.60

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
				local results = tostring(scan:getResultCount())
				self.content_current.decorations[2]:setsurface(scan.name)
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
