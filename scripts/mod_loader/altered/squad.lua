
local oldGetStartingSquad = getStartingSquad
function getStartingSquad(choice)
	if choice == 0 then
		loadPilotsOrder()
		loadSquadSelection()
	end

	if choice >= 0 and choice <= 7 then
		local index = modApi.squadIndices[choice + 1]
		
		modApi:overwriteText(
			"TipTitle_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 1]
		)
		modApi:overwriteText(
			"TipText_"..modApi.squadKeys[choice + 1],
			modApi.squad_text[2 * (index - 1) + 2]
		)

		return modApi.mod_squads[index]
	else
		return oldGetStartingSquad(choice)
	end
end
