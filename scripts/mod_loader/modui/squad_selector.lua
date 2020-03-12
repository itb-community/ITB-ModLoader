--[[
	Adds a new entry to the "Mod Content" menu, allowing to select
	which squads are available for selection in the hangar.
--]]

local maxselected = 8

local function saveSquadSelection()
	local selected = {}
	for i=1,maxselected do
		local index = modApi.squadIndices[i]
		local name = modApi.squad_text[(index-1)*2+1]
		selected[i] = name
	end
	
	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent,function(obj)
		obj.selectedSquads = selected
	end)
end

function loadSquadSelection()
	local map = {}
	
	for i=1,#modApi.squad_icon do
		local name = modApi.squad_text[(i-1)*2+1]
		map[name] = i
	end
	
	local modcontent = modApi:getCurrentModcontentPath()

	modApi.squadIndices = {}
	sdlext.config(modcontent, function(obj)
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
local function createUi()
	local checkboxes = {}

	local onExit = function(self)
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
	
	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local labelcount = Ui()
			:width(0.3):height(0.075)
			:pos(0.71,0.83)
			:caption("")
			:decorate({ DecoCaption(largefont) })
			:addTo(ui)

		Ui()
			:width(0.3):height(0.05)
			:pos(0.7,0.925)
			:caption(modApi:getText("SquadSelect_Total"))
			:decorate({ DecoCaption() })
			:addTo(ui)

		local frametop = Ui()
			:width(0.6):height(0.7)
			:pos(0.2, 0.1)
			:caption(modApi:getText("SquadSelect_FrameTitle"))
			:decorate({ DecoFrameHeader(), DecoFrame() })
			:addTo(ui)

		local scrollarea = UiScrollArea()
			:width(1):height(1)
			:padding(24)
			:addTo(frametop)

		local updatecount = function()
			local count = 0
			
			for i=1,#checkboxes do
				local checkbox = checkboxes[i]
				if checkbox.checked then count=count+1 end
			end
			
			labelcount:caption(count.."/"..maxselected)
		end
		
		-- default button: selects all vanilla squads
		local defaultBtn = Ui()
			:pos(0, 0)
			:setypx(0)
			:heightpx(41)
			:width(0.48)
			:settooltip("Select only vanilla squads.")
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText("Default")
			})
			:addTo(scrollarea)
		function defaultBtn.onclicked()
			-- check first 8 vanilla squads
			for i=1,maxselected do
				checkboxes[i].checked = true
			end
			-- uncheck all remaining squads
			for i=maxselected+1,#checkboxes do
				checkboxes[i].checked = false
			end

			-- always have 8 required squads selected
			labelcount:caption(maxselected.."/"..maxselected)
			return true
		end

		-- random button: selects random 8 squads
		local randomBtn = Ui()
			:pos(0.5, 0)
			:setypx(0)
			:heightpx(41)
			:width(0.48)
			:settooltip("Randomize selected squads.")
			:decorate({
				DecoButton(),
				DecoAlign(0, 2),
				DecoText("Randomize")
			})
			:addTo(scrollarea)
		function randomBtn.onclicked()
		  -- create a list of indexes that we can modify
			local indexes = {}
			for i = 1, #checkboxes do indexes[i] = i end
			-- choose 8 random indexes from the list
			for i=1, maxselected do
				local check = math.random(#indexes)
				checkboxes[indexes[check]].checked = true
				-- remove index so we don't hit it twice
				table.remove(indexes, check)
			end
			-- any remaining index should be unchecked
			for i=1,#indexes do
				checkboxes[indexes[i]].checked = false
			end

			-- always have 8 required squads selected
			labelcount:caption(maxselected.."/"..maxselected)
			return true
		end

		for i=1,#modApi.mod_squads do
			local col = (i-1) % 2
			local row = math.floor((i+1) / 2)
			
			local surface = sdlext.getSurface({ path = modApi.squad_icon[i] or "" })
			
			if i>1 and i<=8 then
				local colorTable = {}
				for j=1,#squadPalettes[1] do
					colorTable[(j-1)*2 + 1] = squadPalettes[1][j]
					colorTable[(j-1)*2 + 2] = squadPalettes[i][j]
				end
				
				surface = sdl.colormapped(surface, colorTable)
			end
			
			local checkbox = UiCheckbox()
				:pos(0.5 * col, 0)
				:setypx(80 * row)
				:heightpx(41)
				:width(0.48)
				:settooltip(modApi.squad_text[i*2])
				:decorate({
					DecoButton(),
					DecoCheckbox(),
					DecoSurfaceOutlined(surface),
					DecoAlign(0, 2),
					DecoText(modApi.squad_text[i*2-1])
				})
			
			scrollarea:add(checkbox)
			
			checkbox.onclicked = function(self, button)
				updatecount()
				return true
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
end

function SelectSquads()
	loadSquadSelection()
	
	createUi()
end
