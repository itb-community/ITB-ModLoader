local maxselected = 8

local function saveSquadSelection()
	local selected = {}
	for i=1,maxselected do
		local index = modApi.squadIndices[i]
		local name = modApi.squad_text[(index-1)*2+1]
		selected[i] = name
	end
	
	sdlext.config("modcontent.lua",function(obj)
		obj.selectedSquads = selected
	end)
end

function loadSquadSelection()
	local map = {}
	
	for i=1,#modApi.squad_icon do
		local name = modApi.squad_text[(i-1)*2+1]
		map[name] = i
	end

	modApi.squadIndices = {}
	sdlext.config("modcontent.lua",function(obj)
		if not obj.selectedSquads then return end
		
		for i=1,maxselected do
			local name = obj.selectedSquads[i]
			local index = map[name]
			if index ~= nil then
				modApi.squadIndices[i] = index
			end
		end
	end)
	
	for i=1,maxselected do
		if modApi.squadIndices[i] == nil then
			modApi.squadIndices[i] = i
		end
	end
end

local largefont = sdlext.font("fonts/NunitoSans_Bold.ttf",44)
local squadPalettes = sdlext.squadPalettes()
function selectSquads()
	loadSquadSelection()
	
	local checkboxes = {}
	
	sdlext.uiEventLoop(function(ui,quit)
		ui.onclicked = function()
			quit()
		end

		local labelcount = Ui():pos(0.71,0.83):width(0.3):height(0.075):caption(""):decorate({DecoCaption(largefont)}):addTo(ui)
		Ui():pos(0.7,0.925):width(0.3):height(0.05):caption("Total selected"):decorate({DecoCaption()}):addTo(ui)

		local frametop = Ui():width(0.6):height(0.7):pos(0.2,0.1):caption("Choose squads"):decorate({DecoFrame(), DecoFrameCaption()}):addTo(ui)
		local scrollarea = UiScrollArea():width(1):height(1):padding(24):decorate({DecoSolid(sdl.rgb(24,28,40))})
		frametop:add(scrollarea)
		
		local updatecount = function()
			local count = 0
			
			for i=1,#checkboxes do
				local checkbox = checkboxes[i]
				if checkbox.checked then count=count+1 end
			end
			
			labelcount:caption(count.."/"..maxselected)
		end
		
		for i=1,#modApi.mod_squads do
			local col = (i-1) % 2
			local row = math.floor((i-1) / 2)
			
			local surface = sdlext.surface(modApi.squad_icon[i] or "")
			
			if i>1 and i<=8 then
				local colorTable = {}
				for j=1,#squadPalettes[1] do
					colorTable[(j-1)*2 + 1] = squadPalettes[1][j]
					colorTable[(j-1)*2 + 2] = squadPalettes[i][j]
				end
				
				surface = sdl.colormapped(surface, colorTable)
			end
			
			local checkbox = UiCheckbox():pos(0.5*col,0):setypx(80*row):heightpx(41):width(0.48):settooltip(modApi.squad_text[i*2]):decorate(
				{ DecoButton(), DecoCheckbox(), DecoSurfaceOutlined(surface), DecoText(modApi.squad_text[i*2-1]) }
			)
			
			scrollarea:add( checkbox )
			
			checkbox.onclicked = function()
				updatecount()
			end
			
			table.insert(checkboxes, checkbox)
		end
		
		for i=1,maxselected do
			if modApi.squadIndices == nil then
				checkboxes[i].checked = true
			else
				checkboxes[modApi.squadIndices[i]].checked = true
			end
		end
		updatecount()
	end)
	
	modApi.squadIndices = {}
	local assignIndex = function(n)
		for i=1,maxselected do
			if modApi.squadIndices[i] == nil then
				modApi.squadIndices[i] = n
				return true
			end
		end
		return false
	end

	for i=1,maxselected do
		if checkboxes[i].checked then
			modApi.squadIndices[i] = i
		end
	end
	
	for i=maxselected+1,#checkboxes do
		if checkboxes[i].checked and not assignIndex(i) then break end
	end
	
	for i=1,maxselected do
		if modApi.squadIndices[i] == nil then
			modApi.squadIndices[i] = i
		end
	end
	
	saveSquadSelection()
end