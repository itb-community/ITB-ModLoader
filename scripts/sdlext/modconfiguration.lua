local function saveModConfig()
	sdlext.config("modcontent.lua",function(obj)
		obj.modOptions = mod_loader:getCurrentModContent()
		obj.modOrder = mod_loader:getCurrentModOrder()
	end)
end

function configureMods()
	loadSquadSelection()
	
	local checkboxes = {}
	local configboxes = {}
	local optionboxes = {}
	local mod_options = mod_loader.mod_options
	local modSelection = mod_loader:getModConfig()
	
	sdlext.uiEventLoop(function(ui,quit)
		ui.onclicked = function()
			quit()
			return true
		end

		local frametop = Ui():width(0.6):height(0.575):pos(0.2,0.1):caption("Mod Configuration"):decorate({DecoFrame(), DecoSolid(sdl.rgb(73,92,121)), DecoFrameCaption()}):addTo(ui)
		local scrollarea = UiScrollArea():width(1):height(1):padding(12):decorate({DecoSolid(sdl.rgb(24,28,40))})
		frametop:add(scrollarea)
		ui:relayout()
		
		local pos=0
		local configuringMod = nil
		
		local function clickConfiguration(button)
			if configuringMod then
				local numOptions = #optionboxes[configuringMod]
				
				for i = configuringMod + 1, #checkboxes do
					checkboxes[i].y = checkboxes[i].y - (numOptions * 46)
					if configboxes[i] then
						configboxes[i].y = configboxes[i].y - (numOptions * 46)
					end
				end
				
				for i, optionbox in pairs(optionboxes[configuringMod]) do
					optionbox:hide()
				end
				
				configboxes[configuringMod].decorations[2].surface = sdl.surface("resources/mods/ui/config-unchecked.png")
			end
			
			if button.configi == configuringMod then
				configuringMod = nil
			else
				configuringMod = button.configi
				local numOptions = #optionboxes[configuringMod]
				
				for i = configuringMod + 1, #checkboxes do
					checkboxes[i].y = checkboxes[i].y + (numOptions * 46)
					if configboxes[i] then
						configboxes[i].y = configboxes[i].y + (numOptions * 46)
					end
				end
				configboxes[configuringMod].decorations[2].surface = sdl.surface("resources/mods/ui/config-checked.png")
				
				for i, optionbox in pairs(optionboxes[configuringMod]) do
					optionbox:show()
				end
			end
			
			scrollarea:relayout()
			return true
		end
		
		for id, option in pairs(mod_options) do
				if mod_loader:hasMod(id) then
				local mod = mod_loader.mods[id]
				
				if #option.options > 0 then
					local checkbox = UiCheckbox():pospx(0, pos):heightpx(41):widthpx((scrollarea.w - scrollarea.padl - scrollarea.padr) - 43):decorate(
						{ DecoButton(), DecoCheckbox(), DecoSurfaceOutlined(sdlext.surface(mod.icon or "resources/mods/squads/unknown.png"),nil,nil,nil,1), DecoText(mod.name) }
					)
					
					checkbox.modId = id
					checkbox.checked = modSelection[id].enabled
					
					scrollarea:add( checkbox )
					table.insert(checkboxes, checkbox)
					
					local configbox = UiCheckbox():pospx((scrollarea.w - scrollarea.padl - scrollarea.padr) - 41, pos):heightpx(41):widthpx(41):decorate(
						{ DecoButton(), DecoSurface(sdl.surface("resources/mods/ui/config-unchecked.png")) }
					)
					
					configbox.configi = #checkboxes
					configbox.onclicked = clickConfiguration
					configboxes[configbox.configi] = configbox
					scrollarea:add( configbox )
					optionboxes[configbox.configi] = {}
					for i, opt in ipairs(option.options) do
						local optionbox
						
						if opt.check then
							optionbox = UiCheckbox():pospx(43, pos + i * 46):heightpx(41):widthpx((scrollarea.w - scrollarea.padl - scrollarea.padr) - 41):settooltip(opt.tip):decorate(
								{ DecoButton(), DecoText(opt.name), DecoRAlign(43), DecoCheckbox() }
							)
							
							optionbox.checked = modSelection[id].options[opt.id].enabled
						else
							local value = modSelection[id].options[opt.id].value
							optionbox = UiDropDown(opt.values,opt.strings,value):pospx(43, pos + i * 46):heightpx(41):widthpx((scrollarea.w - scrollarea.padl - scrollarea.padr) - 41):settooltip(opt.tip):decorate(
								{ DecoButton(), DecoText(opt.name), DecoDropDownText(nil,nil,nil,43), DecoDropDown() }
							)
						end
						
						optionbox.data = opt
						
						optionbox:hide()
						scrollarea:add( optionbox )
						table.insert(optionboxes[configbox.configi],optionbox)
					end
				else	
					local checkbox = UiCheckbox():pospx(0, pos):heightpx(41):width(1):decorate(
						{ DecoButton(), DecoCheckbox(), DecoSurfaceOutlined(sdlext.surface(mod.icon or "resources/mods/squads/unknown.png"),nil,nil,nil,1), DecoText(mod.name) }
					)
					
					checkbox.checked = modSelection[id].enabled
					
					checkbox.modId = id
					
					scrollarea:add( checkbox )
					table.insert(checkboxes, checkbox)
				end
				
				pos = pos + 46
			end
		end
	end)
	
	modSelection = {}
	
	for i, checkbox in ipairs(checkboxes) do
		local options = {}
		modSelection[checkbox.modId] = {
			enabled = checkbox.checked,
			options = options,
			version = mod_options[checkbox.modId].version,
		}
		
		if optionboxes[i] and checkbox.checked then
			for j, option in ipairs(optionboxes[i]) do
				if option.data.check then
					options[option.data.id] = {enabled = option.checked}
				else
					options[option.data.id] = {value = option.value}
				end
			end
		end
	end
	
	local savedOrder = {}--TODO
	mod_loader:loadModContent(modSelection,savedOrder)
	
	saveModConfig()
end