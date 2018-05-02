function showErrorFrame(text)
	sdlext.uiEventLoop(function(ui, quit)
		ui.onclicked = function()
			quit()
			return true
		end

		local w = 700
		local h = 400
		local frame = Ui()
			:widthpx(w):heightpx(h)
			:pospx((ui.w - w)/2, (ui.h - h)/2)
			:caption("Error")
			:decorate({ DecoFrame(), DecoFrameCaption() })
			:addTo(ui)

		local scroll = UiScrollArea()
			:width(1):height(1)
			:padding(10)
			:decorate({ DecoSolid() })
			:addTo(frame)

		text = text or "Some mods failed to load. Check console for details."
		UiWrappedText(text)
			:width(1)
			:addTo(scroll)
	end)
end
