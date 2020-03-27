--[[
	Adds a new entry to the "Mod Content" menu, allowing to select
	which squads are available for selection in the hangar.
--]]

local maxselected = 8

local function saveSquadSelection()
	local selected = {}
	for i = 1, maxselected do
		local index = modApi.squadIndices[i]
		local name = modApi.squad_text[(index - 1) * 2 + 1]
		selected[i] = name
	end

	local modcontent = modApi:getCurrentModcontentPath()

	sdlext.config(modcontent, function(obj)
		obj.selectedSquads = selected
	end)
end

function loadSquadSelection()
	local map = {}

	for i = 1, #modApi.squad_icon do
		local name = modApi.squad_text[(i - 1) * 2 + 1]
		map[name] = i
	end

	local modcontent = modApi:getCurrentModcontentPath()

	modApi.squadIndices = {}
	sdlext.config(modcontent, function(obj)
		if not obj.selectedSquads then
			return
		end

		for i = 1, maxselected do
			local name = obj.selectedSquads[i]
			local index = map[name]
			if index ~= nil then
				modApi.squadIndices[i] = index
			end
		end
	end)

	for i = 1, maxselected do
		if modApi.squadIndices[i] == nil then
			modApi.squadIndices[i] = i
		end
	end
end

local largefont = sdlext.font("fonts/NunitoSans_Bold.ttf", 44)
local squadPalettes = sdlext.squadPalettes()
local function createUi()
	local checkboxes = {}

	local onExit = function(self)
		modApi.squadIndices = {}
		local assignIndex = function(n)
			for i = 1, maxselected do
				if modApi.squadIndices[i] == nil then
					modApi.squadIndices[i] = n
					return true
				end
			end
			return false
		end

		for i = 1, maxselected do
			if checkboxes[i].checked then
				modApi.squadIndices[i] = i
			end
		end

		for i = maxselected + 1, #checkboxes do
			if checkboxes[i].checked and not assignIndex(i) then
				break
			end
		end

		for i = 1, maxselected do
			if modApi.squadIndices[i] == nil then
				modApi.squadIndices[i] = i
			end
		end

		saveSquadSelection()
	end

	sdlext.showDialog(function(ui, quit)
		ui.onDialogExit = onExit

		local lblTotal = Ui()
				:caption(modApi:getText("SquadSelect_Total"))
				:decorate({ DecoCaption() })
				:addTo(ui)

		local lblCount = Ui()
			:caption("")
			:decorate({ DecoCaption(largefont) })
			:addTo(ui)

		local updatecount = function()
			local count = 0

			for i = 1, #checkboxes do
				local checkbox = checkboxes[i]
				if checkbox.checked then
					count = count + 1
				end
			end

			lblCount:caption(count.."/"..maxselected)
		end

		local columnGap = 25
		local buildContent = function(scroll)
			scroll:padding(20)

			local contentLayout = UiBoxLayout()
				:width(1)
				:vgap(15)
				:addTo(scroll)

			local getLayout = function(index)
				local column = index % 2
				local row = 1 + math.floor(index / 2)
				if column == 0 then
					return UiWeightLayout()
						:width(1):heightpx(60)
						:hgap(columnGap)
						:addTo(contentLayout)
				else
					-- Fetch existing layout
					return contentLayout.children[row]
				end
			end

			local modSquadsCount = #modApi.mod_squads
			for i = 1, modSquadsCount do
				local surface = sdlext.getSurface({ path = modApi.squad_icon[i] or "" })

				if i > 1 and i <= 8 then
					local colorTable = {}
					for j = 1, #squadPalettes[1] do
						colorTable[(j - 1) * 2 + 1] = squadPalettes[1][j]
						colorTable[(j - 1) * 2 + 2] = squadPalettes[i][j]
					end

					surface = sdl.colormapped(surface, colorTable)
				end

				local checkbox = UiCheckbox()
					:width(0.5)
					:heightpx(41)
					:settooltip(modApi.squad_text[i * 2])
					:decorate({
						DecoButton(),
						DecoCheckbox(),
						DecoAlign(2, 0),
						DecoSurfaceOutlined(surface),
						DecoAlign(0, 2),
						DecoText(modApi.squad_text[i * 2 - 1])
					})

				checkbox:addTo(getLayout(i - 1))

				checkbox.onclicked = function(self, button)
					updatecount()
					return true
				end

				table.insert(checkboxes, checkbox)
			end

			if modSquadsCount % 2 == 1 then
				-- need to add a filler element to have the last odd squad button correctly sized
				Ui()
					:width(0.5)
					:heightpx(41)
					:addTo(getLayout(modSquadsCount))
			end

			for i = 1, maxselected do
				if modApi.squadIndices == nil then
					checkboxes[i].checked = true
				else
					checkboxes[modApi.squadIndices[i]].checked = true
				end
			end

			updatecount()
		end

		local buildButtons = function(buttonLayout)
			-- default button: selects all vanilla squads
			local btnDefault = sdlext.buildButton(
				modApi:getText("SquadSelect_Default_Text"),
				modApi:getText("SquadSelect_Default_Tooltip"),
				function()
					-- select first 8 vanilla squads
					for i = 1, maxselected do
						checkboxes[i].checked = true
					end
					-- deselect all remaining squads
					for i = maxselected + 1, #checkboxes do
						checkboxes[i].checked = false
					end

					-- always have 8 required squads selected
					lblCount:caption(maxselected.."/"..maxselected)
				end
			)
			btnDefault:addTo(buttonLayout)

			-- random button: selects random 8 squads
			local btnRandom = sdlext.buildButton(
					modApi:getText("SquadSelect_Random_Text"),
					modApi:getText("SquadSelect_Random_Tooltip"),
					function()
					-- create a list of indexes that we can modify
					local indexes = {}
					for i = 1, #checkboxes do
						indexes[i] = i
					end
					-- choose 8 random indexes from the list
					for i = 1, maxselected do
						local check = math.random(#indexes)
						checkboxes[indexes[check]].checked = true
						-- remove index so we don't hit it twice
						table.remove(indexes, check)
					end
					-- any remaining index should be unchecked
					for i = 1, #indexes do
						checkboxes[indexes[i]].checked = false
					end

					-- always have 8 required squads selected
					lblCount:caption(maxselected.."/"..maxselected)
				end
			)
			btnRandom:addTo(buttonLayout)
		end

		local frame = sdlext.buildButtonDialog(
			modApi:getText("SquadSelect_FrameTitle"),
			0.6 * ScreenSizeX(), 0.6 * ScreenSizeY(),
			buildContent,
			buildButtons
		)

		frame
			:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
			:addTo(ui)

		lblTotal:pospx(frame.x + 15, frame.y + frame.h + 35)
		lblCount:pospx(lblTotal.x + 150, lblTotal.y)
	end)
end

function SelectSquads()
	loadSquadSelection()

	createUi()
end
