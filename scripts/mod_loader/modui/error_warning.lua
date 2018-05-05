--[[
	Adds a dialog which appears upon entering the Main Menu for the first time,
	if an error occurred while loading mods.
--]]

function showErrorFrame(text)
	sdlext.uiEventLoop(function(ui, quit)
		ui.onclicked = function(self, button)
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

local errorFrameShown = false
sdlext.addMainMenuEnteredHook(function(screen, wasHangar, wasGame)
	if modApi.showErrorFrame then
		if not errorFrameShown then
			errorFrameShown = true

			-- Schedule the error window to be shown instead of showing
			-- it right away.
			-- Prevents a bug where the console keeps scrolling upwards
			-- due to the game not registering return key release event,
			-- when using 'reload' command to reload scripts, and getting
			-- a script error.
			modApi:scheduleHook(20, function()
				-- could show all errors one after another, but let's not...
				for dir, err in pairs(mod_loader.unmountedMods) do
					showErrorFrame(string.format(
						"Unable to mount mod at [%s]:\n%s",
						dir,
						err
					))
					break
				end
				mod_loader.unmountedMods = {}

				if mod_loader.firsterror then
					showErrorFrame(mod_loader.firsterror)
				end
			end)
		end
	end
end)
